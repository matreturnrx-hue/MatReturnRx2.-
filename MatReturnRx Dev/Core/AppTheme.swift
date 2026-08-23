//
//  AppTheme.swift
//  MatReturnRx
//

import SwiftUI

// ============================================================
// MARK: - Brand Colors
// ============================================================

extension Color {
    // Core backgrounds
    static let mrxBg        = Color(red: 0.027, green: 0.102, blue: 0.184) // Deep Navy #071A2F
    static let mrxCard      = Color(red: 0.094, green: 0.094, blue: 0.094) // Graphite #181818
    static let mrxCardLight = Color(red: 0.118, green: 0.118, blue: 0.118) // Graphite #1E1E1E
    // Brand accents
    static let mrxBlue         = Color(red: 0.0,   green: 0.482, blue: 1.0)
    static let mrxBlueMuted    = Color(red: 0.102, green: 0.227, blue: 0.361)
    static let mrxRed          = Color(red: 0.843, green: 0.149, blue: 0.220) // Fight Red #D72638
    static let mrxDanger       = Color(red: 0.843, green: 0.149, blue: 0.220) // Fight Red #D72638
    static let mrxElectricOrange = Color(red: 1.000, green: 0.420, blue: 0.000) // Electric Orange #FF6B00
    static let mrxOrange       = Color(red: 1.000, green: 0.420, blue: 0.000) // Electric Orange #FF6B00
    static let mrxTeal         = Color(red: 0.000, green: 0.651, blue: 0.651) // Recovery Teal #00A6A6
    static let mrxGreen        = Color(red: 0.239, green: 0.859, blue: 0.310)
    static let mrxYellow       = Color(red: 1.000, green: 0.788, blue: 0.251)
    static let mrxPurple       = Color(red: 0.416, green: 0.302, blue: 1.000)
    // Text
    static let mrxTextSec   = Color(red: 0.722, green: 0.757, blue: 0.800) // Muted Text #B8C1CC
    static let mrxTextMuted = Color(red: 0.550, green: 0.600, blue: 0.650)
    // Dividers
    static let mrxBorder    = Color.white.opacity(0.10)
    static let mrxDivider   = Color.white.opacity(0.06)
}

// ============================================================
// MARK: - App Theme
// ============================================================

enum AppTheme {
    static let deepNavy       = Color.mrxBg
    static let graphite       = Color.mrxCard
    static let fightRed       = Color.mrxRed
    static let electricOrange = Color.mrxElectricOrange
    static let recoveryTeal   = Color.mrxTeal
    static let iceWhite       = Color(red: 0.969, green: 0.976, blue: 0.984)
    static let mutedText      = Color.mrxTextSec
}
