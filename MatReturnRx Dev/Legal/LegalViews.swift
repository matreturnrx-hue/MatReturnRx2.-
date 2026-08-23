//
//  LegalViews.swift
//  MatReturnRx
//

import SwiftUI

// ============================================================
// MARK: - Legal Text Renderer
// ============================================================

struct LegalTextRenderer: View {
    let content: String

    var paragraphs: [LegalParagraph] { parse(content) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(paragraphs) { para in
                switch para.kind {
                case .heading:
                    Text(para.text)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 26)
                        .padding(.bottom, 8)
                case .bulletList:
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(para.bullets, id: \.self) { item in
                            HStack(alignment: .top, spacing: 10) {
                                Text("•")
                                    .font(.system(size: 14))
                                    .foregroundColor(.mrxBlue)
                                    .frame(width: 10)
                                Text(item)
                                    .font(.system(size: 14))
                                    .foregroundColor(.mrxTextSec)
                                    .lineSpacing(3)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .padding(.bottom, 14)
                case .body:
                    Text(para.text)
                        .font(.system(size: 14))
                        .foregroundColor(.mrxTextSec)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom, 12)
                }
            }
        }
    }

    private func parse(_ raw: String) -> [LegalParagraph] {
        raw
            .components(separatedBy: "\n\n")
            .compactMap { block -> LegalParagraph? in
                let trimmed = block.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return nil }

                if trimmed.hasPrefix("## ") {
                    return LegalParagraph(heading: String(trimmed.dropFirst(3)))
                }

                let lines = trimmed
                    .components(separatedBy: "\n")
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }

                let bulletLines = lines.filter { $0.hasPrefix("• ") }
                if !bulletLines.isEmpty && bulletLines.count == lines.count {
                    return LegalParagraph(bullets: bulletLines.map { String($0.dropFirst(2)) })
                }

                return LegalParagraph(body: trimmed.replacingOccurrences(of: "\n", with: " "))
            }
    }
}

// ============================================================
// MARK: - Legal Document Viewer
// ============================================================

struct LegalDocumentViewer: View {
    let document: LegalDocument
    let onRead:   () -> Void

    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    HStack {
                        Text("Version \(document.version)")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.mrxBlue)
                            .padding(.horizontal, 10).padding(.vertical, 4)
                            .background(Color.mrxBlueMuted)
                            .cornerRadius(8)
                        Text("MatReturnRx, LLC")
                            .font(.system(size: 11))
                            .foregroundColor(.mrxTextMuted)
                        Spacer()
                    }
                    .padding(.horizontal, 20).padding(.top, 16).padding(.bottom, 4)

                    LegalTextRenderer(content: document.content)
                        .padding(.horizontal, 20).padding(.bottom, 12)

                    Divider().background(Color.mrxBorder).padding(.horizontal, 20)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("REQUIRED ACCEPTANCE")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.mrxTextMuted)
                            .kerning(0.8)
                        Text(document.checkboxText)
                            .font(.system(size: 13))
                            .foregroundColor(.mrxTextSec)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(14)
                    .background(Color.mrxBlueMuted.opacity(0.6))
                    .cornerRadius(12)
                    .padding(.horizontal, 20).padding(.vertical, 16)

                    MRXButton(title: "✓  I've Read This Document") {
                        onRead()
                        dismiss()
                    }
                    .padding(.horizontal, 20).padding(.bottom, 8)

                    Text("Tapping above marks this document as read and returns you to the acceptance screen.")
                        .font(.system(size: 11))
                        .foregroundColor(.mrxTextMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24).padding(.bottom, 48)
                }
            }
            .background(Color.mrxBg.ignoresSafeArea())
            .navigationTitle(document.title)
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

// ============================================================
// MARK: - Legal Check Row
// ============================================================

struct LegalCheckRow: View {
    @Binding var isChecked: Bool
    let document: LegalDocument

    @State private var showDoc = false

    var body: some View {
        VStack(spacing: 0) {

            HStack(alignment: .top, spacing: 12) {
                Button { isChecked.toggle() } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(isChecked ? Color.mrxBlue : Color.clear)
                            .frame(width: 22, height: 22)
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(Color.mrxBlue, lineWidth: 2)
                            .frame(width: 22, height: 22)
                        if isChecked {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 6) {
                        Text(document.title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                        if document.minorOnly {
                            Text("MINOR")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.mrxYellow)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Color.mrxYellow.opacity(0.15))
                                .cornerRadius(4)
                        }
                        Spacer()
                        if isChecked {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.mrxGreen)
                                .font(.system(size: 16))
                        }
                    }
                    Text(document.checkboxText)
                        .font(.system(size: 12))
                        .foregroundColor(.mrxTextSec)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(14)
            .contentShape(Rectangle())
            .onTapGesture { isChecked.toggle() }

            Divider().background(Color.mrxBorder)

            Button { showDoc = true } label: {
                HStack(spacing: 8) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 13))
                        .foregroundColor(.mrxBlue)
                    Text("Read \(document.title)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.mrxBlue)
                    Spacer()
                    Text(isChecked ? "Read ✓" : "Required")
                        .font(.system(size: 11))
                        .foregroundColor(isChecked ? .mrxGreen : .mrxTextMuted)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11))
                        .foregroundColor(.mrxTextMuted)
                }
                .padding(.horizontal, 14).padding(.vertical, 11)
            }
            .buttonStyle(.plain)
        }
        .background(Color.mrxCard)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isChecked ? Color.mrxBlue.opacity(0.45) : Color.mrxBorder, lineWidth: 1)
        )
        .sheet(isPresented: $showDoc) {
            LegalDocumentViewer(document: document, onRead: { isChecked = true })
        }
    }
}

// ============================================================
// MARK: - Legal Acceptance Screen
// ============================================================

struct LegalAcceptanceScreen: View {
    let isMinor:  Bool
    let userId:   String
    let onAccept: () -> Void

    @StateObject private var store = LegalStore.shared

    @State private var accepted: [String: Bool] = [:]
    @State private var parentName:  String = ""
    @State private var parentEmail: String = ""

    private var documents: [LegalDocument] { LegalDocuments.all(isMinor: isMinor) }

    private var checkedCount: Int { documents.filter { accepted[$0.id] == true }.count }

    private var allChecked: Bool { documents.allSatisfy { accepted[$0.id] == true } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {

                VStack(alignment: .leading, spacing: 8) {
                    Text("Before Using MatReturnRx")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    Text("Please review and accept the required agreements. MatReturnRx provides educational performance and recovery guidance and does not diagnose, treat, or replace medical care.")
                        .font(.system(size: 14))
                        .foregroundColor(.mrxTextSec)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("\(checkedCount) of \(documents.count) accepted")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(allChecked ? .mrxGreen : .mrxTextMuted)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.mrxBorder).frame(height: 5)
                            Capsule()
                                .fill(allChecked ? Color.mrxGreen : Color.mrxBlue)
                                .frame(
                                    width: documents.isEmpty ? 0
                                        : geo.size.width * CGFloat(checkedCount) / CGFloat(documents.count),
                                    height: 5
                                )
                                .animation(.easeInOut(duration: 0.3), value: checkedCount)
                        }
                    }
                    .frame(height: 5)
                }

                VStack(spacing: 10) {
                    ForEach(documents) { doc in
                        LegalCheckRow(
                            isChecked: Binding(
                                get: { accepted[doc.id] ?? false },
                                set: { accepted[doc.id] = $0 }
                            ),
                            document: doc
                        )
                    }
                }

                if isMinor {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("PARENT / GUARDIAN INFORMATION")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.mrxTextMuted)
                            .kerning(0.8)
                        MRXField(label: "Parent or guardian full name", text: $parentName,  type: .name)
                        MRXField(label: "Parent or guardian email",     text: $parentEmail, type: .email)
                    }
                    .padding(14)
                    .background(Color.mrxCard)
                    .cornerRadius(14)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.mrxBorder, lineWidth: 1))
                }

                MRXDisclaimerBox(text: D.core)

                VStack(spacing: 8) {
                    Button {
                        guard allChecked else { return }
                        guard !isMinor || (!parentName.isEmpty && !parentEmail.isEmpty) else { return }
                        store.acceptAll(
                            isMinor:     isMinor,
                            userId:      userId.isEmpty ? "pending" : userId,
                            role:        isMinor ? "parent" : "athlete",
                            parentName:  parentName.isEmpty  ? nil : parentName,
                            parentEmail: parentEmail.isEmpty ? nil : parentEmail
                        )
                        onAccept()
                    } label: {
                        Text(allChecked ? "I Accept and Continue →" : "Accept All Documents Above to Continue")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(allChecked ? .white : .mrxTextMuted)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(allChecked ? Color.mrxBlue : Color.mrxCard)
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(allChecked ? Color.clear : Color.mrxBorder, lineWidth: 1)
                            )
                    }
                    .disabled(!allChecked)

                    if !allChecked {
                        Text("Read each document and check all boxes to continue.")
                            .font(.system(size: 12))
                            .foregroundColor(.mrxTextMuted)
                            .multilineTextAlignment(.center)
                    }
                }

                Text("TOS v1.0  ·  Privacy v1.0  ·  Medical Disclaimer v1.0  ·  Assumption of Risk v1.0"
                     + (isMinor ? "  ·  Youth Waiver v1.0" : ""))
                    .font(.system(size: 10))
                    .foregroundColor(.mrxTextMuted)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 8)
            }
            .padding(20)
        }
        .background(Color.mrxBg.ignoresSafeArea())
    }
}

// ============================================================
// MARK: - Legal Status View
// ============================================================

struct LegalStatusView: View {
    let userId:  String
    let isMinor: Bool

    @StateObject private var store = LegalStore.shared
    @Environment(\.dismiss) var dismiss

    private var documents: [LegalDocument] { LegalDocuments.all(isMinor: isMinor) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    Text("Your legal acceptance records are stored securely and cannot be deleted.")
                        .font(.system(size: 13))
                        .foregroundColor(.mrxTextSec)
                        .padding(.horizontal, 20).padding(.top, 4)

                    VStack(spacing: 0) {
                        ForEach(Array(documents.enumerated()), id: \.element.id) { idx, doc in
                            let rec = store.records.first {
                                $0.documentKey == doc.id && $0.documentVersion == doc.version
                            }
                            HStack(spacing: 14) {
                                Image(systemName: rec != nil ? "checkmark.shield.fill" : "xmark.circle.fill")
                                    .foregroundColor(rec != nil ? .mrxGreen : .mrxDanger)
                                    .font(.system(size: 18))
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(doc.title)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white)
                                    if let rec = rec {
                                        Text("Accepted \(formattedDate(rec.acceptedAt))  ·  v\(rec.documentVersion)")
                                            .font(.system(size: 11))
                                            .foregroundColor(.mrxTextMuted)
                                    } else {
                                        Text("Not yet accepted")
                                            .font(.system(size: 11))
                                            .foregroundColor(.mrxDanger)
                                    }
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 16).padding(.vertical, 14)

                            if idx < documents.count - 1 {
                                Divider().background(Color.mrxDivider).padding(.leading, 48)
                            }
                        }
                    }
                    .background(Color.mrxCard)
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.mrxBorder, lineWidth: 1))
                    .padding(.horizontal, 20)

                    Text("Stored fields: user ID, document key, version, accepted timestamp, device ID, app version"
                         + (isMinor ? ", parent/guardian name and email" : "") + ".")
                        .font(.system(size: 11))
                        .foregroundColor(.mrxTextMuted)
                        .padding(.horizontal, 20).padding(.bottom, 8)
                }
                .padding(.vertical, 16)
            }
            .background(Color.mrxBg.ignoresSafeArea())
            .navigationTitle("Legal Documents")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.foregroundColor(.mrxBlue)
                }
            }
#elseif os(macOS)
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Done") { dismiss() }.foregroundColor(.mrxBlue)
                }
            }
#endif
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: date)
    }
}
