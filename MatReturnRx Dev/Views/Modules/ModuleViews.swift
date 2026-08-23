//
//  ModuleViews.swift
//  MatReturnRx
//

import SwiftUI
import Combine

#if os(iOS)
import UIKit
#endif

// ============================================================
// MARK: - Modules Tab
// ============================================================

struct ModulesTab: View {
    @EnvironmentObject var app: AppState
    @State private var selectedModule: MRXModule? = nil
    @State private var showUpgrade = false

    // Pillar groupings by module ID
    var freeModules: [MRXModule]     { mrxModules.filter { !$0.isPro } }
    var performModules: [MRXModule]  { mrxModules.filter { ["grp"].contains($0.id) } }
    var returnModules: [MRXModule]   { mrxModules.filter { ["rtm"].contains($0.id) } }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [AppTheme.deepNavy, Color(red: 0.05, green: 0.05, blue: 0.05)],
                    startPoint: .top, 
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {

                        // Header
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 10) {
                                BrandLogoView(compact: true)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Training Modules")
                                        .font(.system(size: 22, weight: .bold))
                                        .foregroundColor(.white)
                                    Text("Built for Grapplers. Engineered by PT Science.")
                                        .font(.system(size: 12))
                                        .foregroundColor(AppTheme.fightRed)
                                }
                            }
                            Text("Select a pillar. Work the protocol. Return to the mat.")
                                .font(.system(size: 13))
                                .foregroundColor(.mrxTextSec)
                                .padding(.top, 2)
                        }

                        // Access tier banner
                        if !app.isPro {
                            HStack(spacing: 12) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(AppTheme.electricOrange)
                                    .font(.system(size: 16))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Basic Access — Free Plan")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.white)
                                    Text("Upgrade to Pro to unlock personalized training programs, grappling performance, and return-to-sport protocols.")
                                        .font(.system(size: 11))
                                        .foregroundColor(.mrxTextSec)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                Spacer()
                                Button("Upgrade") { showUpgrade = true }
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10).padding(.vertical, 6)
                                    .background(AppTheme.fightRed)
                                    .cornerRadius(8)
                            }
                            .padding(14)
                            .background(AppTheme.electricOrange.opacity(0.08))
                            .cornerRadius(14)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.electricOrange.opacity(0.25), lineWidth: 1))
                        }

                        // ── PRO · PERSONALIZED PROGRAM
                        if app.isPro {
                            ProPersonalizedProgramCard(selectedModule: $selectedModule)
                        }

                        // ── BASIC · FREE ACCESS
                        pillarSection(
                            title: "BASIC · FREE ACCESS",
                            icon:  "checkmark.seal.fill",
                            color: .mrxGreen,
                            subtitle: "Available to all users",
                            modules: freeModules,
                            locked: false
                        )

                        // ── PRO · PERFORMANCE
                        pillarSection(
                            title: "PRO · PERFORMANCE",
                            icon:  "bolt.fill",
                            color: AppTheme.electricOrange,
                            subtitle: "Combat sport-specific strength & conditioning",
                            modules: performModules,
                            locked: !app.isPro
                        )

                        // ── PRO · RETURN TO SPORT
                        pillarSection(
                            title: "PRO · RETURN TO SPORT",
                            icon:  "sportscourt.fill",
                            color: AppTheme.fightRed,
                            subtitle: "Progressive return-to-mat protocol",
                            modules: returnModules,
                            locked: !app.isPro
                        )

                        // ── COMING SOON
                        comingSoonSection

                        // Pro upgrade banner for free users
                        if !app.isPro {
                            proUpgradeBanner
                        }

                        MRXDisclaimerBox(text: D.short, compact: true)
                    }
                    .padding(20)
                }
#if os(iOS)
                .navigationBarHidden(true)
#endif
            }
        }
        .sheet(item: $selectedModule) { mod in
            NavigationStack { ExerciseListScreen(module: mod) }
        }
        .sheet(isPresented: $showUpgrade) {
            ProUpgradeScreen()
        }
    }

    // MARK: Pillar section builder
    @ViewBuilder
    func pillarSection(title: String, icon: String, color: Color,
                       subtitle: String, modules: [MRXModule], locked: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Section header
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 13))
                        .foregroundColor(color)
                    Text(title)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(color)
                        .kerning(0.7)
                    if locked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10))
                            .foregroundColor(AppTheme.fightRed)
                    }
                }
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.mrxTextMuted)
            }

            ForEach(modules) { mod in
                ModuleCard(module: mod, locked: locked) {
                    if locked {
                        showUpgrade = true
                    } else {
                        selectedModule = mod
                    }
                }
            }
        }
    }

    // MARK: Coming soon section
    var comingSoonSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 13))
                    .foregroundColor(.mrxTextMuted)
                Text("COMING SOON")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.mrxTextMuted)
                    .kerning(0.7)
            }
            Text("More Pro modules being built by the MatReturnRx PT team.")
                .font(.system(size: 12))
                .foregroundColor(.mrxTextMuted)

            VStack(spacing: 8) {
                comingSoonCard(name: "Hydration & Weight-Cut Protocol", icon: "drop.fill",
                               detail: "Sport-specific hydration and safe weight-cut planning.")
                comingSoonCard(name: "Ankle & Foot Injury Prevention",    icon: "figure.walk",
                               detail: "Restoration of ankle stability and push-off power.")
                comingSoonCard(name: "Mental Performance",               icon: "brain.head.profile",
                               detail: "Mindset tools for competition preparation and recovery.")
                comingSoonCard(name: "Grip & Wrist Training",            icon: "hand.raised.fill",
                               detail: "Build grip endurance and wrist resilience for grappling.")
            }
        }
    }

    func comingSoonCard(name: String, icon: String, detail: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.mrxTextMuted)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.mrxTextMuted)
                Text(detail)
                    .font(.system(size: 12))
                    .foregroundColor(Color.mrxTextMuted.opacity(0.7))
            }
            Spacer()
            Text("SOON")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.mrxTextMuted)
                .padding(.horizontal, 7).padding(.vertical, 3)
                .background(Color.mrxBorder)
                .cornerRadius(5)
        }
        .padding(14)
        .background(Color.mrxCard.opacity(0.5))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.mrxBorder, lineWidth: 1))
        .opacity(0.55)
    }

    // MARK: Pro upgrade banner
    var proUpgradeBanner: some View {
        VStack(spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .foregroundColor(AppTheme.electricOrange)
                    .font(.system(size: 18))
                VStack(alignment: .leading, spacing: 3) {
                    Text("Unlock the Full MatReturnRx System")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                    Text("Personalized training programs, grappling performance, return-to-sport protocols, and all future modules.")
                        .font(.system(size: 12))
                        .foregroundColor(.mrxTextSec)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Button { showUpgrade = true } label: {
                Text("View Pro Plans — from $10.99/month")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppTheme.fightRed)
                    .cornerRadius(14)
            }
        }
        .padding(18)
        .background(AppTheme.fightRed.opacity(0.07))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.fightRed.opacity(0.25), lineWidth: 1))
    }
}

// MARK: - Module Card

struct ModuleCard: View {
    let module:  MRXModule
    var locked:  Bool = false
    let onTap:   () -> Void

    var accentColor: Color { locked ? Color.white.opacity(0.18) : module.color }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 0) {
                // Color accent bar
                Rectangle()
                    .fill(accentColor)
                    .frame(width: 4)

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(module.name)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(locked ? .mrxTextMuted : module.color)
                        Spacer()
                        if locked {
                            HStack(spacing: 4) {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 9))
                                Text("PRO")
                                    .font(.system(size: 10, weight: .bold))
                            }
                            .foregroundColor(AppTheme.fightRed)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(AppTheme.fightRed.opacity(0.12))
                            .cornerRadius(6)
                        }
                    }
                    Text(module.tagline)
                        .font(.system(size: 13))
                        .foregroundColor(locked ? Color.mrxTextMuted.opacity(0.6) : .mrxTextSec)
                    Text("\(module.exerciseCount) exercises · \(module.durationMin)–\(module.durationMax) min")
                        .font(.system(size: 12))
                        .foregroundColor(.mrxTextMuted)
                }
                .padding(16)

                Image(systemName: locked ? "lock.fill" : "chevron.right")
                    .font(.system(size: locked ? 14 : 13, weight: .semibold))
                    .foregroundColor(locked ? AppTheme.fightRed.opacity(0.5) : module.color)
                    .padding(.trailing, 16)
            }
            .background(locked ? Color.mrxCard.opacity(0.55) : Color.mrxCard)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(locked ? Color.white.opacity(0.07) : module.color.opacity(0.3), lineWidth: 1)
            )
            .opacity(locked ? 0.8 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

// ============================================================
// MARK: - Exercise List Screen
// ============================================================

struct ExerciseListScreen: View {
    let module: MRXModule
    @EnvironmentObject var app: AppState
    @State private var showRedFlag  = false
    @State private var clearToPlay  = false
    @State private var showPlayer   = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Circle().fill(module.color).frame(width: 10, height: 10)
                    Text(module.name)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                }
                Text(module.tagline)
                    .foregroundColor(.mrxTextSec).font(.system(size: 14))
                Text("\(module.exerciseCount) exercises · \(module.durationMin)–\(module.durationMax) min")
                    .foregroundColor(.mrxTextMuted).font(.system(size: 13))
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.mrxCard)

            ScrollView {
                VStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: "info.circle.fill").foregroundColor(module.color).font(.system(size: 14))
                            Text("Evidence Panel").font(.system(size: 12, weight: .semibold)).foregroundColor(module.color)
                        }
                        Text(module.evidencePanel)
                            .font(.system(size: 12))
                            .foregroundColor(.mrxTextSec)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(14)
                    .background(module.color.opacity(0.08))
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(module.color.opacity(0.3), lineWidth: 1))
                    .padding(.horizontal, 20).padding(.top, 16)

                    ForEach(Array(module.exercises.enumerated()), id: \.element.id) { idx, ex in
                        HStack(spacing: 12) {
                            Text("\(idx + 1)")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(module.color)
                                .frame(width: 28, height: 28)
                                .background(module.color.opacity(0.15))
                                .clipShape(Circle())
                            VStack(alignment: .leading, spacing: 3) {
                                Text(ex.name)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.white)
                                Text("\(ex.sets) sets · \(ex.reps)")
                                    .font(.system(size: 12))
                                    .foregroundColor(.mrxTextMuted)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 20).padding(.vertical, 12)
                        Divider().background(Color.mrxDivider).padding(.horizontal, 20)
                    }

                    VStack(spacing: 12) {
                        MRXButton(title: "Start Session — Safety Check →", color: module.color) {
                            showRedFlag = true
                        }
                        MRXDisclaimerBox(text: D.short, compact: true)
                    }
                    .padding(20)
                }
            }
        }
        .background(Color.mrxBg.ignoresSafeArea())
        .navigationTitle("")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .toolbar {
#if os(iOS)
            ToolbarItem(placement: .topBarTrailing) {
                Button("Close") { dismiss() }.foregroundColor(.mrxBlue)
            }
#else
            ToolbarItem(placement: .automatic) {
                Button("Close") { dismiss() }.foregroundColor(.mrxBlue)
            }
#endif
        }
#if os(iOS)
        .fullScreenCover(isPresented: $showPlayer) {
            ExercisePlayerScreen(module: module)
        }
#else
        .sheet(isPresented: $showPlayer) {
            ExercisePlayerScreen(module: module)
        }
#endif
        .sheet(isPresented: $showRedFlag) {
            NavigationStack {
                RedFlagCheckScreen(module: module) {
                    showRedFlag = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showPlayer = true
                    }
                }
                .navigationTitle("Safety Check")
#if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
#endif
                .toolbar {
#if os(iOS)
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") { showRedFlag = false }.foregroundColor(.mrxBlue)
                    }
#else
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showRedFlag = false }.foregroundColor(.mrxBlue)
                    }
#endif
                }
            }
        }
    }
}

// ============================================================
// MARK: - Safety Screens
// ============================================================

let redFlagQuestions: [(id: String, text: String)] = [
    ("pain",       "Do you have severe pain right now?"),
    ("swelling",   "Do you have new swelling?"),
    ("numbness",   "Do you feel numbness, tingling, or weakness?"),
    ("neck",       "Did you recently sustain a head or neck injury?"),
    ("fever",      "Do you have a fever or feel unwell?"),
    ("locking",    "Does a joint lock, give way, or feel unstable?"),
    ("restricted", "Are you currently restricted from sport by a healthcare provider?"),
    ("dizzy",      "Are you dizzy, faint, confused, or unusually short of breath?"),
]

struct RedFlagCheckScreen: View {
    let module: MRXModule
    let onClear: () -> Void
    @Environment(\.dismiss) var dismiss
    @State private var answers:  [String: Bool] = [:]
    @State private var showRef   = false

    var allAnswered: Bool { answers.count == redFlagQuestions.count }
    var anyYes:      Bool { answers.values.contains(true) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Important Safety Check")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    Text("If you answer YES to any of these, stop and seek medical evaluation before continuing.")
                        .font(.system(size: 14))
                        .foregroundColor(.mrxYellow)
                }

                ForEach(redFlagQuestions, id: \.id) { q in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(q.text)
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .fixedSize(horizontal: false, vertical: true)
                        HStack(spacing: 10) {
                            ForEach(["Yes", "No"], id: \.self) { opt in
                                let isYes = opt == "Yes"
                                let chosen = answers[q.id] == isYes
                                Button {
                                    answers[q.id] = isYes
                                } label: {
                                    Text(opt)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(chosen ? (isYes ? .mrxDanger : .mrxGreen) : .mrxTextMuted)
                                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                                        .background(chosen ? (isYes ? Color.mrxDanger : Color.mrxGreen).opacity(0.18) : Color.mrxCardLight)
                                        .cornerRadius(8)
                                        .overlay(RoundedRectangle(cornerRadius: 8)
                                            .stroke(chosen ? (isYes ? Color.mrxDanger : Color.mrxGreen) : Color.mrxBorder, lineWidth: 1))
                                }
                            }
                        }
                    }
                    .padding(14)
                    .background(Color.mrxCard)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.mrxBorder, lineWidth: 1))
                }

                if anyYes {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.mrxDanger)
                        Text("You've indicated a concern. Please seek evaluation from a qualified healthcare professional before continuing.")
                            .font(.system(size: 13)).foregroundColor(.mrxDanger)
                    }
                    .padding(14)
                    .background(Color.mrxDanger.opacity(0.12))
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.mrxDanger.opacity(0.5), lineWidth: 1))
                }

                Button {
                    showRef = true
                } label: {
                    Text("⚠️  I Need Help")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.mrxDanger)
                        .cornerRadius(12)
                }

                MRXButton(title: allAnswered && !anyYes ? "✓ No, I'm Good to Continue" : "Answer All Questions First") {
                    if allAnswered && !anyYes { onClear() }
                }
                .disabled(!allAnswered || anyYes)

                Text("For emergencies, call 911.")
                    .font(.system(size: 12))
                    .foregroundColor(.mrxTextMuted)
                    .frame(maxWidth: .infinity)

                MRXDisclaimerBox(text: D.core)
            }
            .padding(20)
        }
        .background(Color.mrxBg.ignoresSafeArea())
        .sheet(isPresented: $showRef) { ReferralScreen() }
    }
}

struct ReferralScreen: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                Image(systemName: "heart.text.clipboard.fill")
                    .font(.system(size: 52))
                    .foregroundColor(.mrxDanger)
                    .padding(.top, 40)

                VStack(spacing: 12) {
                    Text("Pause This Module")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                    Text(D.redFlag)
                        .font(.system(size: 14))
                        .foregroundColor(.mrxTextSec)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 12) {
                    MRXButton(title: "Exit Module") { dismiss() }
#if os(iOS)
                    Button("📞 Call Emergency Services — 911") {
                        if let url = URL(string: "tel://911") {
                            UIApplication.shared.open(url)
                        }
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.mrxDanger)
#endif
                }

                MRXDisclaimerBox(text: D.core)
                Spacer()
            }
            .padding(24)
            .background(Color.mrxBg.ignoresSafeArea())
            .navigationTitle("Safety Check")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
#if os(iOS)
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }.foregroundColor(.mrxBlue)
                }
#else
                ToolbarItem(placement: .automatic) {
                    Button("Close") { dismiss() }.foregroundColor(.mrxBlue)
                }
#endif
            }
        }
    }
}

// ============================================================
// MARK: - Exercise Player
// ============================================================

struct ExercisePlayerScreen: View {
    let module: MRXModule
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) var dismiss

    // Session phases
    @State private var sessionStarted = false
    @State private var painBefore: Double = 0

    // Exercise navigation
    @State private var exIdx = 0
    @State private var setNum = 1
    @State private var completedExercises: Set<Int> = []
    @State private var showSafety = true

    // Rest timer
    @State private var isResting = false
    @State private var restSecondsLeft = 60
    @State private var restAdvancesExercise = false
    let restTicker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    // Mid-session pain
    @State private var sessionPainMax: Double = 0
    @State private var showPainCheck = false
    @State private var showHighPainAlert = false

    // Completion
    @State private var showComplete = false

    var exercise: MRXExercise { module.exercises[exIdx] }
    var isLastEx: Bool { exIdx == module.exercises.count - 1 }
    var isLastSet: Bool { setNum == exercise.sets }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.mrxBg.ignoresSafeArea()
                if !sessionStarted {
                    preCheckView
                } else if isResting {
                    restTimerView
                } else {
                    exercisingView
                }
            }
            .navigationTitle(sessionStarted ? module.name : "Pre-Session Check")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
#if os(iOS)
                ToolbarItem(placement: .topBarLeading) {
                    Button("Exit") { dismiss() }.foregroundColor(.mrxTextMuted)
                }
                if sessionStarted && !isResting {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Pain Check") { showPainCheck = true }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.mrxYellow)
                    }
                }
#else
                ToolbarItem(placement: .cancellationAction) {
                    Button("Exit") { dismiss() }.foregroundColor(.mrxTextMuted)
                }
                if sessionStarted && !isResting {
                    ToolbarItem(placement: .automatic) {
                        Button("Pain Check") { showPainCheck = true }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.mrxYellow)
                    }
                }
#endif
            }
        }
#if os(iOS)
        .fullScreenCover(isPresented: $showComplete, onDismiss: { dismiss() }) {
            SessionCompleteScreen(module: module, painBefore: painBefore, sessionPainMax: sessionPainMax)
        }
#else
        .sheet(isPresented: $showComplete, onDismiss: { dismiss() }) {
            SessionCompleteScreen(module: module, painBefore: painBefore, sessionPainMax: sessionPainMax)
        }
#endif
        .sheet(isPresented: $showPainCheck) {
            MidSessionPainSheet(moduleColor: module.color) { pain in
                sessionPainMax = max(sessionPainMax, pain)
                if pain - painBefore >= 2 {
                    showHighPainAlert = true
                }
            }
        }
        .alert("High Pain Detected", isPresented: $showHighPainAlert) {
            Button("Stop Session", role: .destructive) { dismiss() }
            Button("Continue Carefully", role: .cancel) { }
        } message: {
            Text("Your pain has increased by 2 or more points. Consider stopping and consulting a healthcare professional.")
        }
        .onReceive(restTicker) { _ in
            guard isResting, restSecondsLeft > 0 else { return }
            restSecondsLeft -= 1
            if restSecondsLeft == 0 { endRest() }
        }
    }

    // MARK: Pre-check Phase

    var preCheckView: some View {
        ScrollView {
            VStack(spacing: 28) {
                VStack(spacing: 10) {
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 44))
                        .foregroundColor(module.color)
                    Text("Before We Begin")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    Text("Rate your current pain level so we can track how this session affects you.")
                        .font(.system(size: 14))
                        .foregroundColor(.mrxTextSec)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Current Pain Level")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                        Spacer()
                        Text("\(Int(painBefore))/10")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(painColor(painBefore))
                    }
                    Slider(value: $painBefore, in: 0...10, step: 1)
                        .accentColor(painColor(painBefore))
                    HStack {
                        Text("No pain").font(.system(size: 11)).foregroundColor(.mrxTextMuted)
                        Spacer()
                        Text("Severe").font(.system(size: 11)).foregroundColor(.mrxTextMuted)
                    }
                }
                .padding(18)
                .background(Color.mrxCard)
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.mrxBorder, lineWidth: 1))

                if painBefore >= 7 {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.mrxDanger)
                        Text("Pain at 7 or higher — consider speaking with a healthcare provider before this session.")
                            .font(.system(size: 13)).foregroundColor(.mrxDanger)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(14)
                    .background(Color.mrxDanger.opacity(0.12))
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.mrxDanger.opacity(0.5), lineWidth: 1))
                }

                MRXButton(title: "Begin Session →", color: module.color) {
                    sessionPainMax = painBefore
                    sessionStarted = true
                }

                MRXDisclaimerBox(text: D.short, compact: true)
            }
            .padding(20)
        }
    }

    // MARK: Rest Timer Phase

    var restTimerView: some View {
        VStack(spacing: 32) {
            Spacer()
            Text(restAdvancesExercise ? "Exercise Complete!" : "Set Complete!")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
            Text("Rest between sets")
                .font(.system(size: 15))
                .foregroundColor(.mrxTextSec)

            ZStack {
                Circle()
                    .stroke(Color.mrxCard, lineWidth: 12)
                Circle()
                    .trim(from: 0, to: CGFloat(restSecondsLeft) / 60.0)
                    .stroke(module.color, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: restSecondsLeft)
                VStack(spacing: 4) {
                    Text("\(restSecondsLeft)")
                        .font(.system(size: 52, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    Text("seconds")
                        .font(.system(size: 14))
                        .foregroundColor(.mrxTextSec)
                }
            }
            .frame(width: 200, height: 200)

            Button("Skip Rest →") { endRest() }
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(module.color)
                .padding(.horizontal, 32).padding(.vertical, 14)
                .background(module.color.opacity(0.12))
                .cornerRadius(12)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Exercising Phase

    var exercisingView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                // Progress dots — one per exercise
                HStack(spacing: 6) {
                    ForEach(0..<module.exercises.count, id: \.self) { i in
                        ZStack {
                            Circle()
                                .fill(
                                    completedExercises.contains(i) ? module.color :
                                    i == exIdx ? module.color.opacity(0.5) : Color.mrxCard
                                )
                                .frame(width: i == exIdx ? 10 : 8, height: i == exIdx ? 10 : 8)
                            if completedExercises.contains(i) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 5, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    Spacer()
                    Text("\(exIdx + 1) of \(module.exercises.count)")
                        .font(.system(size: 12))
                        .foregroundColor(.mrxTextMuted)
                }

                Text(exercise.name)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)

                ZStack {
                    RoundedRectangle(cornerRadius: 16).fill(Color.mrxCard)
                    VStack(spacing: 8) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 52))
                            .foregroundColor(module.color)
                        Text("Video Demonstration")
                            .font(.system(size: 13))
                            .foregroundColor(.mrxTextMuted)
                        Text("(Add Mux URL to exercise data)")
                            .font(.system(size: 11))
                            .foregroundColor(.mrxTextMuted)
                    }
                }
                .frame(height: 200)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.mrxBorder, lineWidth: 1))

                HStack(spacing: 10) {
                    InfoPill(label: "Set",  val: "\(setNum) of \(exercise.sets)")
                    InfoPill(label: "Reps", val: exercise.reps)
                }

                if showSafety {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.mrxYellow)
                        Text(exercise.safetyWarning)
                            .font(.system(size: 13)).foregroundColor(.mrxYellow)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer()
                        Button { showSafety = false } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 12)).foregroundColor(.mrxTextMuted)
                        }
                    }
                    .padding(12)
                    .background(Color.mrxYellow.opacity(0.10))
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.mrxYellow.opacity(0.4), lineWidth: 1))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("COACHING CUES")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.mrxTextMuted).kerning(0.8)
                    ForEach(exercise.cues, id: \.self) { cue in
                        HStack(alignment: .top, spacing: 8) {
                            Text("•").foregroundColor(module.color)
                            Text(cue).font(.system(size: 14)).foregroundColor(.white)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(14)
                .background(Color.mrxCard)
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.mrxBorder, lineWidth: 1))

                HStack(spacing: 10) {
                    Button {
                        if exIdx > 0 { exIdx -= 1; setNum = 1; showSafety = true }
                    } label: {
                        Text("← Prev")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(exIdx > 0 ? .mrxTextSec : .mrxTextMuted)
                            .padding(.vertical, 14).padding(.horizontal, 18)
                            .background(Color.mrxCard)
                            .cornerRadius(12)
                    }
                    .disabled(exIdx == 0)

                    Button { advanceSet() } label: {
                        Text(isLastSet && isLastEx ? "Finish Session →" : "Complete Set \(setNum) →")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(module.color)
                            .cornerRadius(12)
                    }
                }

                HStack {
                    Button("Skip Exercise") {
                        if !isLastEx { exIdx += 1; setNum = 1; showSafety = true } else { finishSession() }
                    }
                    .font(.system(size: 13)).foregroundColor(.mrxTextMuted)
                    Spacer()
                }

                Text(D.short)
                    .font(.system(size: 11)).foregroundColor(.mrxTextMuted)
                    .frame(maxWidth: .infinity)
            }
            .padding(20)
        }
    }

    // MARK: Helpers

    func advanceSet() {
        if isLastSet && isLastEx {
            completedExercises.insert(exIdx)
            finishSession()
        } else if isLastSet {
            completedExercises.insert(exIdx)
            restAdvancesExercise = true
            startRest()
        } else {
            restAdvancesExercise = false
            startRest()
        }
    }

    func startRest() { restSecondsLeft = 60; isResting = true }

    func endRest() {
        isResting = false
        if restAdvancesExercise { exIdx += 1; setNum = 1; showSafety = true }
        else { setNum += 1 }
    }

    func finishSession() { showComplete = true }

    func painColor(_ v: Double) -> Color {
        v <= 3 ? .mrxGreen : v <= 6 ? .mrxYellow : .mrxDanger
    }
}

struct InfoPill: View {
    let label: String
    let val:   String
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.mrxTextMuted).kerning(0.5)
            Text(val)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.mrxCard)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.mrxBorder, lineWidth: 1))
    }
}

// ============================================================
// MARK: - Mid-Session Pain Sheet
// ============================================================

struct MidSessionPainSheet: View {
    let moduleColor: Color
    let onSave: (Double) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var pain: Double = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                VStack(spacing: 8) {
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 36))
                        .foregroundColor(moduleColor)
                    Text("Mid-Session Pain Check")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                    Text("Rate your pain right now.")
                        .font(.system(size: 14))
                        .foregroundColor(.mrxTextSec)
                }
                .padding(.top, 20)

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Current Pain")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                        Spacer()
                        Text("\(Int(pain))/10")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(pain <= 3 ? .mrxGreen : pain <= 6 ? .mrxYellow : .mrxDanger)
                    }
                    Slider(value: $pain, in: 0...10, step: 1)
                        .accentColor(pain <= 3 ? .mrxGreen : pain <= 6 ? .mrxYellow : .mrxDanger)
                }
                .padding(18)
                .background(Color.mrxCard)
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.mrxBorder, lineWidth: 1))

                MRXButton(title: "Save & Continue", color: moduleColor) {
                    onSave(pain)
                    dismiss()
                }

                Spacer()
            }
            .padding(20)
            .background(Color.mrxBg.ignoresSafeArea())
            .navigationTitle("")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
#if os(iOS)
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }.foregroundColor(.mrxBlue)
                }
#else
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundColor(.mrxBlue)
                }
#endif
            }
        }
    }
}

// ============================================================
// MARK: - Session Complete Screen
// ============================================================

struct SessionCompleteScreen: View {
    let module: MRXModule
    var painBefore: Double = 0
    var sessionPainMax: Double = 0
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) var dismiss
    @State private var painAfter: Double = 0
    @State private var felt: FeltResponse? = nil
    @State private var saving = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text("🏆").font(.system(size: 52))
                        Text("Great work!")
                            .font(.system(size: 32, weight: .bold)).foregroundColor(.white)
                        Text(module.name + " completed.")
                            .foregroundColor(.mrxTextSec)
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        Text("PAIN LOG")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.mrxTextMuted).kerning(0.8)

                        // Before — pre-filled from session start, read-only
                        HStack {
                            Text("Before session")
                                .font(.system(size: 14)).foregroundColor(.mrxTextSec)
                            Spacer()
                            Text("\(Int(painBefore))/10")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(painBefore <= 3 ? .mrxGreen : painBefore <= 6 ? .mrxYellow : .mrxDanger)
                        }

                        if sessionPainMax > painBefore {
                            Divider().background(Color.mrxDivider)
                            HStack {
                                Text("Peak during session")
                                    .font(.system(size: 14)).foregroundColor(.mrxTextSec)
                                Spacer()
                                Text("\(Int(sessionPainMax))/10")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(sessionPainMax <= 3 ? .mrxGreen : sessionPainMax <= 6 ? .mrxYellow : .mrxDanger)
                            }
                        }

                        Divider().background(Color.mrxDivider)

                        // After — editable slider
                        VStack(spacing: 4) {
                            HStack {
                                Text("Pain after session")
                                    .font(.system(size: 14)).foregroundColor(.mrxTextSec)
                                Spacer()
                                Text("\(Int(painAfter))/10")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(painAfter <= 3 ? .mrxGreen : painAfter <= 6 ? .mrxYellow : .mrxDanger)
                            }
                            Slider(value: $painAfter, in: 0...10, step: 1)
                                .accentColor(painAfter <= 3 ? .mrxGreen : painAfter <= 6 ? .mrxYellow : .mrxDanger)
                        }
                    }
                    .padding(16)
                    .background(Color.mrxCard)
                    .cornerRadius(14)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.mrxBorder, lineWidth: 1))

                    VStack(alignment: .leading, spacing: 12) {
                        Text("How do you feel?")
                            .font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                        HStack(spacing: 10) {
                            ForEach(FeltResponse.allCases, id: \.self) { opt in
                                let c: Color = opt == .better ? .mrxGreen : opt == .same ? .mrxYellow : .mrxDanger
                                let chosen = felt == opt
                                let emoji = opt == .better ? "✅" : opt == .same ? "➡️" : "⚠️"
                                Button { felt = opt } label: {
                                    VStack(spacing: 4) {
                                        Text(emoji).font(.system(size: 20))
                                        Text(opt.rawValue)
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(chosen ? c : .mrxTextMuted)
                                    }
                                    .frame(maxWidth: .infinity).padding(.vertical, 12)
                                    .background(chosen ? c.opacity(0.18) : Color.mrxCard)
                                    .cornerRadius(10)
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(chosen ? c : Color.mrxBorder, lineWidth: 1.5))
                                }
                            }
                        }
                    }

                    if felt == .worse || painAfter > painBefore {
                        HStack(spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.mrxYellow)
                            Text("If pain or symptoms worsen tomorrow, seek evaluation from a qualified healthcare professional.")
                                .font(.system(size: 13)).foregroundColor(.mrxYellow)
                        }
                        .padding(14)
                        .background(Color.mrxYellow.opacity(0.12))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.mrxYellow.opacity(0.4), lineWidth: 1))
                    }

                    Button(action: {
                        guard felt != nil else { return }
                        saving = true
                        let currentUserId = app.userId
                        let currentModuleName = module.name
                        let currentPain = painAfter
                        let currentAppState = app
                        MRXProgressTracker.shared.addSessionEntry(
                            userId: currentUserId,
                            moduleName: currentModuleName,
                            pain: currentPain,
                            appState: currentAppState
                        )
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            dismiss()
                        }
                    }) {
                        Text(saving ? "Saving..." : "Back to Home")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.mrxBlue)
                            .cornerRadius(14)
                    }
                    .disabled(felt == nil || saving)

                    MRXDisclaimerBox(text: D.core)
                }
                .padding(20)
            }
            .background(Color.mrxBg.ignoresSafeArea())
            .navigationTitle("Session Complete")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
#if os(iOS)
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close All") { dismiss() }
                        .foregroundColor(.mrxBlue)
                }
#else
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close All") { dismiss() }
                        .foregroundColor(.mrxBlue)
                }
#endif
            }
        }
    }
}


