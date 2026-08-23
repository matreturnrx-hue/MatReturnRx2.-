//
//  AmplifyService.swift
//  MatReturnRx
//

import SwiftUI
import Amplify
import AWSCognitoAuthPlugin
import AWSAPIPlugin
import Combine

// ============================================================
// MARK: - Amplify Bootstrap
// ============================================================

// Call configureAmplify() once at app startup in MatReturnRxApp.init(),
// before the SwiftUI body runs. Reads amplifyconfiguration.json that is
// bundled with the app target (generate it by running: amplify push).

func configureAmplify() {
    do {
        try Amplify.add(plugin: AWSCognitoAuthPlugin())
        try Amplify.add(plugin: AWSAPIPlugin())
        try Amplify.configure()
    } catch {
        print("[Amplify] Configuration failed: \(error)")
    }
}

// ============================================================
// MARK: - Amplify Config Constants
// ============================================================

enum AmplifyConfig {
    // API name must match the key in amplifyconfiguration.json →
    // api → plugins → awsAPIPlugin → {name}
    static let apiName           = "matreturnrxAPI"
    static let processActionPath = "/process-action"
    static let profilesPath      = "/profiles"
    static let progressPath      = "/progress"

    // Cognito hosted domain — used for native Apple Sign In token exchange.
    // Found after amplify push: AWS Console → Cognito → User Pool → App Integration → Domain
    // Format: https://{your-domain}.auth.{region}.amazoncognito.com
    static let cognitoDomain = "https://matreturnrx.auth.us-east-1.amazoncognito.com"

    // App Client ID from amplifyconfiguration.json →
    // auth → plugins → awsCognitoAuthPlugin → CognitoUserPool → Default → AppClientId
    static let appClientId = "REPLACE_WITH_APP_CLIENT_ID"

    // True once placeholder values have been replaced with real AWS resources.
    static var isConfigured: Bool { appClientId != "REPLACE_WITH_APP_CLIENT_ID" }
}

// ============================================================
// MARK: - Amplify API Manager
// ============================================================

final class AmplifyAPIManager {
    static let shared = AmplifyAPIManager()
    private init() {}

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.keyEncodingStrategy = .useDefaultKeys
        e.outputFormatting    = .sortedKeys
        return e
    }()

    // ── Process-Action → Lambda via API Gateway ───────────────

    func callProcessAction(_ request: CloudRequest) async throws -> CloudResponse {
        guard let body = try? encoder.encode(request) else {
            throw CloudProcessingError.networkError("Encode failed")
        }
        let restRequest = RESTRequest(
            apiName: AmplifyConfig.apiName,
            path:    AmplifyConfig.processActionPath,
            body:    body
        )
        do {
            let data = try await Amplify.API.post(request: restRequest)
            return try decoder.decode(CloudResponse.self, from: data)
        } catch let apiError as APIError {
            switch apiError {
            case .httpStatusError(let code, _):
                if code == 429 { throw CloudProcessingError.rateLimited }
                if code == 401 { throw CloudProcessingError.notAuthenticated }
                throw CloudProcessingError.serverError("Server error \(code). Please try again.")
            default:
                throw CloudProcessingError.networkError(apiError.localizedDescription)
            }
        } catch {
            throw CloudProcessingError.decodingError("Could not parse server response.")
        }
    }

    // ── Fetch User Profile ────────────────────────────────────

    func fetchProfile(userId: String) async throws -> AthleteProfile? {
        let restRequest = RESTRequest(
            apiName: AmplifyConfig.apiName,
            path:    "\(AmplifyConfig.profilesPath)/\(userId)"
        )
        guard let data = try? await Amplify.API.get(request: restRequest) else { return nil }
        return try? decoder.decode(AthleteProfile.self, from: data)
    }

    // ── Upsert Profile ────────────────────────────────────────

    func upsertProfile(_ profile: AthleteProfile) async throws {
        guard let body = try? encoder.encode(profile) else { return }
        let restRequest = RESTRequest(
            apiName: AmplifyConfig.apiName,
            path:    AmplifyConfig.profilesPath,
            body:    body
        )
        _ = try? await Amplify.API.post(request: restRequest)
    }

    // ── Fetch Progress Entries ────────────────────────────────

    func fetchProgress(userId: String) async throws -> [MRXCloudProgressEntry]? {
        let restRequest = RESTRequest(
            apiName:         AmplifyConfig.apiName,
            path:            "\(AmplifyConfig.progressPath)/\(userId)",
            queryParameters: ["order": "created_at.asc"]
        )
        guard let data = try? await Amplify.API.get(request: restRequest) else { return nil }
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        return try? dec.decode([MRXCloudProgressEntry].self, from: data)
    }

    // ── Sync Progress Entry ───────────────────────────────────

    func syncProgress(_ entry: MRXCloudProgressEntry) async throws {
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        guard let body = try? enc.encode(entry) else { return }
        let restRequest = RESTRequest(
            apiName: AmplifyConfig.apiName,
            path:    AmplifyConfig.progressPath,
            body:    body
        )
        _ = try? await Amplify.API.post(request: restRequest)
    }
}

// ============================================================
// MARK: - Cloud Action Type
// ============================================================

enum CloudActionType: String, CaseIterable {
    case dailyTrainingPlan   = "daily_training_plan"
    case recoveryScore       = "recovery_score"
    case hydrationPlan       = "hydration_plan"
    case weightCutCountdown  = "weight_cut_countdown"
    case skinCheck           = "skin_check"
    case mentalToughness     = "mental_toughness"
    case neckRehab           = "neck_rehab"
    case shoulderRehab       = "shoulder_rehab"
    case kneeRehab           = "knee_rehab"
    case mobilityPlan        = "mobility_plan"
    case returnToSport       = "return_to_sport"

    var displayName: String {
        switch self {
        case .dailyTrainingPlan:  return "Daily Training Plan"
        case .recoveryScore:      return "Recovery Score"
        case .hydrationPlan:      return "Hydration Plan"
        case .weightCutCountdown: return "Weight-Cut Countdown"
        case .skinCheck:          return "Skin Check"
        case .mentalToughness:    return "Mental Toughness"
        case .neckRehab:          return "Neck Injury Prevention"
        case .shoulderRehab:      return "Shoulder Injury Prevention"
        case .kneeRehab:          return "Knee Injury Prevention"
        case .mobilityPlan:       return "Mobility Plan"
        case .returnToSport:      return "Return to Sport"
        }
    }

    var icon: String {
        switch self {
        case .dailyTrainingPlan:  return "figure.run"
        case .recoveryScore:      return "heart.fill"
        case .hydrationPlan:      return "drop.fill"
        case .weightCutCountdown: return "timer"
        case .skinCheck:          return "eye.fill"
        case .mentalToughness:    return "brain"
        case .neckRehab:          return "person.fill"
        case .shoulderRehab:      return "figure.arms.open"
        case .kneeRehab:          return "figure.walk"
        case .mobilityPlan:       return "arrow.triangle.2.circlepath"
        case .returnToSport:      return "trophy.fill"
        }
    }

    var color: Color {
        switch self {
        case .dailyTrainingPlan:  return .mrxBlue
        case .recoveryScore:      return .mrxGreen
        case .hydrationPlan:      return .mrxTeal
        case .weightCutCountdown: return .mrxOrange
        case .skinCheck:          return .mrxYellow
        case .mentalToughness:    return .mrxPurple
        case .neckRehab:          return .mrxPurple
        case .shoulderRehab:      return .mrxTeal
        case .kneeRehab:          return .mrxOrange
        case .mobilityPlan:       return .mrxGreen
        case .returnToSport:      return .mrxBlue
        }
    }

    static let dailyActions:     [CloudActionType] = [.dailyTrainingPlan, .recoveryScore]
    static let nutritionActions: [CloudActionType] = [.hydrationPlan, .weightCutCountdown]
    static let wellnessActions:  [CloudActionType] = [.skinCheck, .mentalToughness]
    static let rehabActions:     [CloudActionType] = [.neckRehab, .shoulderRehab, .kneeRehab,
                                                       .mobilityPlan, .returnToSport]
}

// ============================================================
// MARK: - Cloud Models
// ============================================================

struct CloudRequest: Codable {
    let userId:             String
    let actionType:         String
    let sport:              String
    let experienceLevel:    String
    let injuryLocation:     String?
    let painLevel:          Int
    let symptoms:           String?
    let goals:              [String]
    let availableEquipment: [String]
    let currentPhase:       String
    let timestamp:          String

    enum CodingKeys: String, CodingKey {
        case userId             = "user_id"
        case actionType         = "action_type"
        case sport
        case experienceLevel    = "experience_level"
        case injuryLocation     = "injury_location"
        case painLevel          = "pain_level"
        case symptoms
        case goals
        case availableEquipment = "available_equipment"
        case currentPhase       = "current_phase"
        case timestamp
    }
}

struct CloudResponse: Codable {
    let title:           String
    let summary:         String
    let recommendations: [String]
    let progressions:    [String]?
    let regressions:     [String]?
    let safetyFlags:     [String]?
    let nextStep:        String
}

struct CloudErrorResponse: Codable {
    let error: String
}

struct AthleteProfile: Codable {
    var userId:              String
    var fullName:            String?
    var sport:               String?
    var experienceLevel:     String?
    var trainingPhase:       String?
    var heightCm:            Double?
    var weightKg:            Double?
    var competitionWeightKg: Double?
    var goals:               [String]?
    var selectedBodyAreas:   [String]?
    var availableEquipment:  [String]?
    var isMinor:             Bool?
    var isPro:               Bool?
    var subscriptionTier:    String?
    var subscriptionStatus:  String?

    enum CodingKeys: String, CodingKey {
        case userId              = "user_id"
        case fullName            = "full_name"
        case sport
        case experienceLevel     = "experience_level"
        case trainingPhase       = "training_phase"
        case heightCm            = "height_cm"
        case weightKg            = "weight_kg"
        case competitionWeightKg = "competition_weight_kg"
        case goals
        case selectedBodyAreas   = "selected_body_areas"
        case availableEquipment  = "available_equipment"
        case isMinor             = "is_minor"
        case isPro               = "is_pro"
        case subscriptionTier    = "subscription_tier"
        case subscriptionStatus  = "subscription_status"
    }
}

enum CloudProcessingError: LocalizedError {
    case notAuthenticated
    case rateLimited
    case serverError(String)
    case networkError(String)
    case decodingError(String)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:     return "Please sign in to use AI Plans."
        case .rateLimited:          return "Too many requests. Please wait a moment and try again."
        case .serverError(let m):   return m.isEmpty ? "Server error. Check AWS Lambda logs." : m
        case .networkError(let m):  return m.isEmpty ? "Network error. Check your internet connection." : m
        case .decodingError(let m): return m.isEmpty ? "Unexpected response format from server." : m
        }
    }
}

// ============================================================
// MARK: - Cloud Processing Service
// ============================================================

@MainActor
class CloudProcessingService: ObservableObject {

    func processAction(
        _ action:       CloudActionType,
        painLevel:      Int,
        symptoms:       String,
        injuryLocation: String,
        appState:       AppState
    ) async throws -> CloudResponse {

        let uid = TokenManager.shared.userId
            ?? (appState.userId.isEmpty ? "anonymous" : appState.userId)

        let request = CloudRequest(
            userId:             uid,
            actionType:         action.rawValue,
            sport:              appState.sport,
            experienceLevel:    appState.experienceLevel,
            injuryLocation:     injuryLocation.isEmpty ? nil : injuryLocation,
            painLevel:          painLevel,
            symptoms:           symptoms.isEmpty ? nil : symptoms,
            goals:              [],
            availableEquipment: ["bodyweight"],
            currentPhase:       appState.trainingPhase,
            timestamp:          ISO8601DateFormatter().string(from: Date())
        )

        return try await AmplifyAPIManager.shared.callProcessAction(request)
    }
}

