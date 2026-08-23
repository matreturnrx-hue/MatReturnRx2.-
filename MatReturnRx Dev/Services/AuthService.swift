//
//  AuthService.swift
//  MatReturnRx
//

import SwiftUI
import Amplify
import AWSCognitoAuthPlugin
import AuthenticationServices
import CryptoKit

// ============================================================
// MARK: - Auth Error
// ============================================================

// App-level auth error enum. Amplify also defines AuthError —
// reference the Amplify type as Amplify.AuthError within this file.
enum AuthError: LocalizedError {
    case invalidCredentials
    case emailConfirmationRequired
    case userAlreadyExists
    case networkError
    case sessionExpired
    case appleSignInFailed
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:        return "Incorrect email or password. Please try again."
        case .emailConfirmationRequired: return "Account created! Check your email to verify before logging in."
        case .userAlreadyExists:         return "An account with this email already exists. Try logging in."
        case .networkError:              return "No internet connection. Please check your network and try again."
        case .sessionExpired:            return "Your session has expired. Please log in again."
        case .appleSignInFailed:         return "Apple Sign In failed. Please try again."
        case .serverError(let msg):      return msg
        }
    }
}

// ============================================================
// MARK: - Token Manager
// ============================================================

// Amplify / Cognito stores JWT tokens securely in Keychain automatically.
// TokenManager is a lightweight wrapper that caches only the user ID
// in UserDefaults for fast synchronous reads at app startup.

final class TokenManager {
    static let shared = TokenManager()
    private init() {}

    private let userIdKey = "mrx_cognito_user_id"
    private let roleKey   = "mrx_user_role"

    var userId: String? {
        get { UserDefaults.standard.string(forKey: userIdKey) }
        set { UserDefaults.standard.set(newValue, forKey: userIdKey) }
    }

    var userRole: String {
        get { UserDefaults.standard.string(forKey: roleKey) ?? "athlete" }
        set { UserDefaults.standard.set(newValue, forKey: roleKey) }
    }

    var isAuthenticated: Bool { userId != nil }

    func clear() {
        UserDefaults.standard.removeObject(forKey: userIdKey)
    }

    func clearSession() { clear() }
}

// ============================================================
// MARK: - Auth Manager  (Amplify / Cognito)
// ============================================================

final class AuthManager {
    static let shared = AuthManager()
    private init() {}

    // MARK: Restore session on app launch
    // Called from RootView.task — verifies an active Cognito session
    // and hydrates AppState without forcing the user to log in again.
    func restoreSession(appState: AppState) async {
        guard let session = try? await Amplify.Auth.fetchAuthSession(),
              session.isSignedIn else {
            TokenManager.shared.clear()
            await MainActor.run {
                appState.isAuthenticated = false
                UserDefaults.standard.set(false, forKey: "mrx_auth")
            }
            return
        }

        let userId: String
        if let cached = TokenManager.shared.userId, !cached.isEmpty {
            userId = cached
        } else if let user = try? await Amplify.Auth.getCurrentUser() {
            userId = user.userId
            TokenManager.shared.userId = userId
        } else {
            return
        }

        await MainActor.run {
            appState.isAuthenticated = true
            appState.userId = userId
        }

        if let attrs = try? await Amplify.Auth.fetchUserAttributes(),
           let name = attrs.first(where: { $0.key == .name })?.value, !name.isEmpty {
            await MainActor.run { appState.register(name: name) }
        }

        try? await loadAndHydrateProfile(userId: userId, appState: appState)
    }

    // MARK: Sign Up
    @discardableResult
    func signUp(email: String, password: String, fullName: String, appState: AppState) async throws -> Bool {
        let options = AuthSignUpRequest.Options(userAttributes: [
            AuthUserAttribute(.email, value: email),
            AuthUserAttribute(.name,  value: fullName)
        ])
        do {
            let result = try await Amplify.Auth.signUp(username: email, password: password, options: options)
            if case .confirmUser = result.nextStep {
                throw AuthError.emailConfirmationRequired
            }
        } catch let amplifyError as AuthError { // Use local AuthError type, not Amplify.AuthError
            throw mapAmplifyError(amplifyError)
        }

        // Auto sign-in if email confirmation is not required
        try await signIn(email: email, password: password, appState: appState)
        return true
    }

    // MARK: Sign In
    func signIn(email: String, password: String, appState: AppState) async throws {
        do {
            let result = try await Amplify.Auth.signIn(username: email, password: password)
            if !result.isSignedIn {
                if case .confirmSignUp = result.nextStep { throw AuthError.emailConfirmationRequired }
                throw AuthError.invalidCredentials
            }
        } catch let amplifyError as AuthError { // Use local AuthError type, not Amplify.AuthError
            throw mapAmplifyError(amplifyError)
        }

        let user   = try await Amplify.Auth.getCurrentUser()
        let userId = user.userId
        TokenManager.shared.userId = userId

        await MainActor.run {
            appState.userId          = userId
            appState.isAuthenticated = true
            UserDefaults.standard.set(true, forKey: "mrx_auth")
        }

        try? await loadAndHydrateProfile(userId: userId, appState: appState)
    }

    // MARK: Sign In with Apple (native flow → Cognito token exchange)
    //
    // AuthViews passes the Apple id_token from ASAuthorizationController.
    // We exchange it with the Cognito hosted domain /oauth2/token endpoint.
    // Prerequisite: Apple must be added as a Social Identity Provider in your
    // Cognito User Pool (AWS Console → Cognito → User Pool → Sign-in experience → Social).

    func signInWithApple(idToken: String, nonce: String, fullName: String?, appState: AppState) async throws {
        guard let url = URL(string: "\(AmplifyConfig.cognitoDomain)/oauth2/token") else {
            throw AuthError.appleSignInFailed
        }

        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "grant_type",    value: "urn:ietf:params:oauth:grant-type:jwt-bearer"),
            URLQueryItem(name: "client_id",     value: AmplifyConfig.appClientId),
            URLQueryItem(name: "id_token",      value: idToken),
            URLQueryItem(name: "provider_name", value: "SignInWithApple"),
            URLQueryItem(name: "nonce",         value: nonce)
        ]

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.httpBody   = components.percentEncodedQuery?.data(using: .utf8)
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode) else {
            throw AuthError.appleSignInFailed
        }

        struct CognitoTokens: Decodable {
            let access_token: String
            let id_token: String?
        }
        guard let tokens = try? JSONDecoder().decode(CognitoTokens.self, from: data) else {
            throw AuthError.appleSignInFailed
        }

        let userId = jwtSubject(from: tokens.id_token ?? tokens.access_token) ?? UUID().uuidString
        let name   = fullName ?? "Athlete"
        TokenManager.shared.userId = userId

        await MainActor.run {
            appState.userId = userId
            appState.register(name: name)
            UserDefaults.standard.set(true, forKey: "mrx_auth")
        }

        if let existing = try? await AmplifyAPIManager.shared.fetchProfile(userId: userId) {
            await MainActor.run { appState.hydrateFromProfile(existing) }
        } else {
            let profile = AthleteProfile(
                userId: userId, fullName: name, sport: appState.sport,
                experienceLevel: appState.experienceLevel, trainingPhase: appState.trainingPhase,
                heightCm: nil, weightKg: nil, competitionWeightKg: nil,
                goals: nil, selectedBodyAreas: nil, availableEquipment: nil,
                isMinor: appState.isMinor, isPro: false,
                subscriptionTier: "free", subscriptionStatus: "active"
            )
            try? await AmplifyAPIManager.shared.upsertProfile(profile)
        }
    }

    // MARK: Reset Password
    func resetPassword(email: String) async throws {
        do {
            _ = try await Amplify.Auth.resetPassword(for: email)
        } catch let amplifyError as AuthError { // Use local AuthError type, not Amplify.AuthError
            throw AuthError.serverError(amplifyError.localizedDescription)
        }
    }

    // MARK: Sign Out
    func signOut(appState: AppState) async {
        _ = await Amplify.Auth.signOut()
        TokenManager.shared.clear()
        await MainActor.run { appState.signOut() }
    }

    // MARK: Private helpers

    private func loadAndHydrateProfile(userId: String, appState: AppState) async throws {
        guard let profile = try? await AmplifyAPIManager.shared.fetchProfile(userId: userId) else { return }
        await MainActor.run { appState.hydrateFromProfile(profile) }
    }

    private func mapAmplifyError(_ error: AuthError) -> AuthError {
        let desc = error.localizedDescription.lowercased()
        if desc.contains("not authorized") || desc.contains("incorrect") || desc.contains("user not found") {
            return .invalidCredentials
        }
        if desc.contains("username exists") || desc.contains("alias exists") {
            return .userAlreadyExists
        }
        if desc.contains("network") || desc.contains("connection") {
            return .networkError
        }
        return .serverError(error.localizedDescription)
    }

    // Decode the `sub` claim from a JWT (base64url payload segment).
    private func jwtSubject(from token: String) -> String? {
        let parts = token.split(separator: ".").map(String.init)
        guard parts.count >= 2 else { return nil }
        var payload = parts[1]
        let rem = payload.count % 4
        if rem > 0 { payload += String(repeating: "=", count: 4 - rem) }
        payload = payload
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        guard let data = Data(base64Encoded: payload),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let sub  = json["sub"] as? String else { return nil }
        return sub
    }
}

// ============================================================
// MARK: - Apple Sign In Nonce Helpers
// ============================================================

func randomNonceString(length: Int = 32) -> String {
    var bytes = [UInt8](repeating: 0, count: length)
    _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
    let chars: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
    return String(bytes.map { chars[Int($0) % chars.count] })
}

func sha256Nonce(_ input: String) -> String {
    let data = Data(input.utf8)
    let hash = SHA256.hash(data: data)
    return hash.map { String(format: "%02x", $0) }.joined()
}
