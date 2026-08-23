//
//  OnboardingViews.swift
//  MatReturnRx
//

import SwiftUI

// ============================================================
// MARK: - Disclaimer Text Constants
// ============================================================

enum OnboardingConstants {
    static let parentConsent = """
I hereby provide consent for the athlete named in this application to use MatReturnRx. I understand that this app provides exercise and training guidance, and that I should consult with a healthcare professional before beginning any exercise program. I acknowledge that I have read and agree to the Terms of Service and Privacy Policy on behalf of the minor athlete.
"""
}

// ============================================================
// MARK: - Onboarding Flow
// ============================================================

enum OnboardStep { case ageGate, parentConsent, legal, profile, goals }

struct OnboardingFlow: View {
    @EnvironmentObject private var app: AppState
    @State private var step: OnboardStep = .ageGate
    @State private var isMinor           = false
    @State private var firstName         = ""
    @State private var sport             = "Wrestling"

    var body: some View {
        ZStack {
            Color.mrxBg.ignoresSafeArea()
            switch step {
            case .ageGate:
                AgeGateScreen(onAdult: { step = .legal }, onMinor: { isMinor = true; step = .parentConsent })
            case .parentConsent:
                ParentConsentScreen(onNext: { step = .legal })
            case .legal:
                LegalAcceptanceScreen(
                    isMinor:  isMinor,
                    userId:   app.userName,
                    onAccept: { step = .profile }
                )
            case .profile:
                AthleteProfileScreen(firstName: $firstName, sport: $sport, onNext: { step = .goals })
            case .goals:
                GoalsScreen(firstName: firstName, sport: sport)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: step)
    }
}

struct AgeGateScreen: View {
    let onAdult: () -> Void
    let onMinor: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            Text("Are you 18\nor older?")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            Text("We tailor your app experience based on your age.")
                .foregroundColor(.mrxTextSec)
                .multilineTextAlignment(.center)
            VStack(spacing: 14) {
                MRXButton(title: "Yes, I am 18 or older",  action: onAdult)
                MRXButton(title: "No, I am under 18",      style: .outline, action: onMinor)
            }
            Text("Youth athletes under 18 require parent or guardian consent.")
                .font(.system(size: 12))
                .foregroundColor(.mrxTextMuted)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(28)
    }
}

struct ParentConsentScreen: View {
    let onNext: () -> Void
    @State private var parentName     = ""
    @State private var parentEmail    = ""
    @State private var relationship   = ""
    @State private var consentChecked = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Parent / Guardian Consent")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                    Text("Since this athlete is under 18, a parent or guardian must provide consent before using MatReturnRx.")
                        .foregroundColor(.mrxTextSec)
                        .font(.system(size: 14))
                }
                VStack(spacing: 12) {
                    MRXField(label: "Parent/guardian full name", text: $parentName,   type: .name)
                    MRXField(label: "Parent/guardian email",     text: $parentEmail,  type: .email)
                    MRXField(label: "Relationship to athlete",   text: $relationship, type: .name)
                }
                Toggle(isOn: $consentChecked) {
                    Text(OnboardingConstants.parentConsent)
                        .font(.system(size: 13))
                        .foregroundColor(.mrxTextSec)
                }
                .toggleStyle(CheckToggleStyle())

                MRXButton(title: "I Provide Consent — Continue") {
                    if consentChecked { onNext() }
                }
                .disabled(!consentChecked)
            }
            .padding(24)
        }
        .background(Color.mrxBg.ignoresSafeArea())
    }
}

struct AthleteProfileScreen: View {
    @Binding var firstName: String
    @Binding var sport: String
    let onNext: () -> Void

    @State private var dob               = ""
    @State private var experienceLevel   = "High School"
    @State private var trainingPhase     = "In-Season"

    let sports      = ["Wrestling", "BJJ", "MMA", "Judo", "Grappling", "Other"]
    let levels      = ["Youth", "High School", "College", "Adult Recreational", "Competitive Adult"]
    let phases      = ["Off-Season", "Pre-Season", "In-Season", "Tournament Week", "Recovery Week", "Return to Training"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Tell Us About You")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)

                VStack(spacing: 12) {
                    MRXField(label: "First name", text: $firstName, type: .name)

                    MRXPickerRow(label: "Primary Sport",     selection: $sport,          options: sports)
                    MRXPickerRow(label: "Experience Level",  selection: $experienceLevel, options: levels)
                    MRXPickerRow(label: "Training Phase",    selection: $trainingPhase,   options: phases)
                }

                MRXButton(title: "Continue →", action: onNext)
                    .disabled(firstName.isEmpty)
            }
            .padding(24)
        }
        .background(Color.mrxBg.ignoresSafeArea())
    }
}

struct GoalsScreen: View {
    @EnvironmentObject var app: AppState
    let firstName: String
    let sport: String

    @State private var selected: Set<String> = []

    let goals = [
        "Injury prevention", "Improve mobility", "Get stronger",
        "Return from injury", "Compete longer", "Improve recovery",
        "Improve readiness", "Improve knee stability",
        "Improve neck strength / control", "Improve shoulder stability", "Track consistency"
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("What are your goals?")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    Text("Select all that apply.")
                        .foregroundColor(.mrxTextSec)
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(goals, id: \.self) { goal in
                        let on = selected.contains(goal)
                        Button {
                            if on { selected.remove(goal) } else { selected.insert(goal) }
                        } label: {
                            Text(goal)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(on ? .white : .mrxTextSec)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 8)
                                .background(on ? Color.mrxBlue : Color.mrxCard)
                                .cornerRadius(10)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(on ? Color.mrxBlue : Color.mrxBorder, lineWidth: 1))
                        }
                    }
                }

                MRXButton(title: "Start MatReturnRx →") {
                    app.finishOnboarding(first: firstName, sp: sport)
                }
                .disabled(selected.isEmpty)
            }
            .padding(24)
        }
        .background(Color.mrxBg.ignoresSafeArea())
    }
}
