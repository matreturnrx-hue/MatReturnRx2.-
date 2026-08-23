//
//  AppState.swift
//  MatReturnRx
//

import SwiftUI
import Combine
import StoreKit

// ============================================================
// MARK: - Subscription Manager  (StoreKit 2)
// ============================================================
// App Store Connect product IDs:
//   pro_6_month_1499  → 6-Month Pro · $14.99/month
//   pro_12_month_1099 → 12-Month Pro · $10.99/month

@MainActor
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

    static let productID6Month  = "pro_6_month_1499"
    static let productID12Month = "pro_12_month_1099"

    @Published var isPurchasing   = false
    @Published var restoreMessage: String? = nil
    @Published var products: [Product] = []
    @Published var purchaseError: String? = nil

    private var transactionListenerTask: Task<Void, Error>?

    private init() {
        transactionListenerTask = listenForTransactionUpdates()
        Task { await loadProducts() }
    }

    deinit { transactionListenerTask?.cancel() }

    // MARK: - Load Products

    func loadProducts() async {
        do {
            let loaded = try await Product.products(for: [
                Self.productID6Month, Self.productID12Month
            ])
            products = loaded.sorted { $0.price < $1.price }
        } catch {
            // Will retry when a purchase is attempted
        }
    }

    // MARK: - Purchase

    func purchase6Month(appState: AppState) {
        Task { await _purchase(productID: Self.productID6Month, appState: appState) }
    }

    func purchase12Month(appState: AppState) {
        Task { await _purchase(productID: Self.productID12Month, appState: appState) }
    }

    private func _purchase(productID: String, appState: AppState) async {
        guard !isPurchasing else { return }

        // Load products first if they haven't loaded yet
        if products.isEmpty { await loadProducts() }

        guard let product = products.first(where: { $0.id == productID }) else {
            purchaseError = "This product is not available right now. Please try again later."
            return
        }

        isPurchasing   = true
        purchaseError  = nil

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try verified(verification)
                appState.activatePro()
                await transaction.finish()

            case .userCancelled:
                break  // user backed out — no error shown

            case .pending:
                purchaseError = "Your purchase is awaiting approval (Ask to Buy). Pro will activate once approved."

            @unknown default:
                break
            }
        } catch {
            purchaseError = "Purchase failed: \(error.localizedDescription)"
        }

        isPurchasing = false
    }

    // MARK: - Restore Purchases

    func restorePurchases(appState: AppState) {
        guard !isPurchasing else { return }
        isPurchasing    = true
        restoreMessage  = nil
        Task {
            do {
                try await AppStore.sync()
                let hasPro = await hasActiveEntitlement()
                if hasPro {
                    appState.activatePro()
                    restoreMessage = "Pro subscription restored successfully."
                } else {
                    restoreMessage = "No active Pro subscription found. Contact support if you believe this is an error."
                }
            } catch {
                restoreMessage = "Restore failed. Check your network and try again."
            }
            isPurchasing = false
        }
    }

    // MARK: - Entitlement Check (call on launch and sign-in)

    func refreshEntitlements(appState: AppState) async {
        if await hasActiveEntitlement() {
            appState.activatePro()
        }
    }

    // MARK: - Transaction Update Listener

    private func listenForTransactionUpdates() -> Task<Void, Error> {
        Task.detached(priority: .background) {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    // Subscription renewed, revoked, or upgraded outside the app
                    await transaction.finish()
                }
            }
        }
    }

    // MARK: - Helpers

    private func hasActiveEntitlement() async -> Bool {
        for await result in Transaction.currentEntitlements {
            if case .verified(let tx) = result,
               (tx.productID == Self.productID6Month || tx.productID == Self.productID12Month),
               tx.revocationDate == nil {
                return true
            }
        }
        return false
    }

    private func verified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error): throw error
        case .verified(let value):      return value
        }
    }
}

// ============================================================
// MARK: - App State
// ============================================================

class AppState: ObservableObject {
    @Published var isAuthenticated      = false
    @Published var hasCompletedOnboard  = false
    @Published var userName             = ""
    @Published var athleteFirst         = ""
    @Published var sport                = "Wrestling"
    @Published var isMinor              = false
    @Published var isPro                = false
    @Published var userId               = ""        // Cognito Auth user UUID
    @Published var latestResult: TLResult? = nil
    @Published var streak               = 0
    @Published var weekSessions         = 0
    @Published var showPaywall          = false
    @Published var legalAccepted        = false
    @Published var experienceLevel      = "High School"
    @Published var trainingPhase        = "In-Season"

    init() {
        load()
        // Verify Pro entitlement against StoreKit on every launch so the
        // correct state is shown even if UserDefaults was cleared.
        Task { @MainActor in
            await SubscriptionManager.shared.refreshEntitlements(appState: self)
        }
    }

    private func load() {
        let d = UserDefaults.standard
        isAuthenticated     = d.bool(forKey: "mrx_auth")
        hasCompletedOnboard = d.bool(forKey: "mrx_onboard")
        userName            = d.string(forKey: "mrx_name")      ?? ""
        athleteFirst        = d.string(forKey: "mrx_first")     ?? ""
        sport               = d.string(forKey: "mrx_sport")     ?? "Wrestling"
        isPro               = d.bool(forKey: "mrx_pro")
        userId              = TokenManager.shared.userId        ?? ""
        streak              = MRXProgressTracker.shared.currentStreak()
        weekSessions        = MRXProgressTracker.shared.weekSessionsCount()
        legalAccepted       = d.bool(forKey: "mrx_legal")
        experienceLevel     = d.string(forKey: "mrx_explevel")  ?? "High School"
        trainingPhase       = d.string(forKey: "mrx_phase")     ?? "In-Season"
    }

    func updateCloudProfile(experienceLevel: String, trainingPhase: String) {
        self.experienceLevel = experienceLevel
        self.trainingPhase   = trainingPhase
        UserDefaults.standard.set(experienceLevel, forKey: "mrx_explevel")
        UserDefaults.standard.set(trainingPhase,   forKey: "mrx_phase")
    }

    func register(name: String) {
        userName     = name
        athleteFirst = String(name.split(separator: " ").first ?? Substring(name))
        isAuthenticated = true
        UserDefaults.standard.set(true, forKey: "mrx_auth")
        UserDefaults.standard.set(name, forKey: "mrx_name")
        UserDefaults.standard.set(athleteFirst, forKey: "mrx_first")
    }

    func finishOnboarding(first: String, sp: String) {
        athleteFirst = first; sport = sp
        hasCompletedOnboard = true
        UserDefaults.standard.set(true,  forKey: "mrx_onboard")
        UserDefaults.standard.set(first, forKey: "mrx_first")
        UserDefaults.standard.set(sp,    forKey: "mrx_sport")
        UserDefaults.standard.set(true,  forKey: "mrx_legal")
        legalAccepted = true
    }

    func saveReadiness(_ r: TLResult) { latestResult = r }

    func recordSession() {
        // Superseded — callers should use MRXProgressTracker.shared.addSessionEntry(...)
    }

    func activatePro() {
        isPro = true
        UserDefaults.standard.set(true, forKey: "mrx_pro")
    }

    func deactivatePro() {
        isPro = false
        UserDefaults.standard.set(false, forKey: "mrx_pro")
    }

    func signOut() {
        let d = UserDefaults.standard
        d.set(false, forKey: "mrx_auth")
        d.set(false, forKey: "mrx_onboard")
        d.set(false, forKey: "mrx_pro")
        isAuthenticated = false
        hasCompletedOnboard = false
        isPro = false
        userId = ""
        userName = ""
        athleteFirst = ""
        TokenManager.shared.clear()
    }

    // Called by AuthManager after a successful Amplify login/signup to hydrate app state.
    func hydrateFromProfile(_ profile: AthleteProfile) {
        if let name = profile.fullName, !name.isEmpty { register(name: name) }
        if let s    = profile.sport               { sport           = s;  UserDefaults.standard.set(s,  forKey: "mrx_sport")    }
        if let el   = profile.experienceLevel     { experienceLevel = el; UserDefaults.standard.set(el, forKey: "mrx_explevel") }
        if let tp   = profile.trainingPhase       { trainingPhase   = tp; UserDefaults.standard.set(tp, forKey: "mrx_phase")    }
        if let pro  = profile.isPro               { activatePro(); _ = pro }
        // A stored profile means the user has already completed onboarding — don't send them back.
        if profile.fullName != nil || profile.sport != nil {
            hasCompletedOnboard = true
            UserDefaults.standard.set(true, forKey: "mrx_onboard")
        }
    }

    func greeting() -> String {
        let h = Calendar.current.component(.hour, from: Date())
        if h < 12 { return "Good morning" }
        if h < 17 { return "Good afternoon" }
        return "Good evening"
    }
}
