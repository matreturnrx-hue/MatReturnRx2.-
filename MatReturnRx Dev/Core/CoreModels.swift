//
//  CoreModels.swift
//  MatReturnRx
//

import SwiftUI

// ============================================================
// MARK: - Legal Constants  (⚠️ DO NOT MODIFY without legal review)
// ============================================================

struct D {
    static let core         = "MatReturnRx provides educational performance and recovery guidance. It does not diagnose, treat, or replace medical care. Stop and seek evaluation from a qualified healthcare professional if symptoms worsen, new symptoms appear, or red flags are present."
    static let short        = "Educational guidance only. Not medical care."
    static let medCheck     = "I understand MatReturnRx provides educational performance and recovery guidance and does not diagnose, treat, or replace medical care."
    static let safeCheck    = "I agree to stop and seek qualified medical evaluation if symptoms worsen, red flags appear, or I am unsure whether it is safe to continue."
    static let redFlag      = "Pause this module. MatReturnRx cannot determine whether this is safe to train through. Seek evaluation from a qualified healthcare professional before continuing."
    static let parentCon    = "I confirm that I am the parent or legal guardian of this athlete and authorize the athlete to use MatReturnRx for educational performance and recovery support. I understand MatReturnRx does not provide medical diagnosis, treatment, or medical clearance."
    static let subLegal     = "Your subscription will auto-renew unless canceled at least 24 hours before the end of the current billing period. Payment will be charged to your Apple ID account. Manage or cancel anytime in Settings → Subscriptions."
}

// ============================================================
// MARK: - Data Models
// ============================================================

enum TrafficLight: String {
    case green, yellow, red

    var color: Color {
        switch self {
        case .green:  return .mrxGreen
        case .yellow: return .mrxYellow
        case .red:    return .mrxDanger
        }
    }
    var bgColor: Color { color.opacity(0.13) }
    var borderColor: Color { color.opacity(0.5) }

    var label: String {
        switch self {
        case .green:  return "Good to Go"
        case .yellow: return "Modify Today"
        case .red:    return "Pause Today"
        }
    }
    var emoji: String {
        switch self {
        case .green:  return "🟢"
        case .yellow: return "🟡"
        case .red:    return "🔴"
        }
    }
    var message: String {
        switch self {
        case .green:  return "Great. Your body is ready for today's session."
        case .yellow: return "We'll reduce volume and focus on controlled movement."
        case .red:    return "Stop and seek qualified evaluation before continuing."
        }
    }
    var recommendation: String {
        switch self {
        case .green:  return "Complete your full session as planned. Monitor how you feel throughout."
        case .yellow: return "Train at 70% intensity. Skip high-effort work. Focus on mobility. Stop if pain increases."
        case .red:    return "Do not train today. If you have pain or symptoms, seek evaluation from a qualified healthcare professional."
        }
    }
}

struct TLResult {
    let status: TrafficLight
    let score:  Double
}

struct MRXExercise: Identifiable {
    let id: String
    let name: String
    let sets: Int
    let reps: String
    let cues: [String]
    let safetyWarning: String
}

struct MRXModule: Identifiable {
    let id: String
    let name: String
    let tagline: String
    let durationMin: Int
    let durationMax: Int
    let color: Color
    let isPro: Bool
    let evidencePanel: String
    let exercises: [MRXExercise]
    var exerciseCount: Int { exercises.count }
}

enum FeltResponse: String, CaseIterable {
    case better = "Better"
    case same   = "Same"
    case worse  = "Worse"
}

// ============================================================
// MARK: - Traffic Light Engine
// ============================================================

func evaluateReadiness(readiness: Double, soreness: Double, sleep: Double,
                       stress: Double, motivation: Double, pain: Double,
                       confidence: Double) -> TLResult {
    let painInv     = 10.0 - pain
    let sorenessInv = 10.0 - soreness
    let composite   = (readiness   * 0.30) + (painInv     * 0.25) +
                      (sleep       * 0.15) + (sorenessInv * 0.12) +
                      (motivation  * 0.10) + (confidence  * 0.08)
    let score = (composite * 10).rounded() / 10

    if pain >= 5              { return TLResult(status: .red,    score: score) }
    if composite < 3.5        { return TLResult(status: .red,    score: score) }
    if composite < 6.5 || pain >= 3 || sleep < 4 || soreness >= 7 {
                                return TLResult(status: .yellow, score: score) }
    return TLResult(status: .green, score: score)
}

// ============================================================
// MARK: - Progress Tracking
// ============================================================
// Note: Progress tracking models and service are in MRXProgressTracking.swift (MatReturnRx 2.0)

// ============================================================
// MARK: - Module Database
// ============================================================
// Note: mrxModules is defined in ModuleData.swift


