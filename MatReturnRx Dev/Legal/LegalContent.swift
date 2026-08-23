//
//  LegalContent.swift
//  MatReturnRx
//

import SwiftUI
import Combine

// ============================================================
// MARK: - Legal Acceptance Record
// ============================================================

struct LegalAcceptanceRecord: Codable, Identifiable {
    let id:                    UUID
    let userId:                String
    let documentKey:           String
    let documentTitle:         String
    let documentVersion:       String
    var accepted:              Bool
    let acceptedAt:            Date
    let userRole:              String
    let appVersion:            String
    let deviceId:              String
    var parentGuardianName:    String?
    var parentGuardianEmail:   String?
}

// ============================================================
// MARK: - Legal Document Model
// ============================================================

struct LegalDocument: Identifiable {
    let id:           String
    let title:        String
    let version:      String
    let checkboxText: String
    let content:      String
    let minorOnly:    Bool
}

// ============================================================
// MARK: - Legal Store
// ============================================================

class LegalStore: ObservableObject {
    static let shared = LegalStore()

    @Published var records: [LegalAcceptanceRecord] = []

    private let key = "mrx_legal_acceptance_records"

    init() { load() }

    func hasAccepted(_ docKey: String, version: String) -> Bool {
        records.contains {
            $0.documentKey     == docKey   &&
            $0.documentVersion == version  &&
            $0.accepted
        }
    }

    func allAccepted(isMinor: Bool) -> Bool {
        LegalDocuments.all(isMinor: isMinor).allSatisfy {
            hasAccepted($0.id, version: $0.version)
        }
    }

    func accept(
        document:    LegalDocument,
        userId:      String,
        role:        String,
        parentName:  String? = nil,
        parentEmail: String? = nil
    ) {
        records.removeAll {
            $0.documentKey == document.id && $0.documentVersion == document.version
        }
        let record = LegalAcceptanceRecord(
            id:                  UUID(),
            userId:              userId,
            documentKey:         document.id,
            documentTitle:       document.title,
            documentVersion:     document.version,
            accepted:            true,
            acceptedAt:          Date(),
            userRole:            role,
            appVersion:          Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
            deviceId:            UUID().uuidString,
            parentGuardianName:  parentName,
            parentGuardianEmail: parentEmail
        )
        records.append(record)
        save()
        syncToAmplify(record)
    }

    func acceptAll(
        isMinor:     Bool,
        userId:      String,
        role:        String,
        parentName:  String? = nil,
        parentEmail: String? = nil
    ) {
        LegalDocuments.all(isMinor: isMinor).forEach {
            accept(document: $0, userId: userId, role: role,
                   parentName: parentName, parentEmail: parentEmail)
        }
    }

    func clearLocal() {
        records = []
        UserDefaults.standard.removeObject(forKey: key)
    }

    private func save() {
        if let encoded = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }

    private func load() {
        guard let data    = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([LegalAcceptanceRecord].self, from: data)
        else { return }
        records = decoded
    }

    // Replace with your Amplify insert when ready
    private func syncToAmplify(_ record: LegalAcceptanceRecord) {}
}

// ============================================================
// MARK: - Legal Documents Registry
// ============================================================

struct LegalDocuments {

    static func all(isMinor: Bool) -> [LegalDocument] {
        var list: [LegalDocument] = [tos, privacy, medical, risk]
        if isMinor { list.append(youth) }
        return list
    }

    static let tos = LegalDocument(
        id:           "terms_of_service",
        title:        "Terms of Service",
        version:      "1.0",
        checkboxText: "I have read and agree to the MatReturnRx Terms of Service.",
        content:      tosText,
        minorOnly:    false
    )

    static let privacy = LegalDocument(
        id:           "privacy_policy",
        title:        "Privacy Policy",
        version:      "1.0",
        checkboxText: "I have read and agree to the MatReturnRx Privacy Policy.",
        content:      privacyText,
        minorOnly:    false
    )

    static let medical = LegalDocument(
        id:           "medical_disclaimer",
        title:        "Medical Disclaimer",
        version:      "1.0",
        checkboxText: "I understand that MatReturnRx provides educational performance and recovery guidance only. It does not diagnose, treat, replace medical care, or provide return-to-play clearance.",
        content:      medicalText,
        minorOnly:    false
    )

    static let risk = LegalDocument(
        id:           "assumption_of_risk",
        title:        "Assumption of Risk",
        version:      "1.0",
        checkboxText: "I understand and accept that exercise, wrestling, grappling, mobility, recovery, and sport participation involve inherent risks, including injury or illness. I voluntarily assume these risks when using MatReturnRx.",
        content:      riskText,
        minorOnly:    false
    )

    static let youth = LegalDocument(
        id:           "youth_athlete_waiver",
        title:        "Youth Athlete Waiver",
        version:      "1.0",
        checkboxText: "I certify that I am the parent or legal guardian of the minor athlete. I authorize the minor athlete to use MatReturnRx and understand that MatReturnRx provides educational performance and recovery guidance only and does not provide medical diagnosis, treatment, or return-to-play clearance.",
        content:      youthText,
        minorOnly:    true
    )
}

// ============================================================
// MARK: - Document Text: Terms of Service
// ============================================================

private let tosText = """
## Terms of Service

Version 1.0

MatReturnRx, LLC ("MatReturnRx," "Company," "we," "us," or "our")

These Terms of Service govern your access to and use of the MatReturnRx mobile application, website, digital content, training modules, recovery modules, educational materials, subscription services, and related products or services.

By creating an account, accessing the app, using any MatReturnRx content, starting a workout, completing a readiness check, viewing a module, purchasing a subscription, or using any related service, you agree to these Terms.

If you do not agree to these Terms, do not use MatReturnRx.

## 1. Purpose of MatReturnRx

MatReturnRx is an educational performance and recovery support platform designed for wrestlers, grapplers, combat athletes, coaches, parents, and teams.

MatReturnRx may provide:

• General exercise guidance
• Mobility routines
• Recovery routines
• Readiness tracking
• Training consistency tracking
• Injury-risk-reduction education
• Knee stability modules
• Neck endurance and control modules
• Shoulder stability and control modules
• Educational safety screens
• Incident reporting tools
• Parent and coach visibility tools
• Subscription-based app features

MatReturnRx is intended to support athletic preparation, recovery, and performance habits.

MatReturnRx does not provide medical diagnosis, medical treatment, physical therapy care, telehealth services, return-to-play clearance, or emergency medical care.

## 2. Educational Use Only

All content provided through MatReturnRx is for educational and general performance-support purposes only.

MatReturnRx content is not intended to:

• Diagnose injuries or medical conditions
• Treat injuries or medical conditions
• Replace evaluation by a physician, physical therapist, athletic trainer, or other qualified healthcare professional
• Provide individualized medical advice
• Provide medical clearance for sport participation
• Replace emergency medical care
• Guarantee injury prevention
• Guarantee pain relief
• Guarantee athletic performance improvement

You are responsible for deciding whether to participate in any activity and for seeking qualified professional care when appropriate.

## 3. No Provider-Patient Relationship

Use of MatReturnRx does not create a provider-patient relationship between you and MatReturnRx, LLC, Juan Ivan Sanchez Aguirre and Itzel Aranza Torres, any employee, contractor, advisor, coach, developer, or affiliate of MatReturnRx.

Even if content is based on physical therapy principles, sports science, strength and conditioning concepts, or clinical practice guideline principles, the app does not provide physical therapy services, medical services, or healthcare services.

## 4. Eligibility

You may use MatReturnRx only if you can legally agree to these Terms.

If you are under 18 years old, you may use MatReturnRx only with the consent of a parent or legal guardian.

If you are under 13 years old, MatReturnRx may require additional parental consent and may limit access to certain features in order to protect user privacy and safety.

Parents and guardians are responsible for supervising minors' use of MatReturnRx.

## 5. Account Registration

To use certain features, you may need to create an account. You agree to provide accurate, current, and complete information when creating your account. You are responsible for keeping your login information confidential. You are responsible for all activity that occurs under your account. You agree to notify MatReturnRx if you believe your account has been accessed without authorization.

## 6. User Roles

MatReturnRx may support different user roles, including:

• Athlete
• Parent or guardian
• Coach
• Team administrator
• Internal admin

Your access to features may depend on your role, subscription status, age, permissions, and consent settings. Coaches and teams may only access athlete information according to the permissions granted by the athlete, parent, guardian, team policy, or applicable law.

## 7. Safety Screening and Red Flags

MatReturnRx may ask safety-related questions before allowing access to certain modules or workouts. You agree to answer these questions honestly.

If you report red-flag symptoms, MatReturnRx may recommend that you stop using a module and seek evaluation from a qualified healthcare professional. Red flags may include:

• Severe pain
• New or worsening swelling
• Numbness, tingling, or weakness
• Dizziness, fainting, confusion, or severe headache
• Recent head, neck, spine, or serious joint injury
• Joint locking, giving way, or instability
• Fever, open wounds, spreading redness, or signs of infection
• Chest pain, severe shortness of breath, or other urgent symptoms
• Being medically restricted from sport or exercise

MatReturnRx does not determine whether you are medically safe to participate. If symptoms are concerning, seek qualified medical evaluation.

## 8. Emergency Situations

MatReturnRx is not an emergency response service. If you experience a medical emergency, call emergency services immediately. Do not rely on MatReturnRx for emergency medical advice, emergency response, concussion management, heat illness management, severe dehydration management, or urgent injury decisions.

## 9. Assumption of Risk

Exercise, sport participation, wrestling, grappling, strength training, conditioning, mobility work, recovery activities, and use of fitness-related products involve inherent risks. These risks may include soreness, strains, sprains, falls, collisions, aggravation of symptoms, illness, dehydration, heat-related illness, skin irritation, skin infection, serious injury, disability, or death. By using MatReturnRx, you acknowledge and accept these risks.

## 10. User Responsibility

You agree to:

• Use MatReturnRx responsibly
• Follow all safety instructions
• Stop activity if symptoms worsen
• Seek qualified medical evaluation when appropriate
• Avoid using the app while impaired, ill, unsafe, or medically restricted
• Use proper technique and supervision when needed
• Follow your school, team, league, athletic association, and healthcare provider rules
• Avoid using MatReturnRx to override medical advice

You are responsible for determining whether your environment, equipment, health status, and supervision are appropriate for participation.

## 11. Coaches and Team Use

Coaches may use MatReturnRx to support team readiness, recovery habits, mobility routines, and training accountability.

Coaches may not use MatReturnRx to:

• Diagnose injuries
• Treat injuries
• Clear athletes for return to sport
• Override medical restrictions
• Ignore red-flag warnings
• Force athletes to participate when symptoms suggest they should stop
• Misrepresent MatReturnRx as medical care

Coaches are responsible for operating within their professional scope, training rules, school policies, and applicable law.

## 12. Parent and Guardian Responsibilities

Parents and guardians are responsible for:

• Reviewing these Terms
• Providing consent for minor users
• Supervising minor users when appropriate
• Ensuring that the athlete stops activity if symptoms worsen
• Seeking qualified healthcare evaluation when needed
• Ensuring that the athlete follows team, school, and medical guidance

MatReturnRx is not a substitute for parental supervision, coaching supervision, athletic training care, or medical care.

## 13. Subscriptions and Payments

MatReturnRx may offer free and paid subscription plans. Paid features may include expanded modules, advanced tracking, progress reports, parent views, team features, or other premium tools.

Subscription fees, billing intervals, trial periods, renewals, and cancellation instructions will be shown at the time of purchase. If you purchase through Apple App Store or Google Play, billing, renewals, refunds, and cancellations are generally managed by Apple or Google according to their policies. Subscriptions may automatically renew unless canceled before the renewal date.

## 14. Refunds and Cancellations

Refunds for purchases made through Apple App Store or Google Play are handled by Apple or Google according to their policies. MatReturnRx may provide cancellation instructions inside the app but cannot always directly cancel or refund subscriptions purchased through third-party app stores. Access may continue until the end of the current billing period after cancellation.

## 15. Acceptable Use

You agree not to:

• Copy, modify, distribute, or sell MatReturnRx content without permission
• Reverse engineer the app
• Use the app for unlawful purposes
• Submit false or misleading information
• Harass, threaten, or abuse other users
• Attempt to access another user's account
• Interfere with app security
• Upload harmful code or malicious content
• Misrepresent MatReturnRx content as your own
• Use MatReturnRx to provide unauthorized medical care

## 16. Intellectual Property

All MatReturnRx content, including but not limited to app design, text, graphics, logos, videos, workouts, modules, progressions, exercise descriptions, systems, trademarks, and educational materials, is owned by MatReturnRx, LLC or licensed to MatReturnRx. You receive a limited, personal, non-exclusive, non-transferable, revocable license to use MatReturnRx for its intended purpose. You do not receive ownership rights in MatReturnRx content.

## 17. User Content

If you submit information, notes, reports, feedback, images, or other content to MatReturnRx, you grant MatReturnRx permission to use that content to provide services, improve the app, respond to support requests, investigate incidents, and operate the platform. You are responsible for ensuring that submitted content is accurate and lawful.

## 18. Privacy

Your use of MatReturnRx is also governed by the MatReturnRx Privacy Policy. Please review the Privacy Policy to understand what information may be collected, how it may be used, and what choices may be available to you.

## 19. Third-Party Services

MatReturnRx may use third-party services for:

• App hosting and authentication
• Database storage and video hosting
• Payment processing and subscription management
• Analytics and crash reporting
• Email and customer support

MatReturnRx is not responsible for third-party services outside its control.

## 20. No Guarantees

MatReturnRx does not guarantee injury prevention, pain relief, recovery, medical improvement, athletic success, competition results, or continuous app availability. Your results may vary based on many factors, including training age, health status, coaching, adherence, nutrition, sleep, medical history, and sport demands.

## 21. Limitation of Liability

To the maximum extent permitted by law, MatReturnRx, LLC, Juan Ivan Sanchez Aguirre and Itzel Aranza Torres, employees, contractors, advisors, affiliates, and partners shall not be liable for any indirect, incidental, consequential, special, punitive, or exemplary damages arising out of or related to use of MatReturnRx. To the maximum extent permitted by law, the total liability of MatReturnRx, LLC shall not exceed the amount paid by you to MatReturnRx during the twelve months before the claim.

## 22. Indemnification

You agree to defend, indemnify, and hold harmless MatReturnRx, LLC, Juan Ivan Sanchez Aguirre and Itzel Aranza Torres, employees, contractors, affiliates, and partners from claims, damages, liabilities, costs, and expenses arising from:

• Your use or misuse of MatReturnRx
• Your violation of these Terms or applicable law
• Your violation of another person's rights
• Your failure to follow safety instructions

## 23. Account Suspension or Termination

MatReturnRx may suspend or terminate your account if you violate these Terms, misuse the app, create safety concerns, fail to pay required fees, attempt unauthorized access, or engage in conduct harmful to MatReturnRx or other users. You may stop using MatReturnRx at any time.

## 24. Changes to the App or Terms

MatReturnRx may update the app, content, features, subscriptions, legal documents, or Terms from time to time. If material changes are made, MatReturnRx may notify users through the app, email, or other reasonable methods. Continued use after updates means you accept the revised Terms.

## 25. Governing Law

These Terms are governed by the laws of the state where MatReturnRx, LLC is organized, unless otherwise required by applicable law.

## 26. Contact

MatReturnRx, LLC
Owners: Juan Ivan Sanchez Aguirre & Itzel Aranza Torres
Email: support@matreturnrx.com
Website: matreturnrx.com
"""

// ============================================================
// MARK: - Document Text: Privacy Policy
// ============================================================

private let privacyText = """
## Privacy Policy

Version 1.0

MatReturnRx, LLC ("MatReturnRx," "Company," "we," "us," or "our")

This Privacy Policy explains how MatReturnRx may collect, use, store, share, and protect information when you use the MatReturnRx mobile application, website, digital content, subscriptions, and related services.

By using MatReturnRx, you agree to this Privacy Policy. If you do not agree, do not use MatReturnRx.

## 1. Important Notice

MatReturnRx is an educational performance and recovery support app. It is not intended to provide medical diagnosis, medical treatment, physical therapy services, telehealth services, or emergency medical care.

Although MatReturnRx may collect fitness, readiness, soreness, pain, recovery, training, or wellness-related information, this does not automatically mean MatReturnRx is subject to HIPAA. Even when HIPAA does not apply, MatReturnRx still takes privacy seriously.

## 2. Information We May Collect

MatReturnRx may collect the following categories of information.

A. Account Information:

• Name
• Email address
• Password or authentication credentials
• User role
• Account status and subscription status
• Login activity

B. Athlete Profile Information:

• Athlete first name
• Date of birth and age category
• Sport and experience level
• Training phase
• Height and weight
• Goals and selected body areas to monitor

C. Parent or Guardian Information (for minor users):

• Parent or guardian name
• Parent or guardian email
• Relationship to athlete
• Consent status, timestamp, and version

D. Readiness and Training Information:

• Readiness, soreness, sleep quality, stress, motivation, and confidence scores
• Pain or soreness score
• Workout completion and module selection
• Session history and progression or regression status
• Notes submitted by the user

E. Safety and Red Flag Responses:

We may collect responses to safety questions, including whether a user reports severe pain, swelling, numbness or tingling, recent head or neck injury, fever, joint locking or giving way, dizziness, or medical restriction from sport.

F. Incident Reports:

• Type of issue and description
• Module or exercise involved
• Pain level and whether medical help was sought
• Photo or attachment if submitted
• Date, time, and follow-up status

G. Subscription and Payment Information:

MatReturnRx may receive limited subscription-related information such as subscription status, plan type, renewal date, trial status, platform, and customer ID from the subscription provider. MatReturnRx generally does not store full payment card information.

H. Device and Technical Information:

• Device type and operating system
• App version and IP address
• Device identifiers
• Crash logs, error logs, analytics events, and usage activity

I. Communications:

• Name, email, and message content
• Support request details, feedback, and survey responses

## 3. How We Use Information

MatReturnRx may use information to:

• Create and manage accounts
• Provide and personalize app features
• Generate readiness recommendations
• Display training and recovery modules
• Track progress and maintain legal acceptance records
• Verify parent or guardian consent
• Provide support and manage subscriptions
• Improve app performance and debug errors
• Analyze app usage and respond to incident reports
• Maintain safety and compliance records
• Enforce Terms of Service and protect users

## 4. How We Use Readiness and Pain Information

MatReturnRx may use readiness, soreness, pain, and safety responses to provide general educational recommendations — such as continuing with a module, modifying volume, using a recovery-focused session, or pausing and seeking qualified evaluation if red flags are present.

MatReturnRx does not use this information to diagnose injuries, treat injuries, or provide medical clearance.

## 5. How We Share Information

A. With Service Providers: We may share information with vendors that help us operate the app, such as hosting, authentication, database, video hosting, payment processing, subscription management, analytics, crash reporting, and customer support providers. These providers may process information only as needed to provide services to MatReturnRx.

B. With Parents or Guardians: For minor athletes, certain information may be visible to a parent or guardian, such as athlete profile, general readiness status, session completion, and safety flags depending on settings and applicable law.

C. With Coaches or Teams: If a user joins a team or coach account, certain information may be shared with the coach or team — such as roster status, session completion, general readiness color, and team compliance metrics. Detailed private notes, sensitive pain details, weight information, or other sensitive data should not be shared by default unless the user or parent/guardian has given permission.

D. For Legal or Safety Reasons: We may disclose information to comply with law, respond to legal requests, protect user safety, investigate misuse, enforce Terms, protect rights or security, or respond to emergencies.

E. Business Transfers: If MatReturnRx is involved in a merger, acquisition, sale, or reorganization, information may be transferred as part of that transaction, subject to appropriate protections.

## 6. De-Identified and Aggregated Data

MatReturnRx may use de-identified or aggregated data for app improvement, research, analytics, product development, reporting, and business planning. De-identified or aggregated data is not intended to identify individual users.

## 7. Children and Minors

MatReturnRx may be used by youth athletes only with appropriate parent or guardian consent. If a user is under 18, parent or guardian consent may be required. If a user is under 13, additional privacy requirements may apply, and MatReturnRx may limit features or require verified parental consent before collecting personal information.

Parents or guardians may contact MatReturnRx to request access, correction, or deletion of a minor's information.

## 8. Data Retention

MatReturnRx may retain information as long as needed to provide services, maintain user accounts, comply with legal obligations, resolve disputes, enforce agreements, maintain safety records, maintain legal acceptance logs, and improve app functionality.

Some records — such as legal acceptance records, incident reports, and safety-related logs — may be retained for longer periods where appropriate.

## 9. Data Security

MatReturnRx uses reasonable administrative, technical, and physical safeguards to protect information. These may include encrypted transmission, access controls, role-based permissions, secure authentication, audit logs, data backup, and vendor security review. No system is completely secure. MatReturnRx cannot guarantee that information will never be accessed, disclosed, altered, or destroyed.

## 10. Account Deletion and Data Requests

Users may request to access, correct, delete, or export certain personal information; manage privacy settings; and manage coach/team sharing and parent/guardian access. Some information may be retained if required for legal, safety, security, fraud prevention, dispute resolution, or compliance purposes.

## 11. Push Notifications and Communications

MatReturnRx may send readiness reminders, workout reminders, recovery reminders, safety-related messages, subscription notices, app updates, and support communications. Users may manage push notification permissions through device settings.

## 12. Analytics and Tracking

MatReturnRx may use analytics to understand signup completion, onboarding completion, module usage, session completion, app performance, subscription events, user engagement, and crash reports. MatReturnRx avoids using sensitive health or youth data for advertising without proper consent and compliance review.

## 13. Third-Party Links

MatReturnRx may contain links to third-party websites, app stores, payment providers, or resources. MatReturnRx is not responsible for third-party privacy practices.

## 14. International Users

If you use MatReturnRx outside the United States, your information may be processed in the United States or other countries where our service providers operate. Privacy rights may vary depending on your location.

## 15. Changes to This Privacy Policy

MatReturnRx may update this Privacy Policy from time to time. If material changes are made, MatReturnRx may notify users through the app, email, or other reasonable methods. Continued use after changes means you accept the updated Privacy Policy.

## 16. Contact

MatReturnRx, LLC
Owners: Juan Ivan Sanchez Aguirre & Itzel Aranza Torres
Privacy Email: privacy@matreturnrx.com
Support Email: support@matreturnrx.com
"""

// ============================================================
// MARK: - Document Text: Medical Disclaimer
// ============================================================

private let medicalText = """
## Medical Disclaimer

Version 1.0

MatReturnRx, LLC

MatReturnRx is an educational performance and recovery support app. MatReturnRx does not provide medical advice, medical diagnosis, medical treatment, physical therapy services, telehealth services, emergency medical care, or return-to-play clearance.

By using MatReturnRx, you acknowledge and agree to the following.

## 1. Educational Purpose Only

All information, exercises, videos, modules, readiness scores, recovery suggestions, mobility routines, strengthening routines, safety screens, and educational content in MatReturnRx are provided for general educational and performance-support purposes only.

The content is not intended to diagnose, treat, cure, prevent, or manage any disease, injury, disorder, or medical condition.

## 2. Not a Substitute for Medical Care

MatReturnRx is not a substitute for evaluation by a qualified healthcare professional. You should consult a physician, physical therapist, athletic trainer, or other qualified healthcare professional before beginning any exercise program if you have:

• Current pain
• Recent injury
• Surgery history
• Medical condition
• Neurological symptoms
• Cardiovascular concerns
• Dizziness or fainting
• Severe fatigue
• Illness
• Uncertainty about safe participation

## 3. No Physical Therapy Relationship

Although MatReturnRx may be informed by physical therapy principles, sports science, strength and conditioning concepts, or clinical practice guideline principles, use of the app does not create a physical therapist-patient relationship or any provider-patient relationship.

MatReturnRx does not evaluate, diagnose, treat, discharge, or clear users for sport.

## 4. No Diagnosis

MatReturnRx does not diagnose:

• ACL injuries or MCL injuries
• Meniscus injuries
• Shoulder instability or rotator cuff injuries
• Neck injuries or concussions
• Skin infections
• Dehydration or heat illness
• Any other medical condition

Any references to body regions, symptoms, exercises, or risk factors are for educational and performance-support purposes only.

## 5. No Treatment

MatReturnRx does not treat injuries or medical conditions. Modules such as Mobility / Recovery, Knee Starter, Neck Starter, and Shoulder Starter are designed to support general movement quality, readiness, strength, endurance, control, and recovery habits. They are not treatment plans.

## 6. Red Flags and When to Stop

Stop using MatReturnRx and seek qualified medical evaluation if you experience:

• Severe pain
• Pain that worsens during activity
• Pain that does not improve with rest
• Numbness, tingling, or weakness
• Dizziness, fainting, confusion, or severe headache
• Chest pain or severe shortness of breath
• New or worsening swelling
• Joint locking, giving way, or instability
• Recent head, neck, spine, or serious joint injury
• Fever, open wounds, spreading redness, drainage, or possible infection
• Signs of dehydration, heat illness, or unsafe weight cutting
• Any symptom that feels unusual, severe, or concerning

If you believe you are experiencing a medical emergency, call emergency services immediately.

## 7. Sport Participation and Return-to-Play

MatReturnRx does not clear athletes for participation, return to practice, return to competition, or return to play. Only qualified healthcare professionals, athletic trainers, physicians, or authorized personnel may make medical clearance decisions according to applicable laws, policies, and sport rules.

A green readiness score in MatReturnRx does not mean you are medically cleared.

## 8. Weight-Cutting and Hydration

Any weight, hydration, or recovery-related content in MatReturnRx is educational only. MatReturnRx does not prescribe weight cuts, dehydration strategies, nutrition plans, medical diets, or fluid restriction.

Unsafe weight cutting can cause serious harm, including dehydration, heat illness, fainting, organ stress, reduced performance, hospitalization, or death. Seek qualified medical, nutritional, or athletic training guidance before engaging in weight-cutting practices.

## 9. Skin Health

Any skin health content in MatReturnRx is educational only. MatReturnRx does not diagnose ringworm, staph, MRSA, impetigo, skin infections, wounds, rashes, or contagious conditions.

If you notice suspicious skin changes, open wounds, spreading redness, drainage, fever, or pain, seek medical evaluation and follow team, school, league, and public health rules before contact participation.

## 10. User Responsibility

You are responsible for:

• Using good judgment and following app safety instructions
• Stopping when symptoms worsen
• Seeking qualified care when needed
• Using proper technique and training in a safe environment
• Following coach, school, league, medical, and parental guidance

Do not ignore medical advice because of anything you see in MatReturnRx.

## 11. No Guarantee

MatReturnRx does not guarantee injury prevention, pain reduction, recovery, improved performance, medical improvement, safe sport participation, safe weight cutting, or competition success. Results vary by individual.

## Contact

MatReturnRx, LLC
support@matreturnrx.com
"""

// ============================================================
// MARK: - Document Text: Assumption of Risk
// ============================================================

private let riskText = """
## Assumption of Risk

Version 1.0

MatReturnRx, LLC

By using MatReturnRx, I acknowledge that participation in exercise, sport preparation, wrestling, grappling, combat sports, mobility work, strengthening exercises, conditioning, recovery activities, and related performance activities involves inherent risks.

I understand and accept the risks described below.

## 1. Inherent Risks of Athletic Activity

I understand that athletic activity may involve risk of injury or illness, even when performed correctly. These risks may include:

• Muscle soreness and fatigue
• Sprains, strains, and bruising
• Joint irritation, tendon irritation, and ligament injury
• Muscle injury
• Falls and collision-related injury
• Aggravation of prior symptoms
• Neck, shoulder, knee, back, ankle, or foot pain
• Skin irritation and skin infection
• Dehydration and heat illness
• Dizziness and fainting
• Serious injury, disability, or death

## 2. Combat Sport Risks

I understand that wrestling, grappling, BJJ, MMA, judo, and related combat sports involve additional risks due to contact, takedowns, scrambles, submissions, mat contact, partner resistance, fatigue, and competition demands. These risks may include:

• Head or neck injury
• Joint sprains and shoulder instability
• Knee injury
• Skin infections and concussion
• Overtraining and unsafe weight-cutting practices
• Contact-related injuries
• Recurrence of previous symptoms

MatReturnRx does not eliminate these risks.

## 3. Risk of Using App-Based Guidance

I understand that MatReturnRx provides educational guidance through an app and cannot directly observe my movement, environment, technique, health status, or symptoms. I understand that app-based guidance has limitations. MatReturnRx cannot determine whether I am medically safe to participate. I am responsible for stopping if something does not feel right.

## 4. Responsibility to Stop

I agree to stop using a module or exercise and seek qualified evaluation if I experience:

• Severe pain or worsening pain
• Numbness, tingling, or weakness
• Dizziness, fainting, or confusion
• Severe headache or chest pain
• Severe shortness of breath
• Swelling or locking or giving way
• Fever or open wounds or signs of infection
• Recent head, neck, spine, or serious joint injury
• Any symptom that feels unsafe or concerning

## 5. No Guarantee of Safety

I understand that even if I follow all instructions, injuries or adverse events may still occur. I understand that readiness scores, green/yellow/red recommendations, progress tracking, and module completion do not guarantee safety or medical clearance.

## 6. Personal Responsibility

I agree that I am responsible for:

• My decision to participate
• My exercise technique and training environment
• My equipment use and intensity level
• My decision to stop and seek professional care
• Following medical restrictions
• Following team, school, league, and parent rules

## 7. Voluntary Participation

I voluntarily choose to use MatReturnRx. I understand that I may stop using the app at any time. I understand that I should not participate if I feel unsafe, unwell, impaired, medically restricted, or uncertain.

## 8. Release of Liability

To the maximum extent permitted by law, I release and hold harmless MatReturnRx, LLC, Juan Ivan Sanchez Aguirre and Itzel Aranza Torres, employees, contractors, advisors, affiliates, and partners from claims, damages, injuries, losses, costs, or liabilities arising from my use of MatReturnRx, except where such release is prohibited by law.

I understand that some jurisdictions may limit the enforceability of waivers or releases.

## Contact

MatReturnRx, LLC
support@matreturnrx.com
"""

// ============================================================
// MARK: - Document Text: Youth Athlete Waiver
// ============================================================

private let youthText = """
## Youth Athlete Waiver and Parent/Guardian Consent

Version 1.0

MatReturnRx, LLC

This Youth Athlete Waiver and Parent/Guardian Consent applies when a user under the age of 18 uses MatReturnRx.

The parent or legal guardian must review and accept this waiver before the minor athlete uses MatReturnRx.

## 1. Parent or Guardian Consent

I confirm that I am the parent or legal guardian of the minor athlete using MatReturnRx. I authorize the minor athlete to use MatReturnRx for educational performance and recovery support.

I understand that MatReturnRx does not provide medical diagnosis, medical treatment, physical therapy services, telehealth services, emergency medical care, or return-to-play clearance.

## 2. Minor Athlete Information

The following information will be collected for consent records:

• Minor athlete name and date of birth
• Parent or guardian name and email
• Parent or guardian relationship to athlete
• Consent date and time
• Consent version and app version

## 3. Educational Use Only

I understand that MatReturnRx provides educational performance and recovery content. This may include:

• Mobility routines and recovery routines
• Readiness tracking
• Knee stability exercises
• Neck endurance exercises
• Shoulder control exercises
• Progress tracking and safety screens
• Incident reporting tools

I understand that this content is not medical care.

## 4. No Medical Care or Clearance

I understand that MatReturnRx does not:

• Diagnose or treat injuries
• Replace a physician, physical therapist, athletic trainer, or other healthcare professional
• Clear the athlete for practice or competition
• Determine whether the athlete is medically safe to participate
• Provide emergency care
• Guarantee injury prevention or recovery

I understand that medical decisions must be made by qualified healthcare professionals and appropriate school, team, or sport personnel.

## 5. Acknowledgment of Athletic Risk

I understand that exercise, wrestling, grappling, combat sports, mobility work, conditioning, and recovery activities involve inherent risks. These risks may include:

• Soreness, fatigue, sprains, strains, and bruising
• Falls and contact injury
• Head or neck injury
• Knee, shoulder, and back injury
• Skin irritation and skin infection
• Dehydration and heat illness
• Aggravation of symptoms
• Serious injury, disability, or death

I understand that MatReturnRx cannot eliminate these risks.

## 6. Parent/Guardian Responsibility

I agree that I am responsible for:

• Supervising the minor athlete's use of MatReturnRx when appropriate
• Ensuring the athlete uses the app responsibly
• Ensuring the athlete stops if symptoms worsen
• Seeking medical care when needed
• Following physician, physical therapist, athletic trainer, school, team, and league guidance
• Ensuring the athlete does not use MatReturnRx to ignore medical restrictions
• Reviewing safety warnings and app instructions

## 7. Minor Athlete Safety Rules

The minor athlete should stop using MatReturnRx and seek adult assistance or qualified evaluation if they experience:

• Severe pain or worsening symptoms
• Numbness, tingling, or weakness
• Dizziness, fainting, confusion, or severe headache
• Chest pain or severe shortness of breath
• New or worsening swelling
• Joint locking, giving way, or instability
• Recent head, neck, spine, or serious joint injury
• Fever, open wounds, spreading redness, or signs of infection
• Symptoms of dehydration or heat illness
• Any symptom that feels unsafe or concerning

If there is a medical emergency, call emergency services immediately.

## 8. Data and Privacy for Youth Users

I understand that MatReturnRx may collect information about the minor athlete, such as account information, athlete profile, readiness check-ins, training phase, goals, module completion, safety responses, incident reports, and parent/guardian consent records.

I understand that MatReturnRx uses this information to provide app features, support safety workflows, improve app functionality, and maintain compliance records.

I understand that I may contact MatReturnRx to request access, correction, or deletion of the minor athlete's information, subject to legal, safety, and compliance retention requirements.

## 9. Coach and Team Sharing

If the minor athlete joins a team or coach account, certain information may be shared with the coach or team — such as attendance or completion status, general readiness status, team compliance metrics, and safety flags when appropriate.

Detailed private notes, sensitive pain details, weight data, or other sensitive information should not be shared by default unless parent/guardian consent permits it.

## 10. Voluntary Participation

I understand that use of MatReturnRx is voluntary. I may stop the minor athlete's use of MatReturnRx at any time. I understand that the athlete should not participate if they are injured, ill, medically restricted, or unsure whether activity is safe.

## 11. Release of Liability

To the maximum extent permitted by law, I, on behalf of myself and the minor athlete, release and hold harmless MatReturnRx, LLC, Juan Ivan Sanchez Aguirre and Itzel Aranza Torres, employees, contractors, advisors, affiliates, and partners from claims, damages, injuries, losses, costs, or liabilities arising from the minor athlete's use of MatReturnRx, except where such release is prohibited by law.

I understand that some jurisdictions may limit the enforceability of waivers signed on behalf of minors.

## 12. Parent/Guardian Certification

By accepting this waiver, I certify that:

• I am the parent or legal guardian of the minor athlete
• I have authority to provide consent
• I have read and understood this waiver
• I understand the risks involved
• I understand MatReturnRx is not medical care
• I voluntarily allow the minor athlete to use MatReturnRx

## Contact

MatReturnRx, LLC
Owners: Juan Ivan Sanchez Aguirre & Itzel Aranza Torres
support@matreturnrx.com
"""

// ============================================================
// MARK: - Legal Paragraph Model
// ============================================================

struct LegalParagraph: Identifiable {
    let id      = UUID()
    let text:    String
    let bullets: [String]
    let kind:    Kind

    enum Kind { case heading, bulletList, body }

    init(heading: String) { text = heading; bullets = []; kind = .heading }
    init(bullets: [String]) { text = ""; self.bullets = bullets; kind = .bulletList }
    init(body: String) { text = body; bullets = []; kind = .body }
}
