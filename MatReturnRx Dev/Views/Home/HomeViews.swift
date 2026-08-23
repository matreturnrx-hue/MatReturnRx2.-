//
//  HomeViews.swift
//  MatReturnRx
//

import SwiftUI

// ============================================================
// MARK: - Root View
// ============================================================

struct RootView: View {
    @EnvironmentObject var app: AppState
    @State private var restoringSession = true

    var body: some View {
        ZStack {
            Color.mrxBg.ignoresSafeArea()

            if restoringSession {
                // Splash while we check for an existing session
                VStack(spacing: 20) {
                    BrandLogoView(compact: false)
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.fightRed))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.mrxBg.ignoresSafeArea())
            } else if !app.isAuthenticated {
                NavigationStack { WelcomeScreen() }
            } else if !app.hasCompletedOnboard {
                OnboardingFlow()
            } else {
                MainTabView()
            }
        }
        .sheet(isPresented: $app.showPaywall) { PaywallScreen() }
        .task {
            await AuthManager.shared.restoreSession(appState: app)
            await MainActor.run { restoringSession = false }
        }
    }
}

// ============================================================
// MARK: - Main Tab View
// ============================================================

struct MainTabView: View {
    @State private var tab = 0
    var body: some View {
        TabView(selection: $tab) {
            HomeTab()
                .tabItem { Label("Home",     systemImage: "house.fill") }
                .tag(0)
            ModulesTab()
                .tabItem { Label("Modules",  systemImage: "rectangle.stack.fill") }
                .tag(1)
            ProgressTab()
                .tabItem { Label("Progress", systemImage: "chart.bar.fill") }
                .tag(2)
            AITabGateView()
                .tabItem { Label("AI Plans", systemImage: "sparkles") }
                .tag(3)
            ProfileTab()
                .tabItem { Label("Profile",  systemImage: "person.fill") }
                .tag(4)
        }
        .accentColor(.mrxBlue)
        .background(Color.mrxBg)
    }
}

// ============================================================
// MARK: - Home Tab
// ============================================================

struct HomeTab: View {
    @EnvironmentObject var app: AppState
    @StateObject private var service = CloudProcessingService()

    @State private var showReadiness    = false
    @State private var selectedModule: MRXModule? = nil
    @State private var cloudResult: CloudResponse? = nil
    @State private var showCloudResult  = false
    @State private var cloudLoading: CloudActionType? = nil
    @State private var cloudError       = ""
    @State private var showCloudError   = false
    @State private var showProUpgrade   = false

    var tlStatus: TrafficLight { app.latestResult?.status ?? .green }
    var tlScore:  Double       { app.latestResult?.score  ?? 0.0 }

    // Quick-action cloud buttons config
    private struct QuickAction: Identifiable {
        let id = UUID()
        let label: String
        let icon: String
        let color: Color
        let action: CloudActionType
    }

    private let quickActions: [QuickAction] = [
        QuickAction(label: "Neck",          icon: "person.fill",          color: AppTheme.recoveryTeal,   action: .neckRehab),
        QuickAction(label: "Shoulder",      icon: "figure.arms.open",     color: AppTheme.electricOrange, action: .shoulderRehab),
        QuickAction(label: "Knee",          icon: "figure.walk",          color: AppTheme.fightRed,       action: .kneeRehab),
        QuickAction(label: "Mobility",      icon: "figure.flexibility",   color: Color.mrxBlue,           action: .mobilityPlan),
        QuickAction(label: "Recovery",      icon: "heart.fill",           color: AppTheme.recoveryTeal,   action: .recoveryScore),
        QuickAction(label: "Return",        icon: "sportscourt.fill",     color: AppTheme.electricOrange, action: .returnToSport),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [AppTheme.deepNavy, Color(red: 0.05, green: 0.05, blue: 0.05)],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {

                        // Header — logo + athlete greeting
                        HStack(alignment: .center) {
                            BrandLogoView(compact: true)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(app.greeting() + ",")
                                    .foregroundColor(.mrxTextMuted)
                                    .font(.system(size: 13))
                                Text(app.athleteFirst.isEmpty ? "Athlete" : app.athleteFirst)
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .padding(.leading, 10)
                            Spacer()
                            Button("Check In") { showReadiness = true }
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 14).padding(.vertical, 8)
                                .background(AppTheme.fightRed)
                                .cornerRadius(20)
                        }

                        // Tagline strip
                        Text("Built for Grapplers. Engineered by PT Science.")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppTheme.fightRed)
                            .kerning(0.3)

                        // Readiness card
                        VStack(alignment: .leading, spacing: 8) {
                            Text("TODAY'S READINESS")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.mrxTextMuted)
                                .kerning(0.8)
                            HStack(alignment: .center) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(tlStatus.emoji + " " + tlStatus.label)
                                        .font(.system(size: 22, weight: .bold))
                                        .foregroundColor(tlStatus.color)
                                    Text(app.latestResult == nil ? "Tap to complete today's check-in" : tlStatus.message)
                                        .font(.system(size: 13))
                                        .foregroundColor(.mrxTextSec)
                                }
                                Spacer()
                                ZStack {
                                    Circle().stroke(tlStatus.color.opacity(0.3), lineWidth: 3)
                                        .frame(width: 60, height: 60)
                                    Circle().trim(from: 0, to: app.latestResult == nil ? 0 : CGFloat(tlScore / 10))
                                        .stroke(tlStatus.color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                                        .frame(width: 60, height: 60)
                                        .rotationEffect(.degrees(-90))
                                    VStack(spacing: 0) {
                                        Text(app.latestResult == nil ? "--" : String(format: "%.1f", tlScore))
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(tlStatus.color)
                                        Text("/10")
                                            .font(.system(size: 10))
                                            .foregroundColor(tlStatus.color)
                                    }
                                }
                            }
                        }
                        .padding(18)
                        .background(tlStatus.bgColor)
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(tlStatus.borderColor, lineWidth: 1.5))
                        .onTapGesture { showReadiness = true }

                        // Stats row
                        HStack(spacing: 10) {
                            StatCard(num: "\(app.streak)🔥", label: "Day Streak")
                            StatCard(num: "\(app.weekSessions)", label: "This Week")
                            StatCard(num: app.latestResult == nil ? "--" : String(format: "%.1f", tlScore), label: "Readiness")
                        }

                        // AI-powered quick actions
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("AI QUICK ACTIONS")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.mrxTextMuted)
                                    .kerning(0.8)
                                Spacer()
                                Image(systemName: "sparkles")
                                    .font(.system(size: 12))
                                    .foregroundColor(AppTheme.electricOrange)
                                Text("Powered by AI")
                                    .font(.system(size: 11))
                                    .foregroundColor(AppTheme.electricOrange)
                            }

                            let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
                            LazyVGrid(columns: columns, spacing: 10) {
                                ForEach(quickActions) { qa in
                                    cloudQuickButton(qa)
                                }
                            }
                        }

                        // Today's Focus — recommended module
                        VStack(alignment: .leading, spacing: 12) {
                            Text("TODAY'S FOCUS")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.mrxTextMuted)
                                .kerning(0.8)
                            let rec = mrxModules[0]
                            HStack {
                                Circle().fill(rec.color).frame(width: 10, height: 10)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(rec.name)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                    Text("\(rec.exerciseCount) exercises · \(rec.durationMin)–\(rec.durationMax) min")
                                        .font(.system(size: 12))
                                        .foregroundColor(.mrxTextMuted)
                                }
                                Spacer()
                                Button("Start →") { selectedModule = rec }
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 14).padding(.vertical, 10)
                                    .background(AppTheme.electricOrange)
                                    .cornerRadius(10)
                            }
                            .padding(14)
                            .background(Color.mrxCard)
                            .cornerRadius(14)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.mrxBorder, lineWidth: 1))
                        }

                        MRXDisclaimerBox(text: D.short, compact: true)
                    }
                    .padding(20)
                }
#if os(iOS)
                .navigationBarHidden(true)
#endif

                // Loading overlay
                if cloudLoading != nil {
                    Color.black.opacity(0.55).ignoresSafeArea()
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.fightRed))
                            .scaleEffect(1.6)
                        Text("Generating \(cloudLoading?.rawValue.replacingOccurrences(of: "_", with: " ").capitalized ?? "plan")...")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(28)
                    .background(Color.mrxCard)
                    .cornerRadius(20)
                }
            }
        }
        .sheet(isPresented: $showReadiness) { DailyReadinessScreen() }
        .sheet(item: $selectedModule) { mod in
            NavigationStack { ExerciseListScreen(module: mod) }
        }
        .sheet(isPresented: $showCloudResult) {
            if let result = cloudResult {
                ResultView(result: result)
            }
        }
        .sheet(isPresented: $showProUpgrade) {
            ProUpgradeScreen()
        }
        .alert("Cloud Error", isPresented: $showCloudError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(cloudError)
        }
    }

    @ViewBuilder
    private func cloudQuickButton(_ qa: QuickAction) -> some View {
        let isLoading = cloudLoading == qa.action
        let locked    = !app.isPro

        Button {
            if locked {
                showProUpgrade = true
            } else {
                guard cloudLoading == nil else { return }
                runCloudAction(qa.action)
            }
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(locked ? Color.white.opacity(0.06) : qa.color.opacity(0.15))
                        .frame(width: 44, height: 44)
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: qa.color))
                            .scaleEffect(0.8)
                    } else if locked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Color.white.opacity(0.3))
                    } else {
                        Image(systemName: qa.icon)
                            .font(.system(size: 18))
                            .foregroundColor(qa.color)
                    }
                }
                Text(qa.label)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(locked ? .mrxTextMuted : (isLoading ? qa.color.opacity(0.6) : .white))
                Text(locked ? "Pro" : "AI Plan")
                    .font(.system(size: 10, weight: locked ? .bold : .regular))
                    .foregroundColor(locked ? AppTheme.fightRed : .mrxTextMuted)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(locked ? Color.mrxCard.opacity(0.5) : Color.mrxCard)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(locked ? Color.white.opacity(0.08) : qa.color.opacity(isLoading ? 0.6 : 0.3), lineWidth: 1)
            )
        }
        .disabled(!locked && cloudLoading != nil)
    }

    func runCloudAction(_ actionType: CloudActionType) {
        cloudLoading = actionType
        Task {
            do {
                let result = try await service.processAction(
                    actionType,
                    painLevel:      0,
                    symptoms:       "",
                    injuryLocation: "",
                    appState:       app
                )
                await MainActor.run {
                    cloudResult  = result
                    showCloudResult = true
                    cloudLoading = nil
                }
            } catch {
                await MainActor.run {
                    cloudError   = error.localizedDescription
                    showCloudError = true
                    cloudLoading = nil
                }
            }
        }
    }
}

// ============================================================
// MARK: - Progress Tab
// ============================================================

struct ProgressTab: View {
    @EnvironmentObject var app: AppState
    @State private var selectedPeriod: ProgressPeriod = .week
    @State private var readinessEntries: [MRXReadinessEntry] = []
    
    enum ProgressPeriod: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case all = "All Time"
    }
    
    var filteredEntries: [MRXReadinessEntry] {
        let now = Date()
        switch selectedPeriod {
        case .week:
            let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now
            return readinessEntries.filter { $0.timestamp >= weekAgo }
        case .month:
            let monthAgo = Calendar.current.date(byAdding: .day, value: -30, to: now) ?? now
            return readinessEntries.filter { $0.timestamp >= monthAgo }
        case .all:
            return readinessEntries
        }
    }
    
    var averageScore: Double {
        guard !filteredEntries.isEmpty else { return 0 }
        let total = filteredEntries.reduce(0.0) { $0 + $1.readinessScore }
        return total / Double(filteredEntries.count)
    }
    
    var greenDays: Int {
        filteredEntries.filter { $0.status == .green }.count
    }
    
    var yellowDays: Int {
        filteredEntries.filter { $0.status == .yellow }.count
    }
    
    var redDays: Int {
        filteredEntries.filter { $0.status == .red }.count
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [AppTheme.deepNavy, Color(red: 0.05, green: 0.05, blue: 0.05)],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        // Header
                        Text("Your Progress")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Track your readiness and training consistency over time.")
                            .font(.system(size: 14))
                            .foregroundColor(.mrxTextSec)
                        
                        // Period selector
                        Picker("Period", selection: $selectedPeriod) {
                            ForEach(ProgressPeriod.allCases, id: \.self) { period in
                                Text(period.rawValue).tag(period)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.vertical, 8)
                        
                        // Stats overview
                        VStack(alignment: .leading, spacing: 12) {
                            Text("OVERVIEW")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.mrxTextMuted)
                                .kerning(0.8)
                            
                            VStack(spacing: 12) {
                                HStack(spacing: 10) {
                                    ProgressStatCard(
                                        value: String(format: "%.1f", averageScore),
                                        label: "Avg Score",
                                        color: .mrxBlue
                                    )
                                    ProgressStatCard(
                                        value: "\(filteredEntries.count)",
                                        label: "Check-Ins",
                                        color: AppTheme.electricOrange
                                    )
                                }
                                
                                HStack(spacing: 10) {
                                    ProgressStatCard(
                                        value: "\(greenDays)",
                                        label: "Green Days",
                                        color: .mrxGreen
                                    )
                                    ProgressStatCard(
                                        value: "\(yellowDays)",
                                        label: "Yellow Days",
                                        color: .mrxYellow
                                    )
                                    ProgressStatCard(
                                        value: "\(redDays)",
                                        label: "Red Days",
                                        color: .mrxDanger
                                    )
                                }
                            }
                        }
                        
                        // Readiness history
                        VStack(alignment: .leading, spacing: 12) {
                            Text("READINESS HISTORY")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.mrxTextMuted)
                                .kerning(0.8)
                            
                            if filteredEntries.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "chart.line.uptrend.xyaxis")
                                        .font(.system(size: 48))
                                        .foregroundColor(.mrxTextMuted)
                                    Text("No Data Yet")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                    Text("Complete your first daily check-in to start tracking progress.")
                                        .font(.system(size: 14))
                                        .foregroundColor(.mrxTextMuted)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(32)
                                .background(Color.mrxCard)
                                .cornerRadius(16)
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.mrxBorder, lineWidth: 1))
                            } else {
                                ForEach(filteredEntries.sorted(by: { $0.timestamp > $1.timestamp })) { entry in
                                    ReadinessHistoryRow(entry: entry)
                                }
                            }
                        }
                        
                        MRXDisclaimerBox(text: D.short, compact: true)
                    }
                    .padding(20)
                }
            }
#if os(iOS)
            .navigationBarHidden(true)
#endif
        }
        .task {
            // Load readiness entries
            readinessEntries = MRXProgressTracker.shared.allEntries.filter { $0.userId == app.userId }
        }
    }
}

struct ProgressStatCard: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.mrxTextMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(Color.mrxCard)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(color.opacity(0.3), lineWidth: 1))
    }
}

struct ReadinessHistoryRow: View {
    let entry: MRXReadinessEntry
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: entry.timestamp)
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Status indicator
            VStack(spacing: 4) {
                Text(entry.status.emoji)
                    .font(.system(size: 24))
                Circle()
                    .fill(entry.status.color)
                    .frame(width: 8, height: 8)
            }
            .frame(width: 44)
            
            // Details
            VStack(alignment: .leading, spacing: 4) {
                Text(formattedDate)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "bed.double.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.mrxTextMuted)
                        Text("\(Int(entry.sleep))")
                            .font(.system(size: 11))
                            .foregroundColor(.mrxTextSec)
                    }
                    HStack(spacing: 4) {
                        Image(systemName: "figure.walk")
                            .font(.system(size: 10))
                            .foregroundColor(.mrxTextMuted)
                        Text("\(Int(entry.soreness))")
                            .font(.system(size: 11))
                            .foregroundColor(.mrxTextSec)
                    }
                    HStack(spacing: 4) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 10))
                            .foregroundColor(.mrxTextMuted)
                        Text("\(Int(entry.stress))")
                            .font(.system(size: 11))
                            .foregroundColor(.mrxTextSec)
                    }
                    if entry.pain > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.mrxYellow)
                            Text("\(Int(entry.pain))")
                                .font(.system(size: 11))
                                .foregroundColor(.mrxYellow)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Score
            VStack(spacing: 2) {
                Text(String(format: "%.1f", entry.readinessScore))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(entry.status.color)
                Text("/ 10")
                    .font(.system(size: 10))
                    .foregroundColor(.mrxTextMuted)
            }
        }
        .padding(14)
        .background(entry.status.bgColor)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(entry.status.borderColor, lineWidth: 1))
    }
}

// ============================================================
// MARK: - Daily Readiness Screen
// ============================================================

struct DailyReadinessScreen: View {
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) var dismiss
    @State private var readiness:   Double = 5
    @State private var soreness:    Double = 3
    @State private var sleep:       Double = 5
    @State private var stress:      Double = 3
    @State private var motivation:  Double = 5
    @State private var pain:        Double = 0
    @State private var confidence:  Double = 7
    @State private var showResult   = false
    @State private var result: TLResult? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("How Are You Feeling?")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                    Text("Rate each area. Be honest — this guides your session.")
                        .foregroundColor(.mrxTextSec)
                        .font(.system(size: 14))

                    SliderRow(label: "Overall Readiness",  sub: "How ready to train?",          val: $readiness,  positiveScale: true)
                    SliderRow(label: "Muscle Soreness",    sub: "How sore are your muscles?",    val: $soreness,   positiveScale: false)
                    SliderRow(label: "Sleep Quality",      sub: "How well did you sleep?",       val: $sleep,      positiveScale: true)
                    SliderRow(label: "Stress Level",       sub: "Mental and life stress?",       val: $stress,     positiveScale: false)
                    SliderRow(label: "Motivation",         sub: "Motivated to train today?",     val: $motivation, positiveScale: true)
                    SliderRow(label: "Pain / Soreness",    sub: "Any current pain? 0 = none",    val: $pain,       positiveScale: false)
                    SliderRow(label: "Confidence to Train",sub: "How confident are you?",        val: $confidence, positiveScale: true)

                    if pain >= 5 {
                        HStack(spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.mrxYellow)
                            Text("Pain at \(Int(pain))/10 is significant. Your readiness result will reflect this.")
                                .font(.system(size: 13))
                                .foregroundColor(.mrxYellow)
                        }
                        .padding(14)
                        .background(Color.mrxYellow.opacity(0.12))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.mrxYellow.opacity(0.5), lineWidth: 1))
                    }

                    MRXButton(title: "See My Recommendation →") {
                        let r = evaluateReadiness(readiness: readiness, soreness: soreness, sleep: sleep,
                                                  stress: stress, motivation: motivation, pain: pain, confidence: confidence)
                        result = r
                        app.saveReadiness(r)
                        MRXProgressTracker.shared.addReadinessEntry(
                            userId: app.userId, score: r.score, status: r.status,
                            sleep: sleep, soreness: soreness, stress: stress,
                            pain: pain, appState: app
                        )
                        showResult = true
                    }

                    MRXDisclaimerBox(text: D.short, compact: true)
                }
                .padding(20)
            }
            .background(Color.mrxBg.ignoresSafeArea())
            .navigationTitle("Daily Readiness")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.mrxBlue)
                }
            }
#elseif os(macOS)
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.mrxBlue)
                }
            }
#endif
            .sheet(isPresented: $showResult) {
                if let r = result { ReadinessResultScreen(result: r) }
            }
        }
    }
}

struct SliderRow: View {
    let label:          String
    let sub:            String
    @Binding var val:   Double
    let positiveScale:  Bool

    var sliderColor: Color {
        if positiveScale {
            if val >= 7 { return .mrxGreen }
            if val >= 4 { return .mrxYellow }
            return .mrxDanger
        } else {
            if val >= 7 { return .mrxDanger }
            if val >= 4 { return .mrxYellow }
            return .mrxGreen
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(label).font(.system(size: 15, weight: .semibold)).foregroundColor(.white)
                    Text(sub).font(.system(size: 12)).foregroundColor(.mrxTextMuted)
                }
                Spacer()
                Text("\(Int(val))")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(sliderColor)
                    .frame(width: 36, height: 36)
                    .background(sliderColor.opacity(0.15))
                    .clipShape(Circle())
            }
            Slider(value: $val, in: 0...10, step: 1)
                .accentColor(sliderColor)
            HStack {
                Text(positiveScale ? "Not ready" : "None")
                    .font(.system(size: 10)).foregroundColor(.mrxTextMuted)
                Spacer()
                Text(positiveScale ? "Fully ready" : "Very high")
                    .font(.system(size: 10)).foregroundColor(.mrxTextMuted)
            }
        }
        .padding(14)
        .background(Color.mrxCard)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.mrxBorder, lineWidth: 1))
    }
}

struct ReadinessResultScreen: View {
    let result: TLResult
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    VStack(spacing: 12) {
                        Text(result.status.emoji)
                            .font(.system(size: 52))
                        Text(result.status.label)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(result.status.color)
                        Text(result.status.message)
                            .font(.system(size: 15))
                            .foregroundColor(.mrxTextSec)
                            .multilineTextAlignment(.center)

                        ZStack {
                            Circle().stroke(result.status.color.opacity(0.2), lineWidth: 8).frame(width: 100, height: 100)
                            VStack(spacing: 0) {
                                Text(String(format: "%.1f", result.score))
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(result.status.color)
                                Text("/ 10").font(.system(size: 12)).foregroundColor(result.status.color)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(28)
                    .background(result.status.bgColor)
                    .cornerRadius(20)
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(result.status.borderColor, lineWidth: 1.5))

                    VStack(alignment: .leading, spacing: 8) {
                        Text("RECOMMENDATION")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.mrxTextMuted).kerning(0.8)
                        Text(result.status.recommendation)
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(16)
                    .background(Color.mrxCard)
                    .cornerRadius(14)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.mrxBorder, lineWidth: 1))

                    if result.status == .red {
                        MRXDisclaimerBox(text: D.core)
                    }

                    MRXButton(title: "View Modules →") { dismiss() }
                }
                .padding(20)
            }
            .background(Color.mrxBg.ignoresSafeArea())
            .navigationTitle("Your Readiness")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }.foregroundColor(.mrxBlue)
                }
            }
#elseif os(macOS)
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Close") { dismiss() }.foregroundColor(.mrxBlue)
                }
            }
#endif
        }
    }
}
