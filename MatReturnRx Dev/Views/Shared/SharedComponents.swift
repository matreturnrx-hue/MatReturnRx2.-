//
//  SharedComponents.swift
//  MatReturnRx
//

import SwiftUI

// ============================================================
// MARK: - Shared UI Components
// ============================================================

enum MRXButtonStyle { case primary, outline, danger }

struct MRXButton: View {
    let title:  String
    var style:  MRXButtonStyle = .primary
    var color:  Color = .mrxBlue
    var action: (() -> Void)?

    var bgColor: Color {
        switch style {
        case .primary: return color
        case .outline: return .clear
        case .danger:  return .mrxDanger
        }
    }
    var fgColor: Color {
        switch style {
        case .primary: return .white
        case .outline: return .white
        case .danger:  return .white
        }
    }
    var borderColor: Color {
        switch style {
        case .outline: return Color.white.opacity(0.25)
        default:       return .clear
        }
    }

    var body: some View {
        Button(action: { action?() }) {
            Text(title)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(fgColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(bgColor)
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(borderColor, lineWidth: 1.5))
        }
    }
}

struct MRXField: View {
    enum FieldType { case name, email, password }
    let label: String
    @Binding var text: String
    let type:  FieldType

    var body: some View {
        makeField()
            .font(.system(size: 16))
            .foregroundColor(.white)
            .padding(16)
            .background(Color.mrxCard)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.mrxBorder, lineWidth: 1))
    }
    
    @ViewBuilder
    private func makeField() -> some View {
        if type == .password {
            SecureField(label, text: $text)
#if os(iOS)
                .textContentType(.password)
#endif
        } else if type == .email {
            TextField(label, text: $text)
#if os(iOS)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .textContentType(.emailAddress)
#else
                .autocorrectionDisabled(true)
#endif
        } else {
            TextField(label, text: $text)
#if os(iOS)
                .keyboardType(.default)
                .textInputAutocapitalization(.words)
                .textContentType(.name)
#endif
        }
    }
}

struct MRXPickerRow: View {
    let label:      String
    @Binding var selection: String
    let options:    [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.mrxTextMuted)
            Picker(label, selection: $selection) {
                ForEach(options, id: \.self) { Text($0).tag($0) }
            }
            .pickerStyle(.menu)
            .accentColor(.mrxBlue)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Color.mrxCard)
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.mrxBorder, lineWidth: 1))
        }
    }
}

struct MRXDisclaimerBox: View {
    let text:    String
    var compact: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if !compact {
                Rectangle().fill(Color.mrxYellow).frame(width: 3)
                    .cornerRadius(1.5)
            }
            Text(text)
                .font(.system(size: compact ? 11 : 12))
                .foregroundColor(.mrxTextMuted)
                .italic()
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(compact ? 10 : 14)
        .background(Color.mrxCard.opacity(compact ? 0.6 : 1))
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.mrxBorder, lineWidth: 1))
    }
}

struct StatCard: View {
    let num:    String
    let label:  String
    var color:  Color = .white

    var body: some View {
        VStack(spacing: 4) {
            Text(num)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.mrxTextMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.mrxCard)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.mrxBorder, lineWidth: 1))
    }
}

struct CheckToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 5)
                    .fill(configuration.isOn ? Color.mrxBlue : Color.clear)
                    .frame(width: 22, height: 22)
                RoundedRectangle(cornerRadius: 5)
                    .stroke(Color.mrxBlue, lineWidth: 2)
                    .frame(width: 22, height: 22)
                if configuration.isOn {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .onTapGesture { configuration.isOn.toggle() }
            configuration.label
            Spacer()
        }
    }
}



