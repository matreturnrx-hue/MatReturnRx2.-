//
//  ProfileViews.swift
//  MatReturnRx
//

// NOTE: iOS-only navigation and toolbar APIs are guarded by #if os(iOS)

import SwiftUI
import StoreKit

// ============================================================
// MARK: - Profile Tab
// ============================================================

struct ProfileTab: View {
    @EnvironmentObject var app: AppState
    @State private var showPaywall  = false
    @State private var showPrivacy  = false
    @State private var showIncident = false
    @State private var showLegal    = false
    @State private var showHelp     = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle().fill(Color.mrxBlueMuted).frame(width: 64, height: 64)
                            Text(String((app.athleteFirst.first ?? "A").uppercased()))
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(.mrxBlue)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(app.athleteFirst.isEmpty ? app.userName : app.athleteFirst)
                                .font(.system(size: 20, weight: .bold)).foregroundColor(.white)
                            Text(app.sport + " Athlete")
                                .font(.system(size: 13)).foregroundColor(.mrxTextMuted)
                            Text(app.isPro ? "⭐ Pro Member" : "Free Plan")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(app.isPro ? Color(red:1,green:0.84,blue:0) : .mrxTextMuted)
                        }
                        Spacer()
                    }

                    HStack(spacing: 10) {
                        StatCard(num: String(format: "%.1f", app.latestResult?.score ?? 0), label: "Readiness",
                                 color: app.latestResult?.status.color ?? .mrxTextMuted)
                        StatCard(num: "\(app.streak)🔥", label: "Streak")
                        StatCard(num: "\(app.weekSessions)", label: "Sessions")
                    }

                    VStack(spacing: 0) {
                        ProfileMenuRow(icon: "star.fill",           label: "Go Pro",            color: Color(red:1,green:0.84,blue:0)) { showPaywall = true }
                        ProfileMenuRow(icon: "lock.shield.fill",    label: "Privacy Center",    color: .mrxBlue)  { showPrivacy  = true }
                        ProfileMenuRow(icon: "exclamationmark.bubble.fill", label: "Report an Issue", color: .mrxYellow) { showIncident = true }
                        ProfileMenuRow(icon: "doc.text.fill",       label: "Legal Documents",   color: .mrxTextMuted) { showLegal = true }
                        ProfileMenuRow(icon: "questionmark.circle.fill", label: "Help & Support", color: .mrxTextMuted) { showHelp = true }
                        ProfileMenuRow(icon: "rectangle.portrait.and.arrow.right", label: "Sign Out", color: .mrxDanger, last: true) {
                            Task { await AuthManager.shared.signOut(appState: app) }
                        }
                    }
                    .background(Color.mrxCard)
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.mrxBorder, lineWidth: 1))

                    Text("MatReturnRx MVP 1.0 · MatReturnRx, LLC · Juan Ivan Sanchez Aguirre & Itzel Aranza Torres")
                        .font(.system(size: 11))
                        .foregroundColor(.mrxTextMuted)
                        .multilineTextAlignment(.center)
                }
                .padding(20)
            }
            .background(Color.mrxBg.ignoresSafeArea())
#if os(iOS)
            .navigationBarHidden(true)
#endif
        }
        .sheet(isPresented: $showPaywall)  { PaywallScreen() }
        .sheet(isPresented: $showPrivacy)  { PrivacyCenterScreen() }
        .sheet(isPresented: $showIncident) { IncidentReportScreen() }
        .sheet(isPresented: $showLegal)    { LegalStatusView(userId: app.userName, isMinor: app.isMinor) }
        .sheet(isPresented: $showHelp)     { HelpSupportScreen() }
    }
}

struct ProfileMenuRow: View {
    let icon: String
    let label: String
    let color: Color
    var last = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
                    .frame(width: 28)
                Text(label)
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13))
                    .foregroundColor(.mrxTextMuted)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.clear)
        }
        if !last {
            Divider().background(Color.mrxDivider).padding(.leading, 58)
        }
    }
}

// ============================================================
// MARK: - Paywall Screen  (alias → ProUpgradeScreen)
// ============================================================

typealias PaywallScreen = ProUpgradeScreen

// ============================================================
// MARK: - Pro Upgrade Screen
// ============================================================

struct ProUpgradeScreen: View {
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) var dismiss
    @StateObject private var sub = SubscriptionManager.shared

    // 0 = 12-month (default / best value), 1 = 6-month
    @State private var selectedPlan = 0
    @State private var showRestoreAlert = false
    @State private var showPurchaseError = false

    // Returns the real App Store price when loaded, otherwise the fallback string.
    func price(for productID: String, fallback: String) -> String {
        sub.products.first(where: { $0.id == productID })?.displayPrice ?? fallback
    }
    private var price12: String { price(for: SubscriptionManager.productID12Month, fallback: "$10.99") }
    private var price6:  String { price(for: SubscriptionManager.productID6Month,  fallback: "$14.99") }

    private let basicFeatures: [(String, Bool)] = [
        ("Mobility & Recovery module",             true),
        ("Knee, Neck & Shoulder Starter programs", true),
        ("Hip & Groin Injury Prevention",          true),
        ("Lower Back Injury Prevention",           true),
        ("Readiness check & pain tracking",        true),
        ("AI Coach (limited questions/day)",       true),
        ("Personalized programs built for you",    false),
        ("Grappling Performance module",           false),
        ("Return to Mat Protocol",                 false),
    ]

    private let proFeatures: [String] = [
        "Personalized programs built for YOUR body & history",
        "Grappling Strength Foundation module",
        "Return to Mat Protocol",
        "Full AI Coach — unlimited access",
        "Sport-phase & injury-specific progressions",
        "All future Pro modules included",
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
                    VStack(spacing: 28) {

                        // Hero
                        VStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(AppTheme.fightRed.opacity(0.15))
                                    .frame(width: 72, height: 72)
                                Image(systemName: "sparkles")
                                    .font(.system(size: 30))
                                    .foregroundColor(AppTheme.fightRed)
                            }
                            Text("Upgrade to Pro")
                                .font(.system(size: 34, weight: .black))
                                .foregroundColor(.white)
                            Text("Go beyond standardized programs. Get training built specifically for your body, your injury, and your return timeline.")
                                .font(.system(size: 15))
                                .foregroundColor(.mrxTextSec)
                                .multilineTextAlignment(.center)
                                .lineSpacing(3)
                        }
                        .padding(.top, 8)

                        // Basic vs Pro comparison
                        VStack(spacing: 12) {
                            // Basic (free) section
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("FREE BASIC PLAN")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.mrxTextMuted)
                                        .kerning(0.8)
                                    Spacer()
                                    Text("Current Plan")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.mrxTextMuted)
                                        .padding(.horizontal, 8).padding(.vertical, 3)
                                        .background(Color.white.opacity(0.08))
                                        .cornerRadius(6)
                                }
                                ForEach(basicFeatures, id: \.0) { label, included in
                                    HStack(spacing: 10) {
                                        Image(systemName: included ? "checkmark.circle.fill" : "xmark.circle.fill")
                                            .foregroundColor(included ? .mrxGreen : Color.white.opacity(0.2))
                                            .font(.system(size: 14))
                                        Text(label)
                                            .font(.system(size: 13))
                                            .foregroundColor(included ? .white : .mrxTextMuted)
                                    }
                                }
                            }
                            .padding(16)
                            .background(Color.mrxCard)
                            .cornerRadius(14)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.mrxBorder, lineWidth: 1))

                            // Pro section
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("PRO MEMBERSHIP")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(AppTheme.fightRed)
                                        .kerning(0.8)
                                    Spacer()
                                    HStack(spacing: 4) {
                                        Image(systemName: "person.crop.circle.badge.checkmark")
                                            .font(.system(size: 10))
                                        Text("Personalized")
                                            .font(.system(size: 11, weight: .semibold))
                                    }
                                    .foregroundColor(AppTheme.electricOrange)
                                    .padding(.horizontal, 8).padding(.vertical, 3)
                                    .background(AppTheme.electricOrange.opacity(0.12))
                                    .cornerRadius(6)
                                }
                                ForEach(proFeatures, id: \.self) { label in
                                    HStack(spacing: 10) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(AppTheme.recoveryTeal)
                                            .font(.system(size: 14))
                                        Text(label)
                                            .font(.system(size: 13))
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            .padding(16)
                            .background(AppTheme.fightRed.opacity(0.07))
                            .cornerRadius(14)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.fightRed.opacity(0.35), lineWidth: 1.5))
                        }

                        // Plan selection
                        VStack(spacing: 10) {
                            Text("CHOOSE YOUR PLAN")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.mrxTextMuted)
                                .kerning(0.8)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            // 12-Month — recommended
                            planCard(
                                idx:      0,
                                title:    "12-Month Pro Plan",
                                price:    price12,
                                period:   "per month · billed annually",
                                badge:    "Best Value",
                                saving:   "Save $48/yr vs monthly"
                            )

                            // 6-Month
                            planCard(
                                idx:      1,
                                title:    "6-Month Pro Plan",
                                price:    price6,
                                period:   "per month · billed every 6 months",
                                badge:    nil,
                                saving:   nil
                            )
                        }

                        // CTAs
                        VStack(spacing: 10) {
                            if sub.isPurchasing {
                                HStack(spacing: 12) {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    Text("Processing…")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(AppTheme.fightRed.opacity(0.6))
                                .cornerRadius(14)
                            } else {
                                Button {
                                    if selectedPlan == 0 {
                                        sub.purchase12Month(appState: app)
                                    } else {
                                        sub.purchase6Month(appState: app)
                                    }
                                } label: {
                                    Text(selectedPlan == 0
                                         ? "Start 12-Month Plan — \(price12)/month"
                                         : "Start 6-Month Plan — \(price6)/month")
                                        .font(.system(size: 17, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 18)
                                        .background(AppTheme.fightRed)
                                        .cornerRadius(14)
                                }

                                // Secondary plan shortcut
                                Button {
                                    selectedPlan = selectedPlan == 0 ? 1 : 0
                                } label: {
                                    Text(selectedPlan == 0
                                         ? "Or choose 6-Month — \(price6)/month"
                                         : "Or choose 12-Month — \(price12)/month (Best Value)")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.mrxTextSec)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(Color.mrxCard)
                                        .cornerRadius(14)
                                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.mrxBorder, lineWidth: 1))
                                }
                            }
                        }

                        // Restore + legal
                        VStack(spacing: 14) {
                            Button {
                                sub.restoreMessage = nil
                                sub.restorePurchases(appState: app)
                            } label: {
                                Text("Restore Purchases")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(AppTheme.recoveryTeal)
                            }

                            HStack(spacing: 20) {
                                Button("Terms of Service") {}
                                    .font(.system(size: 12)).foregroundColor(.mrxTextMuted)
                                Button("Privacy Policy") {}
                                    .font(.system(size: 12)).foregroundColor(.mrxTextMuted)
                            }

                            Text("Cancel anytime. " + D.subLegal)
                                .font(.system(size: 11))
                                .foregroundColor(Color.white.opacity(0.3))
                                .multilineTextAlignment(.center)
                                .lineSpacing(2)
                        }
                        .padding(.bottom, 16)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                }
            }
#if os(iOS)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundColor(.mrxTextMuted)
                }
            }
#endif
        }
        .alert("Restore Purchases", isPresented: $showRestoreAlert) {
            Button("OK", role: .cancel) { sub.restoreMessage = nil }
        } message: {
            Text(sub.restoreMessage ?? "")
        }
        .alert("Purchase Error", isPresented: $showPurchaseError) {
            Button("OK", role: .cancel) { sub.purchaseError = nil }
        } message: {
            Text(sub.purchaseError ?? "")
        }
        .onChange(of: app.isPro) { _, newValue in
            if newValue { dismiss() }
        }
        .onChange(of: sub.restoreMessage) { _, msg in
            if msg != nil { showRestoreAlert = true }
        }
        .onChange(of: sub.purchaseError) { _, err in
            if err != nil { showPurchaseError = true }
        }
        .onAppear {
            if sub.products.isEmpty {
                Task { await sub.loadProducts() }
            }
        }
    }

    @ViewBuilder
    func planCard(idx: Int, title: String, price: String, period: String,
                          badge: String?, saving: String?) -> some View {
        let selected = selectedPlan == idx
        Button { selectedPlan = idx } label: {
            ZStack(alignment: .topTrailing) {
                HStack(alignment: .center, spacing: 16) {
                    // Selection indicator
                    ZStack {
                        Circle()
                            .stroke(selected ? AppTheme.fightRed : Color.mrxBorder, lineWidth: 2)
                            .frame(width: 22, height: 22)
                        if selected {
                            Circle()
                                .fill(AppTheme.fightRed)
                                .frame(width: 12, height: 12)
                        }
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        Text(period)
                            .font(.system(size: 11))
                            .foregroundColor(.mrxTextMuted)
                        if let s = saving {
                            Text(s)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(AppTheme.recoveryTeal)
                        }
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 0) {
                        Text(price)
                            .font(.system(size: 22, weight: .black))
                            .foregroundColor(selected ? .white : .mrxTextSec)
                        Text("/mo")
                            .font(.system(size: 11))
                            .foregroundColor(.mrxTextMuted)
                    }
                }
                .padding(16)
                .background(selected ? AppTheme.fightRed.opacity(0.10) : Color.mrxCard)
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(selected ? AppTheme.fightRed : Color.mrxBorder,
                                lineWidth: selected ? 2 : 1)
                )

                if let b = badge {
                    Text(b)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(AppTheme.electricOrange)
                        .cornerRadius(8)
                        .offset(x: -12, y: -10)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// ============================================================
// MARK: - Privacy Center Screen
// ============================================================

struct PrivacyCenterScreen: View {
    @Environment(\.dismiss) var dismiss
    @State private var showExportAlert  = false
    @State private var showDeleteAlert  = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Your health and performance data belongs to you. Manage it here.")
                        .font(.system(size: 14)).foregroundColor(.mrxTextSec)

                    MRXDisclaimerBox(text: "Your health and performance data is private. MatReturnRx only shares data with coaches or parents when you explicitly grant permission.")

                    VStack(spacing: 0) {
                        PrivacyRow(icon: "eye.fill",         label: "View Data Collected",
                                   desc: "See what information MatReturnRx has stored about you.")   {}
                        PrivacyRow(icon: "arrow.down.doc.fill", label: "Download My Data",
                                   desc: "Request a full export of your personal data.")              { showExportAlert = true }
                        PrivacyRow(icon: "person.2.fill",    label: "Manage Coach/Team Sharing",
                                   desc: "Control what information your coach can see.")              {}
                        PrivacyRow(icon: "figure.2",         label: "Manage Parent Access",
                                   desc: "Control parent access to your readiness and session data.") {}
                        PrivacyRow(icon: "envelope.fill",    label: "Contact Privacy Support",
                                   desc: "Email our privacy team: privacy@matreturnrx.com")          {}
                        PrivacyRow(icon: "trash.fill",       label: "Delete My Account",
                                   desc: "Permanently delete your account and personal data.",
                                   color: .mrxDanger, last: true)                                    { showDeleteAlert = true }
                    }
                    .background(Color.mrxCard)
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.mrxBorder, lineWidth: 1))
                }
                .padding(20)
            }
            .background(Color.mrxBg.ignoresSafeArea())
#if os(iOS)
            .navigationTitle("Privacy Center")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.foregroundColor(.mrxBlue)
                }
            }
#endif
            .alert("Data Export Requested", isPresented: $showExportAlert) {
                Button("OK") {}
            } message: {
                Text("Your data export request has been submitted. You will receive an email within 30 days.")
            }
            .alert("Delete Account", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Request Deletion", role: .destructive) {}
            } message: {
                Text("This will permanently delete your account and associated data. Safety and legal records may be retained as required by law.")
            }
        }
    }
}

struct PrivacyRow: View {
    let icon:   String
    let label:  String
    let desc:   String
    var color: Color = .mrxBlue
    var last = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 18)).foregroundColor(color).frame(width: 28)
                VStack(alignment: .leading, spacing: 3) {
                    Text(label).font(.system(size: 15)).foregroundColor(.white)
                    Text(desc).font(.system(size: 12)).foregroundColor(.mrxTextMuted)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13)).foregroundColor(.mrxTextMuted)
            }
            .padding(.horizontal, 16).padding(.vertical, 14)
        }
        if !last {
            Divider().background(Color.mrxDivider).padding(.leading, 58)
        }
    }
}

// ============================================================
// MARK: - Incident Report Screen
// ============================================================

struct IncidentReportScreen: View {
    @Environment(\.dismiss) var dismiss
    @State private var type         = "Pain spike"
    @State private var description  = ""
    @State private var location     = ""
    @State private var painLevel: Double = 0
    @State private var soughtHelp   = false
    @State private var submitted    = false

    let types = ["Pain spike", "Injury", "Equipment issue", "App issue", "Safety concern", "Other"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Let us know what happened.")
                        .font(.system(size: 14)).foregroundColor(.mrxTextSec)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Type of issue")
                            .font(.system(size: 13, weight: .semibold)).foregroundColor(.mrxTextSec)
                        Picker("Type", selection: $type) {
                            ForEach(types, id: \.self) { Text($0).tag($0) }
                        }
                        .pickerStyle(.menu)
                        .accentColor(.mrxBlue)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(Color.mrxCard)
                        .cornerRadius(10)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.system(size: 13, weight: .semibold)).foregroundColor(.mrxTextSec)
                        TextEditor(text: $description)
                            .frame(minHeight: 100)
                            .padding(10)
                            .background(Color.mrxCard)
                            .cornerRadius(10)
                            .foregroundColor(.white)
                            .font(.system(size: 14))
                    }

                    MRXField(label: "Where did it happen?", text: $location, type: .name)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Pain level: \(Int(painLevel))/10")
                            .font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                        Slider(value: $painLevel, in: 0...10, step: 1).accentColor(.mrxDanger)
                    }
                    .padding(14)
                    .background(Color.mrxCard)
                    .cornerRadius(12)

                    Toggle(isOn: $soughtHelp) {
                        Text("I have sought or plan to seek medical help")
                            .font(.system(size: 14)).foregroundColor(.mrxTextSec)
                    }
                    .toggleStyle(CheckToggleStyle())

                    MRXButton(title: "Submit Report") {
                        submitted = true
                    }

                    HStack {
                        Image(systemName: "phone.fill").foregroundColor(.mrxDanger)
                        Text("For emergencies, call 911.")
                            .font(.system(size: 13, weight: .semibold)).foregroundColor(.mrxDanger)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(20)
            }
            .background(Color.mrxBg.ignoresSafeArea())
#if os(iOS)
            .navigationTitle("Report an Issue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }.foregroundColor(.mrxBlue)
                }
            }
#endif
            .alert("Report Submitted", isPresented: $submitted) {
                Button("OK") { dismiss() }
            } message: {
                Text("Your report has been submitted and will be reviewed by the MatReturnRx team.")
            }
        }
    }
}
struct HelpSupportScreen: View {
    @Environment(\.dismiss) var dismiss
    @State private var faqExpanded: Int? = nil

    struct FAQItem: Identifiable {
        let id = UUID()
        let question: String
        let answer: String
    }

    let faqs: [FAQItem] = [
        FAQItem(question: "How do I upgrade to Pro?",
                answer: "Open the Profile tab and select 'Go Pro' to view available plans and features."),
        FAQItem(question: "What happens if I forget my password?",
                answer: "On the login screen, tap 'Forgot Password?' and follow the instructions to reset your credentials."),
        FAQItem(question: "How can I contact support?",
                answer: "Use the contact options below, or email support@matreturnrx.com. For privacy issues, use privacy@matreturnrx.com."),
        FAQItem(question: "Is my data private?",
                answer: "Yes. Your health and training data is stored securely and never shared without your permission. See the Privacy Center for details."),
        FAQItem(question: "How do I report a bug or incident?",
                answer: "Use the 'Report an Issue' option in the Profile tab, or the 'Submit Feedback' button below."),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Frequently Asked Questions")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 4)

                    ForEach(Array(faqs.enumerated()), id: \.offset) { idx, item in
                        VStack(alignment: .leading, spacing: 4) {
                            Button {
                                withAnimation { faqExpanded = (faqExpanded == idx ? nil : idx) }
                            } label: {
                                HStack {
                                    Text(item.question)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: faqExpanded == idx ? "chevron.down" : "chevron.right")
                                        .foregroundColor(.mrxTextMuted)
                                }
                            }
                            if faqExpanded == idx {
                                Text(item.answer)
                                    .font(.system(size: 14))
                                    .foregroundColor(.mrxTextSec)
                                    .padding(.top, 3)
                                    .transition(.opacity)
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 4)
                        Divider().background(Color.mrxDivider)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Contact & Support")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                        Link("Email Support", destination: URL(string: "mailto:support@matreturnrx.com")!)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.mrxBlue)
                        Link("Privacy Questions", destination: URL(string: "mailto:privacy@matreturnrx.com")!)
                            .font(.system(size: 15))
                            .foregroundColor(.mrxTextSec)
                        Link("Visit Website", destination: URL(string: "https://matreturnrx.com")!)
                            .font(.system(size: 15))
                            .foregroundColor(.mrxTextSec)
                    }
                    .padding(.vertical, 8)

                    NavigationLink(destination: IncidentReportScreen()) {
                        Text("Submit Feedback or Report an Issue")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppTheme.fightRed)
                            .cornerRadius(14)
                    }
                    .padding(.top, 10)

                    VStack(alignment: .leading, spacing: 5) {
                        Text("App Version: 1.0")
                            .font(.system(size: 13)).foregroundColor(.mrxTextMuted)
                        Text("MatReturnRx, LLC © 2026")
                            .font(.system(size: 13)).foregroundColor(.mrxTextMuted)
                    }
                    .padding(.top, 28)

                }
                .padding(20)
            }
            .background(Color.mrxBg.ignoresSafeArea())
#if os(iOS)
            .navigationTitle("Help & Support")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.foregroundColor(.mrxBlue)
                }
            }
#endif
        }
    }
}

