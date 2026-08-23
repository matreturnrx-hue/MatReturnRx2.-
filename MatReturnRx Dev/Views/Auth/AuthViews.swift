//
//  AuthViews.swift
//  MatReturnRx
//

import SwiftUI
import AuthenticationServices

// Helper functions moved outside struct to avoid private keyword issues
func pillar(icon: String, label: String, color: Color) -> some View {
    VStack(spacing: 6) {
        Image(systemName: icon)
            .font(.system(size: 16))
            .foregroundColor(color)
        Text(label)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.white.opacity(0.85))
    }
    .frame(maxWidth: .infinity)
}

// ============================================================
// MARK: - Welcome & Auth Screens
// ============================================================

struct WelcomeScreen: View {
    @EnvironmentObject var app: AppState
    var body: some View {
        ZStack {
            // Background gradient — deep navy to graphite
            LinearGradient(
                colors: [AppTheme.deepNavy, Color(red: 0.05, green: 0.05, blue: 0.05)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo + tagline
                VStack(alignment: .leading, spacing: 20) {
                    BrandLogoView(compact: false)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recover. Prepare. Perform.")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white.opacity(0.85))
                        Text("Evidence-informed training and recovery for combat athletes — backed by physical therapy science.")
                            .font(.system(size: 14))
                            .foregroundColor(.mrxTextSec)
                            .lineSpacing(3)
                    }

                    // Marketing pillars
                    HStack(spacing: 0) {
                        pillar(icon: "cross.case.fill",      label: "PT-Based",     color: AppTheme.recoveryTeal)
                        Divider().frame(width: 1).background(Color.white.opacity(0.1)).padding(.vertical, 4)
                        pillar(icon: "bolt.fill",            label: "Performance",  color: AppTheme.electricOrange)
                        Divider().frame(width: 1).background(Color.white.opacity(0.1)).padding(.vertical, 4)
                        pillar(icon: "shield.fill",          label: "Safe Return",  color: AppTheme.fightRed)
                    }
                    .padding(14)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(14)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 28)
                .padding(.bottom, 48)

                // CTAs
                VStack(spacing: 12) {
                    NavigationLink(destination: CreateAccountScreen()) {
                        Text("Get Started — It's Free")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(AppTheme.fightRed)
                            .cornerRadius(14)
                    }
                    NavigationLink(destination: LoginScreen()) {
                        Text("Log In")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.clear)
                            .cornerRadius(14)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.25), lineWidth: 1.5))
                    }

                    #if DEBUG
                    Button("⚙️ Dev: Skip Login") {
                        app.userId       = "dev-user"
                        app.userName     = "Dev Athlete"
                        app.athleteFirst = "Dev"
                        app.isAuthenticated     = true
                        app.hasCompletedOnboard = true
                        UserDefaults.standard.set(true, forKey: "mrx_auth")
                        UserDefaults.standard.set(true, forKey: "mrx_onboard")
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.mrxTextMuted)
                    #endif
                }
                .padding(.horizontal, 24)

                Text("By continuing, you agree to our Terms of Service and Privacy Policy.")
                    .font(.system(size: 11))
                    .foregroundColor(.mrxTextMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.top, 16)
                    .padding(.bottom, 36)
            }
        }
#if os(iOS)
        .navigationBarHidden(true)
#elseif os(macOS)
        .navigationTitle("")
        .toolbar(.hidden, for: .windowToolbar)
#endif
    }

    func pillar(icon: String, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.mrxTextSec)
        }
        .frame(maxWidth: .infinity)
    }
}

struct CreateAccountScreen: View {
    @EnvironmentObject var app: AppState
    @State private var name     = ""
    @State private var email    = ""
    @State private var password = ""
    @State private var confirm  = ""
    @State private var agreed   = false
    @State private var loading  = false
    @State private var errMsg   = ""
    @State private var showErr  = false
    @State private var showConfirmation = false   // email-confirmation-required notice
    @State private var currentNonce: String? = nil
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Create Account")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    Text("Join MatReturnRx and start training smarter.")
                        .foregroundColor(.mrxTextSec)
                }

                VStack(spacing: 12) {
                    MRXField(label: "Full name",            text: $name,     type: .name)
                    MRXField(label: "Email address",        text: $email,    type: .email)
                    MRXField(label: "Password (8+ chars)",  text: $password, type: .password)
                    MRXField(label: "Confirm password",     text: $confirm,  type: .password)
                }

                Toggle(isOn: $agreed) {
                    Text("I agree to the **Terms of Service** and **Privacy Policy**")
                        .font(.system(size: 14))
                        .foregroundColor(.mrxTextSec)
                }
                .toggleStyle(CheckToggleStyle())

                // Primary CTA — real Amplify signup
                MRXButton(
                    title: loading ? "Creating account..." : "Create Account",
                    color: AppTheme.fightRed
                ) {
                    guard !loading else { return }
                    validate()
                }
                .disabled(loading)

                // Divider
                HStack {
                    Rectangle().fill(Color.mrxBorder).frame(height: 1)
                    Text("or").font(.system(size: 12)).foregroundColor(.mrxTextMuted).padding(.horizontal, 8)
                    Rectangle().fill(Color.mrxBorder).frame(height: 1)
                }

                // Sign in with Apple — required for App Store compliance
                SignInWithAppleButton(.signUp) { request in
                    let nonce = randomNonceString()
                    currentNonce = nonce
                    request.requestedScopes = [.fullName, .email]
                    request.nonce = sha256Nonce(nonce)
                } onCompletion: { result in
                    handleAppleResult(result)
                }
                .signInWithAppleButtonStyle(.white)
                .frame(height: 50)
                .cornerRadius(14)
                .disabled(loading)

                Button("Already have an account? Log In") { dismiss() }
                    .font(.system(size: 14))
                    .foregroundColor(.mrxTextSec)
                    .frame(maxWidth: .infinity)
            }
            .padding(24)
        }
        .background(Color.mrxBg.ignoresSafeArea())
        .navigationTitle("")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        // Generic error alert
        .alert("Error", isPresented: $showErr, actions: { Button("OK", role: .cancel) {} }) {
            Text(errMsg)
        }
        // Email confirmation notice
        .alert("Check Your Email", isPresented: $showConfirmation, actions: {
            Button("OK", role: .cancel) { dismiss() }
        }) {
            Text("We sent a confirmation link to \(email). Verify your email, then log in.")
        }
    }

    // MARK: Email sign-up
    func validate() {
        guard !name.isEmpty          else { showError("Please enter your full name.");             return }
        guard email.contains("@")    else { showError("Please enter a valid email address.");      return }
        guard password.count >= 8    else { showError("Password must be at least 8 characters."); return }
        guard password == confirm    else { showError("Passwords do not match.");                  return }
        guard agreed                 else { showError("Please agree to the Terms of Service.");    return }

        loading = true
        Task {
            do {
                try await AuthManager.shared.signUp(
                    email:    email,
                    password: password,
                    fullName: name,
                    appState: app
                )
                // signUp returns without throwing → immediate session (email confirm disabled)
                await MainActor.run { loading = false }
            } catch AuthError.emailConfirmationRequired {
                await MainActor.run { loading = false; showConfirmation = true }
            } catch {
                await MainActor.run { loading = false; showError(error.localizedDescription) }
            }
        }
    }

    // MARK: Apple Sign In
    func handleAppleResult(_ result: Result<ASAuthorization, Error>) {
        Task { @MainActor in
            switch result {
            case .success(let auth):
                guard let credential = auth.credential as? ASAuthorizationAppleIDCredential,
                      let tokenData  = credential.identityToken,
                      let idToken    = String(data: tokenData, encoding: .utf8),
                      let nonce      = currentNonce else {
                    showError("Apple Sign In failed. Please try again.")
                    return
                }
                let givenName  = credential.fullName?.givenName
                let familyName = credential.fullName?.familyName
                let fullName   = [givenName, familyName].compactMap { $0 }.joined(separator: " ")
                loading = true
                do {
                    try await AuthManager.shared.signInWithApple(
                        idToken:  idToken,
                        nonce:    nonce,
                        fullName: fullName.isEmpty ? nil : fullName,
                        appState: app
                    )
                } catch {
                    showError(error.localizedDescription)
                }
                loading = false
            case .failure(let error):
                let nsError = error as NSError
                if nsError.code != ASAuthorizationError.canceled.rawValue {
                    showError(error.localizedDescription)
                }
            }
        }
    }

    func showError(_ msg: String) { errMsg = msg; showErr = true }
}

struct LoginScreen: View {
    @EnvironmentObject var app: AppState
    @State private var email    = ""
    @State private var password = ""
    @State private var loading  = false
    @State private var errMsg   = ""
    @State private var showErr  = false
    @State private var showForgot       = false
    @State private var currentNonce: String? = nil
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Log In")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    Text("Welcome back to MatReturnRx.")
                        .foregroundColor(.mrxTextSec)
                }

                VStack(spacing: 12) {
                    MRXField(label: "Email address", text: $email,    type: .email)
                    MRXField(label: "Password",      text: $password, type: .password)
                }

                // Primary CTA — real Amplify login
                MRXButton(
                    title: loading ? "Logging in..." : "Log In",
                    color: AppTheme.fightRed
                ) {
                    guard !loading else { return }
                    signIn()
                }
                .disabled(loading)

                // Forgot Password — functional
                Button("Forgot Password?") { showForgot = true }
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.recoveryTeal)
                    .frame(maxWidth: .infinity)

                // Divider
                HStack {
                    Rectangle().fill(Color.mrxBorder).frame(height: 1)
                    Text("or").font(.system(size: 12)).foregroundColor(.mrxTextMuted).padding(.horizontal, 8)
                    Rectangle().fill(Color.mrxBorder).frame(height: 1)
                }

                // Sign in with Apple — required for App Store compliance
                SignInWithAppleButton(.signIn) { request in
                    let nonce = randomNonceString()
                    currentNonce = nonce
                    request.requestedScopes = [.fullName, .email]
                    request.nonce = sha256Nonce(nonce)
                } onCompletion: { result in
                    handleAppleResult(result)
                }
                .signInWithAppleButtonStyle(.white)
                .frame(height: 50)
                .cornerRadius(14)
                .disabled(loading)

                Button("Don't have an account? Create Account") { dismiss() }
                    .font(.system(size: 14))
                    .foregroundColor(.mrxTextSec)
                    .frame(maxWidth: .infinity)
            }
            .padding(24)
        }
        .background(Color.mrxBg.ignoresSafeArea())
        .navigationTitle("")
        .alert("Error", isPresented: $showErr, actions: { Button("OK", role: .cancel) {} }) {
            Text(errMsg)
        }
        .sheet(isPresented: $showForgot) {
            ForgotPasswordScreen()
        }
    }

    // MARK: Email login
    func signIn() {
        guard !email.isEmpty     else { showError("Please enter your email address."); return }
        guard !password.isEmpty  else { showError("Please enter your password.");      return }
        loading = true
        Task {
            do {
                try await AuthManager.shared.signIn(email: email, password: password, appState: app)
                await MainActor.run { loading = false }
            } catch {
                await MainActor.run { loading = false; showError(error.localizedDescription) }
            }
        }
    }

    // MARK: Apple Sign In
    func handleAppleResult(_ result: Result<ASAuthorization, Error>) {
        Task { @MainActor in
            switch result {
            case .success(let auth):
                guard let credential = auth.credential as? ASAuthorizationAppleIDCredential,
                      let tokenData  = credential.identityToken,
                      let idToken    = String(data: tokenData, encoding: .utf8),
                      let nonce      = currentNonce else {
                    showError("Apple Sign In failed. Please try again.")
                    return
                }
                let givenName  = credential.fullName?.givenName
                let familyName = credential.fullName?.familyName
                let fullName   = [givenName, familyName].compactMap { $0 }.joined(separator: " ")
                loading = true
                do {
                    try await AuthManager.shared.signInWithApple(
                        idToken:  idToken,
                        nonce:    nonce,
                        fullName: fullName.isEmpty ? nil : fullName,
                        appState: app
                    )
                } catch {
                    showError(error.localizedDescription)
                }
                loading = false
            case .failure(let error):
                let nsError = error as NSError
                if nsError.code != ASAuthorizationError.canceled.rawValue {
                    showError(error.localizedDescription)
                }
            }
        }
    }

    func showError(_ msg: String) { errMsg = msg; showErr = true }
}

// ============================================================
// MARK: - Forgot Password Screen
// ============================================================

struct ForgotPasswordScreen: View {
    @State private var email        = ""
    @State private var loading      = false
    @State private var showSuccess  = false
    @State private var errMsg       = ""
    @State private var showErr      = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.mrxBg.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Reset Password")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            Text("Enter the email address linked to your account. We'll send you a password reset link.")
                                .font(.system(size: 14))
                                .foregroundColor(.mrxTextSec)
                                .lineSpacing(3)
                        }

                        MRXField(label: "Email address", text: $email, type: .email)

                        MRXButton(
                            title: loading ? "Sending..." : "Send Reset Link",
                            color: AppTheme.fightRed
                        ) {
                            guard !loading else { return }
                            sendReset()
                        }
                        .disabled(loading)

                        Button("Back to Log In") { dismiss() }
                            .font(.system(size: 14))
                            .foregroundColor(.mrxTextSec)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(24)
                }
            }
            .navigationTitle("")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }.foregroundColor(.mrxTextMuted)
                }
            }
#elseif os(macOS)
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Close") { dismiss() }.foregroundColor(.mrxTextMuted)
                }
            }
#endif
            .alert("Error", isPresented: $showErr, actions: { Button("OK", role: .cancel) {} }) {
                Text(errMsg)
            }
            .alert("Check Your Email", isPresented: $showSuccess, actions: {
                Button("Done") { dismiss() }
            }) {
                Text("A password reset link has been sent to \(email). Check your inbox and follow the instructions.")
            }
        }
    }

    func sendReset() {
        guard email.contains("@") else {
            errMsg = "Please enter a valid email address."
            showErr = true
            return
        }
        loading = true
        Task {
            do {
                try await AuthManager.shared.resetPassword(email: email)
                await MainActor.run { loading = false; showSuccess = true }
            } catch {
                await MainActor.run { loading = false; errMsg = error.localizedDescription; showErr = true }
            }
        }
    }
}
