//
//  PersonalizedProgramViews.swift
//  MatReturnRx
//

import SwiftUI

// ============================================================
// MARK: - Model
// ============================================================

struct ExerciseRef: Codable {
    let moduleId: String
    let exerciseId: String
}

struct PersonalizedProgram: Codable {
    let bodyArea: String
    let painLevel: Int
    let goal: String
    let exerciseRefs: [ExerciseRef]
    let generatedAt: Date
}

// ============================================================
// MARK: - Service
// ============================================================

enum PersonalizedProgramService {

    private static let storageKey = "mrx_personalized_program"

    // MARK: Generate

    static func generate(bodyArea: String, painLevel: Int, goal: String) -> PersonalizedProgram {
        var refs: [ExerciseRef] = []

        // Mobility warmup — always leads
        let mobExercises = mrxModules.first(where: { $0.id == "mob" })?.exercises ?? []
        let warmupCount = painLevel >= 6 ? 1 : 2
        refs.append(contentsOf: mobExercises.prefix(warmupCount).map {
            ExerciseRef(moduleId: "mob", exerciseId: $0.id)
        })

        // Primary body area exercises — fewer for high pain
        let primaryId = primaryModuleId(for: bodyArea)
        if let primary = mrxModules.first(where: { $0.id == primaryId }) {
            let count = painLevel >= 6 ? 2 : painLevel >= 3 ? 3 : 4
            refs.append(contentsOf: primary.exercises.prefix(count).map {
                ExerciseRef(moduleId: primaryId, exerciseId: $0.id)
            })
        }

        // Goal-specific bonus exercises
        if goal == "Return to Sport" {
            let bonus = mrxModules.first(where: { $0.id == "rtm" })?.exercises.prefix(2) ?? []
            refs.append(contentsOf: bonus.map { ExerciseRef(moduleId: "rtm", exerciseId: $0.id) })
        }
        if goal == "Build Strength" && primaryId != "grp" {
            let bonus = mrxModules.first(where: { $0.id == "grp" })?.exercises.prefix(2) ?? []
            refs.append(contentsOf: bonus.map { ExerciseRef(moduleId: "grp", exerciseId: $0.id) })
        }

        return PersonalizedProgram(
            bodyArea: bodyArea,
            painLevel: painLevel,
            goal: goal,
            exerciseRefs: refs,
            generatedAt: Date()
        )
    }

    // MARK: Convert to MRXModule

    static func toModule(_ program: PersonalizedProgram) -> MRXModule {
        let exercises = program.exerciseRefs.compactMap { ref -> MRXExercise? in
            mrxModules
                .first(where: { $0.id == ref.moduleId })?
                .exercises.first(where: { $0.id == ref.exerciseId })
        }
        let count = exercises.count
        return MRXModule(
            id: "personalized",
            name: "My Program · \(program.bodyArea)",
            tagline: program.goal,
            durationMin: max(10, count * 3),
            durationMax: count * 5,
            color: color(for: program.bodyArea),
            isPro: true,
            evidencePanel: "This program was built for you based on your selected body area, current pain level (\(program.painLevel)/10), and goal. It uses evidence-informed exercises from the MatReturnRx library. Adjust based on how you feel. Stop and seek evaluation from a qualified healthcare professional if symptoms worsen.",
            exercises: exercises
        )
    }

    // MARK: Persistence

    static func save(_ program: PersonalizedProgram) {
        guard let data = try? JSONEncoder().encode(program) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    static func load() -> PersonalizedProgram? {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let program = try? JSONDecoder().decode(PersonalizedProgram.self, from: data)
        else { return nil }
        return program
    }

    // MARK: Helpers

    static func primaryModuleId(for bodyArea: String) -> String {
        switch bodyArea {
        case "Knee":          return "kne"
        case "Neck":          return "nec"
        case "Shoulder":      return "sho"
        case "Hip & Groin":   return "hip"
        case "Lower Back":    return "lbk"
        case "Performance":   return "grp"
        case "Return to Mat": return "rtm"
        default:              return "mob"
        }
    }

    static func color(for bodyArea: String) -> Color {
        switch bodyArea {
        case "Knee":          return .mrxOrange
        case "Neck":          return .mrxPurple
        case "Shoulder":      return .mrxTeal
        case "Hip & Groin":   return .mrxYellow
        case "Lower Back":    return Color(red: 0.4, green: 0.78, blue: 0.55)
        case "Performance":   return .mrxBlue
        case "Return to Mat": return .mrxDanger
        default:              return .mrxGreen
        }
    }
}

// ============================================================
// MARK: - Entry Card  (embedded in ModulesTab for Pro users)
// ============================================================

struct ProPersonalizedProgramCard: View {
    @EnvironmentObject var app: AppState
    @Binding var selectedModule: MRXModule?

    @State private var savedProgram: PersonalizedProgram? = PersonalizedProgramService.load()
    @State private var showBuilder = false

    private static let dateFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "star.fill")
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.electricOrange)
                Text("PRO · YOUR PERSONALIZED PROGRAM")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(AppTheme.electricOrange)
                    .kerning(0.7)
            }

            if let program = savedProgram {
                savedProgramCard(program)
            } else {
                noProgramCTA
            }
        }
        .sheet(isPresented: $showBuilder) {
            ProgramBuilderSheet { generated in
                PersonalizedProgramService.save(generated)
                savedProgram = generated
            }
            .environmentObject(app)
        }
    }

    @ViewBuilder
    private func savedProgramCard(_ program: PersonalizedProgram) -> some View {
        let module = PersonalizedProgramService.toModule(program)
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("My Program · \(program.bodyArea)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(module.color)
                    Text(program.goal)
                        .font(.system(size: 13))
                        .foregroundColor(.mrxTextSec)
                    Text("\(module.exerciseCount) exercises · \(module.durationMin)–\(module.durationMax) min · Built \(Self.dateFmt.string(from: program.generatedAt))")
                        .font(.system(size: 12))
                        .foregroundColor(.mrxTextMuted)
                }
                Spacer()
                Circle().fill(module.color).frame(width: 10, height: 10)
            }

            HStack(spacing: 10) {
                Button {
                    selectedModule = module
                } label: {
                    Text("Start Session →")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(module.color)
                        .cornerRadius(10)
                }
                Button { showBuilder = true } label: {
                    Text("Rebuild")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.mrxTextSec)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 18)
                        .background(Color.mrxCard)
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.mrxBorder, lineWidth: 1))
                }
            }
        }
        .padding(16)
        .background(module.color.opacity(0.07))
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(module.color.opacity(0.3), lineWidth: 1))
    }

    private var noProgramCTA: some View {
        VStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Not a template. Built for you.")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                Text("Tell us your body area, current pain level, and goal — we'll build a program from our exercise library tailored to where you are right now.")
                    .font(.system(size: 13))
                    .foregroundColor(.mrxTextSec)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)
            }
            Button { showBuilder = true } label: {
                HStack(spacing: 8) {
                    Image(systemName: "wand.and.stars")
                    Text("Build My Program →")
                }
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(AppTheme.electricOrange)
                .cornerRadius(12)
            }
        }
        .padding(16)
        .background(AppTheme.electricOrange.opacity(0.07))
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.electricOrange.opacity(0.3), lineWidth: 1))
    }
}

// ============================================================
// MARK: - Program Builder Sheet
// ============================================================

struct ProgramBuilderSheet: View {
    let onGenerate: (PersonalizedProgram) -> Void
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) var dismiss

    @State private var selectedArea: String? = nil
    @State private var painLevel: Double = 2
    @State private var selectedGoal: String? = nil
    @State private var generated: PersonalizedProgram? = nil
    @State private var selectedModule: MRXModule? = nil

    private let bodyAreas: [(name: String, icon: String)] = [
        ("Knee",          "figure.walk"),
        ("Neck",          "person.fill"),
        ("Shoulder",      "figure.arms.open"),
        ("Hip & Groin",   "figure.stand"),
        ("Lower Back",    "figure.run"),
        ("Performance",   "bolt.fill"),
        ("Return to Mat", "sportscourt.fill"),
        ("Mobility",      "arrow.triangle.2.circlepath"),
    ]

    private let goals = [
        "Reduce Pain & Recover",
        "Build Strength",
        "Improve Mobility",
        "Return to Sport",
    ]

    private var canGenerate: Bool { selectedArea != nil && selectedGoal != nil }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.mrxBg.ignoresSafeArea()
                if let prog = generated {
                    generatedPreview(prog)
                } else {
                    builderForm
                }
            }
#if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .navigationTitle(generated == nil ? "Build My Program" : "Your Program")
            .toolbar {
#if os(macOS)
                ToolbarItem(placement: .automatic) {
                    if generated != nil {
                        Button("← Rebuild") { generated = nil }
                            .foregroundColor(.mrxTextSec)
                    }
                }
                ToolbarItem(placement: .automatic) {
                    Button("Close") { dismiss() }
                        .foregroundColor(.mrxTextMuted)
                }
#else
                ToolbarItem(placement: .topBarLeading) {
                    if generated != nil {
                        Button("← Rebuild") { generated = nil }
                            .foregroundColor(.mrxTextSec)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundColor(.mrxTextMuted)
                }
#endif
            }
        }
        .sheet(item: $selectedModule) { mod in
            NavigationStack { ExerciseListScreen(module: mod) }
                .environmentObject(app)
        }
    }

    // MARK: Builder Form

    private var builderForm: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {

                // Body area picker
                VStack(alignment: .leading, spacing: 12) {
                    Text("What's your primary area?")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(bodyAreas, id: \.name) { area in
                            let selected = selectedArea == area.name
                            let areaColor = PersonalizedProgramService.color(for: area.name)
                            Button { selectedArea = area.name } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: area.icon)
                                        .font(.system(size: 14))
                                        .foregroundColor(selected ? .white : areaColor)
                                        .frame(width: 22)
                                    Text(area.name)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(selected ? .white : .mrxTextSec)
                                    Spacer()
                                }
                                .padding(12)
                                .background(selected ? areaColor : Color.mrxCard)
                                .cornerRadius(10)
                                .overlay(RoundedRectangle(cornerRadius: 10)
                                    .stroke(selected ? areaColor : Color.mrxBorder, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Pain level
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Current pain level")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        Spacer()
                        Text("\(Int(painLevel))/10")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(painLevel <= 3 ? .mrxGreen : painLevel <= 6 ? .mrxYellow : .mrxDanger)
                    }
                    Slider(value: $painLevel, in: 0...10, step: 1)
                        .accentColor(painLevel <= 3 ? .mrxGreen : painLevel <= 6 ? .mrxYellow : .mrxDanger)
                    if painLevel >= 6 {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.mrxYellow)
                            Text("High pain — your program will use gentle loading and fewer exercises.")
                                .font(.system(size: 12))
                                .foregroundColor(.mrxYellow)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(16)
                .background(Color.mrxCard)
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.mrxBorder, lineWidth: 1))

                // Goal picker
                VStack(alignment: .leading, spacing: 12) {
                    Text("What's your primary goal?")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(goals, id: \.self) { goal in
                            let selected = selectedGoal == goal
                            Button { selectedGoal = goal } label: {
                                Text(goal)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(selected ? .white : .mrxTextSec)
                                    .multilineTextAlignment(.center)
                                    .padding(14)
                                    .frame(maxWidth: .infinity)
                                    .background(selected ? AppTheme.fightRed : Color.mrxCard)
                                    .cornerRadius(10)
                                    .overlay(RoundedRectangle(cornerRadius: 10)
                                        .stroke(selected ? AppTheme.fightRed : Color.mrxBorder, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Generate CTA
                Button {
                    guard let area = selectedArea, let goal = selectedGoal else { return }
                    let prog = PersonalizedProgramService.generate(
                        bodyArea: area,
                        painLevel: Int(painLevel),
                        goal: goal
                    )
                    onGenerate(prog)
                    generated = prog
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "wand.and.stars")
                        Text("Generate My Program")
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(canGenerate ? .white : .mrxTextMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(canGenerate ? AppTheme.fightRed : Color.mrxCard)
                    .cornerRadius(14)
                    .overlay(RoundedRectangle(cornerRadius: 14)
                        .stroke(canGenerate ? Color.clear : Color.mrxBorder, lineWidth: 1))
                }
                .disabled(!canGenerate)

                MRXDisclaimerBox(text: D.short, compact: true)
            }
            .padding(20)
        }
    }

    // MARK: Generated Preview

    @ViewBuilder
    private func generatedPreview(_ program: PersonalizedProgram) -> some View {
        let module = PersonalizedProgramService.toModule(program)
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // Program header card
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Circle().fill(module.color).frame(width: 10, height: 10)
                        Text("My Program · \(program.bodyArea)")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(module.color)
                    }
                    Text(program.goal)
                        .font(.system(size: 14))
                        .foregroundColor(.mrxTextSec)
                    HStack(spacing: 16) {
                        Label("\(module.exerciseCount) exercises", systemImage: "list.bullet")
                        Label("\(module.durationMin)–\(module.durationMax) min", systemImage: "clock")
                    }
                    .font(.system(size: 12))
                    .foregroundColor(.mrxTextMuted)
                }
                .padding(16)
                .background(module.color.opacity(0.08))
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(module.color.opacity(0.3), lineWidth: 1))

                // Pain adaptation notice
                if program.painLevel > 0 {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.shield.fill").foregroundColor(.mrxGreen)
                        Text("Adapted for pain level \(program.painLevel)/10 — loading adjusted for where you are today.")
                            .font(.system(size: 13))
                            .foregroundColor(.mrxTextSec)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(12)
                    .background(Color.mrxGreen.opacity(0.08))
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.mrxGreen.opacity(0.3), lineWidth: 1))
                }

                // Exercise list
                Text("YOUR EXERCISES")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.mrxTextMuted)
                    .kerning(0.8)

                VStack(spacing: 0) {
                    ForEach(Array(module.exercises.enumerated()), id: \.element.id) { idx, ex in
                        HStack(spacing: 12) {
                            Text("\(idx + 1)")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(module.color)
                                .frame(width: 28, height: 28)
                                .background(module.color.opacity(0.15))
                                .clipShape(Circle())
                            VStack(alignment: .leading, spacing: 2) {
                                Text(ex.name)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.white)
                                Text("\(ex.sets) sets · \(ex.reps)")
                                    .font(.system(size: 12))
                                    .foregroundColor(.mrxTextMuted)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        if idx < module.exercises.count - 1 {
                            Divider().background(Color.mrxDivider).padding(.leading, 56)
                        }
                    }
                }
                .background(Color.mrxCard)
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.mrxBorder, lineWidth: 1))

                // CTAs
                VStack(spacing: 10) {
                    Button {
                        selectedModule = module
                    } label: {
                        Text("Start Session →")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(module.color)
                            .cornerRadius(14)
                    }

                    Button { generated = nil } label: {
                        Text("Rebuild Program")
                            .font(.system(size: 14))
                            .foregroundColor(.mrxTextMuted)
                    }
                }

                MRXDisclaimerBox(text: D.short, compact: true)
            }
            .padding(20)
        }
    }
}
