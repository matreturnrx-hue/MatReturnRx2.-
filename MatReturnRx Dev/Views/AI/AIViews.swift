//
//  AIViews.swift
//  MatReturnRx
//

import SwiftUI

// ============================================================
// MARK: - AI Tab Gate
// ============================================================
// Checks subscription status before granting access to DashboardView.
// isProUser == true  → full AI Tab
// isProUser == false → ProUpgradeScreen paywall

struct AITabGateView: View {
    @EnvironmentObject var app: AppState

    var body: some View {
        if app.isPro {
            DashboardView()
        } else {
            AILockedView()
        }
    }
}

struct AILockedView: View {
    @EnvironmentObject var app: AppState
    @State private var showUpgrade = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [AppTheme.deepNavy, Color(red: 0.05, green: 0.05, blue: 0.05)],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 28) {
                    Spacer()

                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.fightRed.opacity(0.12))
                                .frame(width: 96, height: 96)
                            Image(systemName: "lock.fill")
                                .font(.system(size: 36))
                                .foregroundColor(AppTheme.fightRed)
                        }

                        VStack(spacing: 8) {
                            Text("AI Plans · Pro Feature")
                                .font(.system(size: 22, weight: .black))
                                .foregroundColor(.white)
                            Text("Personalized AI training, injury prevention, recovery plans, and performance programming are available exclusively to Pro members.")
                                .font(.system(size: 14))
                                .foregroundColor(.mrxTextSec)
                                .multilineTextAlignment(.center)
                                .lineSpacing(3)
                        }
                    }
                    .padding(.horizontal, 32)

                    // Mini pro feature preview
                    VStack(alignment: .leading, spacing: 10) {
                        Text("INCLUDED WITH PRO")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.mrxTextMuted)
                            .kerning(0.8)
                        ForEach([
                            ("sparkles",          "Personalized AI exercise plans"),
                            ("cross.case.fill",   "Injury prevention & recovery programming"),
                            ("heart.fill",        "Recovery & performance support"),
                            ("sportscourt.fill",  "Return-to-sport guidance"),
                        ], id: \.0) { icon, label in
                            HStack(spacing: 12) {
                                Image(systemName: icon)
                                    .font(.system(size: 14))
                                    .foregroundColor(AppTheme.recoveryTeal)
                                    .frame(width: 20)
                                Text(label)
                                    .font(.system(size: 13))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(16)
                    .background(Color.mrxCard)
                    .cornerRadius(14)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.mrxBorder, lineWidth: 1))
                    .padding(.horizontal, 24)

                    // Pricing teaser
                    VStack(spacing: 4) {
                        Text("Starting at $10.99/month")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                        Text("12-Month Plan · Best Value")
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.electricOrange)
                    }

                    VStack(spacing: 10) {
                        Button { showUpgrade = true } label: {
                            Text("Unlock AI Pro")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(AppTheme.fightRed)
                                .cornerRadius(14)
                        }
                        .padding(.horizontal, 24)

                        Text("Cancel anytime. Subscription terms apply.")
                            .font(.system(size: 11))
                            .foregroundColor(Color.white.opacity(0.25))
                    }

                    Spacer()
                }
            }
            .navigationTitle("AI Plans")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
        }
        .sheet(isPresented: $showUpgrade) {
            ProUpgradeScreen()
        }
    }
}

// ============================================================
// MARK: - Dashboard View
// ============================================================

struct DashboardView: View {
    @EnvironmentObject var app: AppState
    @StateObject private var service = CloudProcessingService()

    @State private var painLevel:      Double = 0
    @State private var symptoms:       String = ""
    @State private var injuryLocation: String = "None"

    @State private var isLoading       = false
    @State private var selectedResult: CloudResponse? = nil
    @State private var showResult      = false
    @State private var errorMessage    = ""
    @State private var showError       = false
    @State private var lastAction:     CloudActionType? = nil

    private let bodyParts = ["None", "Neck", "Shoulder", "Knee", "Hip",
                             "Lower Back", "Ankle", "Wrist", "Elbow", "Multiple"]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.mrxBg.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {

                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 10) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 20))
                                    .foregroundColor(AppTheme.electricOrange)
                                Text("AI Plans")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            Text("Personalized plans powered by your profile and AWS Amplify AI.")
                                .font(.system(size: 13))
                                .foregroundColor(.mrxTextSec)
                            HStack(spacing: 6) {
                                badge(app.sport,           color: AppTheme.fightRed)
                                badge(app.experienceLevel, color: AppTheme.recoveryTeal)
                                badge(app.trainingPhase,   color: .mrxTextMuted)
                            }
                        }

                        // Service connectivity warning (debug only)
                        #if DEBUG
                        if !AmplifyConfig.isConfigured {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.mrxYellow)
                                Text("AI service not configured (debug)")
                                    .font(.system(size: 12))
                                    .foregroundColor(.mrxYellow)
                            }
                            .padding(10)
                            .background(Color.mrxYellow.opacity(0.1))
                            .cornerRadius(10)
                        }
                        #endif

                        // Session context card
                        VStack(alignment: .leading, spacing: 14) {
                            Text("TODAY'S CONTEXT")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.mrxTextMuted)
                                .kerning(0.8)

                            HStack {
                                Text("Pain level: \(Int(painLevel))/10")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(painLevel >= 5 ? .mrxDanger : painLevel >= 3 ? .mrxYellow : .white)
                                Spacer()
                                if painLevel >= 5 {
                                    Text("High pain — use caution")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.mrxDanger)
                                }
                            }
                            Slider(value: $painLevel, in: 0...10, step: 1)
                                .accentColor(painLevel >= 5 ? .mrxDanger : painLevel >= 3 ? .mrxYellow : .mrxBlue)

                            Divider().background(Color.mrxDivider)

                            MRXPickerRow(
                                label:     "Injury / Problem Area",
                                selection: $injuryLocation,
                                options:   bodyParts
                            )

                            Divider().background(Color.mrxDivider)

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Symptoms / Notes (optional)")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.mrxTextMuted)
                                TextField("e.g. sharp pain, stiffness, clicking sound...", text: $symptoms)
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(Color.mrxBg)
                                    .cornerRadius(10)
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.mrxBorder, lineWidth: 1))
                            }
                        }
                        .padding(14)
                        .background(Color.mrxCard)
                        .cornerRadius(14)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.mrxBorder, lineWidth: 1))

                        // Button sections
                        dashSection(title: "DAILY",               actions: CloudActionType.dailyActions)
                        dashSection(title: "NUTRITION & WEIGHT",  actions: CloudActionType.nutritionActions)
                        dashSection(title: "SAFETY & WELLNESS",   actions: CloudActionType.wellnessActions)
                        dashSection(title: "INJURY PREVENTION & RECOVERY", actions: CloudActionType.rehabActions)

                        MRXDisclaimerBox(text: D.core)
                    }
                    .padding(20)
                }

                // Loading overlay
                if isLoading {
                    Color.black.opacity(0.55).ignoresSafeArea()
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(1.4)
                            .tint(.mrxBlue)
                        if let action = lastAction {
                            Text("Building your \(action.displayName)...")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                        }
                        Text("AWS Amplify AI is personalizing your plan")
                            .font(.system(size: 12))
                            .foregroundColor(.mrxTextMuted)
                    }
                    .padding(28)
                    .background(Color.mrxCard)
                    .cornerRadius(20)
                }
            }
#if os(iOS)
            .navigationBarHidden(true)
#endif
        }
        .sheet(isPresented: $showResult) {
            if let result = selectedResult { ResultView(result: result) }
        }
        .alert("Unable to Process Request", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    // Button grid section
    @ViewBuilder
    func dashSection(title: String, actions: [CloudActionType]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.mrxTextMuted)
                .kerning(0.8)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(actions, id: \.rawValue) { action in
                    actionButton(action)
                }
            }
        }
    }

    @ViewBuilder
    func actionButton(_ action: CloudActionType) -> some View {
        Button { trigger(action) } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: action.icon)
                        .font(.system(size: 20))
                        .foregroundColor(action.color)
                        .frame(width: 28)
                    Spacer()
                    Image(systemName: "sparkles")
                        .font(.system(size: 10))
                        .foregroundColor(action.color.opacity(0.55))
                }
                Text(action.displayName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Tap to generate →")
                    .font(.system(size: 11))
                    .foregroundColor(.mrxTextMuted)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.mrxCard)
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(action.color.opacity(0.25), lineWidth: 1))
            .opacity(isLoading ? 0.5 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }

    func badge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(color)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(color.opacity(0.12))
            .cornerRadius(6)
    }

    func trigger(_ action: CloudActionType) {
        lastAction = action
        isLoading  = true
        Task {
            do {
                let result = try await service.processAction(
                    action,
                    painLevel:      Int(painLevel),
                    symptoms:       symptoms,
                    injuryLocation: injuryLocation == "None" ? "" : injuryLocation,
                    appState:       app
                )
                await MainActor.run {
                    selectedResult = result
                    showResult     = true
                    isLoading      = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError    = true
                    isLoading    = false
                }
            }
        }
    }
}

// ============================================================
// MARK: - Result View
// ============================================================

struct ResultView: View {
    let result: CloudResponse
    @Environment(\.dismiss) var dismiss

    private var hasSafetyFlags: Bool { !(result.safetyFlags?.isEmpty ?? true) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // Safety banner — always shown first when flags exist
                    if hasSafetyFlags {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.mrxDanger)
                                    .font(.system(size: 18))
                                Text("SAFETY WARNING — READ FIRST")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.mrxDanger)
                                    .kerning(0.4)
                            }
                            ForEach(result.safetyFlags ?? [], id: \.self) { flag in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.mrxDanger)
                                        .font(.system(size: 13))
                                        .padding(.top, 1)
                                    Text(flag)
                                        .font(.system(size: 13))
                                        .foregroundColor(.white)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            Divider().background(Color.mrxDanger.opacity(0.4))
                            Text("Stop activity. Seek evaluation from a qualified healthcare professional before continuing.")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.mrxDanger)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(14)
                        .background(Color.mrxDanger.opacity(0.1))
                        .cornerRadius(14)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.mrxDanger.opacity(0.5), lineWidth: 1.5))
                    }

                    // Summary
                    resultBlock(title: "SUMMARY") {
                        Text(result.summary)
                            .font(.system(size: 14))
                            .foregroundColor(.mrxTextSec)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    // Recommendations
                    if !result.recommendations.isEmpty {
                        resultList(
                            title: "RECOMMENDATIONS",
                            items: result.recommendations,
                            icon:  "checkmark.circle.fill",
                            color: AppTheme.recoveryTeal
                        )
                    }

                    // Progressions
                    if let p = result.progressions, !p.isEmpty {
                        resultList(
                            title: "PROGRESSIONS",
                            items: p,
                            icon:  "arrow.up.circle.fill",
                            color: .mrxGreen
                        )
                    }

                    // Regressions / Modifications
                    if let r = result.regressions, !r.isEmpty {
                        resultList(
                            title: "REGRESSIONS / MODIFICATIONS",
                            items: r,
                            icon:  "arrow.down.circle.fill",
                            color: .mrxYellow
                        )
                    }

                    // Next Step
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "arrow.right.circle.fill")
                            .foregroundColor(AppTheme.electricOrange)
                            .font(.system(size: 18))
                        VStack(alignment: .leading, spacing: 4) {
                            Text("NEXT STEP")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(AppTheme.electricOrange)
                                .kerning(0.8)
                            Text(result.nextStep)
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(14)
                    .background(AppTheme.electricOrange.opacity(0.1))
                    .cornerRadius(14)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.electricOrange.opacity(0.3), lineWidth: 1))

                    MRXDisclaimerBox(text: D.core)
                }
                .padding(20)
            }
            .background(Color.mrxBg.ignoresSafeArea())
            .navigationTitle(result.title)
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.foregroundColor(AppTheme.fightRed)
                }
            }
#elseif os(macOS)
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Done") { dismiss() }.foregroundColor(AppTheme.fightRed)
                }
            }
#endif
        }
    }

    @ViewBuilder
    func resultBlock<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.mrxTextMuted)
                .kerning(0.8)
            content()
        }
        .padding(14)
        .background(Color.mrxCard)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.mrxBorder, lineWidth: 1))
    }

    @ViewBuilder
    func resultList(title: String, items: [String], icon: String, color: Color) -> some View {
        resultBlock(title: title) {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: icon)
                            .foregroundColor(color)
                            .font(.system(size: 13))
                            .padding(.top, 1)
                        Text(item)
                            .font(.system(size: 14))
                            .foregroundColor(.mrxTextSec)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }
}
