//
//  BrandLogoView.swift
//  MatReturnRx
//

import SwiftUI

// ============================================================
// MARK: - Brand Logo View
// ============================================================

struct BrandLogoView: View {
    var compact: Bool = false

    var body: some View {
        if compact {
            compactLogo
        } else {
            fullLogo
        }
    }

    private var compactLogo: some View {
        ZStack {
            Circle()
                .stroke(AppTheme.fightRed, lineWidth: 2)
                .frame(width: 44, height: 44)
            Text("MRx")
                .font(.system(size: 14, weight: .black))
                .foregroundColor(.white)
            // Return arrow accent
            Image(systemName: "arrow.uturn.right")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(AppTheme.fightRed)
                .offset(x: 12, y: 12)
        }
    }

    private var fullLogo: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .stroke(AppTheme.fightRed, lineWidth: 2.5)
                        .frame(width: 56, height: 56)
                    Text("MRx")
                        .font(.system(size: 18, weight: .black))
                        .foregroundColor(.white)
                    Image(systemName: "arrow.uturn.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(AppTheme.fightRed)
                        .offset(x: 16, y: 16)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("MatReturnRx")
                        .font(.system(size: 26, weight: .black))
                        .foregroundColor(.white)
                    Text("Built for Grapplers. Engineered by PT Science.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppTheme.fightRed)
                }
            }
        }
    }
}
