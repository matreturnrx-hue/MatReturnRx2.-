//
//  MRXProgressTracking.swift
//  MatReturnRx 2.0
//
//  Unified progress tracking service with cloud sync
//

import Foundation
import Combine

// ============================================================
// MARK: - Progress Entry Model (Local)
// ============================================================

struct MRXReadinessEntry: Identifiable, Codable {
    let id: UUID
    let userId: String
    let timestamp: Date
    let readinessScore: Double
    let trafficLightStatus: String  // "green", "yellow", "red"
    let sleep: Double
    let soreness: Double
    let stress: Double
    let pain: Double
    
    init(
        id: UUID = UUID(),
        userId: String,
        timestamp: Date = Date(),
        readinessScore: Double,
        status: TrafficLight,
        sleep: Double,
        soreness: Double,
        stress: Double,
        pain: Double
    ) {
        self.id = id
        self.userId = userId
        self.timestamp = timestamp
        self.readinessScore = readinessScore
        self.trafficLightStatus = status.rawValue
        self.sleep = sleep
        self.soreness = soreness
        self.stress = stress
        self.pain = pain
    }
    
    var status: TrafficLight {
        TrafficLight(rawValue: trafficLightStatus) ?? .green
    }
}

// ============================================================
// MARK: - Cloud Progress Entry Model
// ============================================================

struct MRXCloudProgressEntry: Codable, Identifiable {
    let id: String
    let userId: String
    let date: Date
    let entryType: String
    let readinessScore: Double
    let trafficLight: String
    let sleepQuality: Double
    let sorenessLevel: Double
    let stressLevel: Double
    let painLevel: Double
    let moduleName: String?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId         = "user_id"
        case date
        case entryType      = "entry_type"
        case readinessScore = "readiness_score"
        case trafficLight   = "traffic_light"
        case sleepQuality   = "sleep_quality"
        case sorenessLevel  = "soreness_level"
        case stressLevel    = "stress_level"
        case painLevel      = "pain_level"
        case moduleName     = "module_name"
        case createdAt      = "created_at"
    }
}

// ============================================================
// MARK: - Entry Conversion Extensions
// ============================================================

extension MRXReadinessEntry {
    /// Converts local entry to cloud format for syncing
    func toCloudEntry() -> MRXCloudProgressEntry {
        return MRXCloudProgressEntry(
            id: self.id.uuidString,
            userId: self.userId,
            date: self.timestamp,
            entryType: "readiness",
            readinessScore: self.readinessScore,
            trafficLight: self.trafficLightStatus,
            sleepQuality: self.sleep,
            sorenessLevel: self.soreness,
            stressLevel: self.stress,
            painLevel: self.pain,
            moduleName: nil,
            createdAt: self.timestamp
        )
    }
    
    /// Initialize from cloud entry
    init(fromCloud cloudEntry: MRXCloudProgressEntry) {
        self.id = UUID(uuidString: cloudEntry.id) ?? UUID()
        self.userId = cloudEntry.userId
        self.timestamp = cloudEntry.date
        self.readinessScore = cloudEntry.readinessScore
        self.trafficLightStatus = cloudEntry.trafficLight
        self.sleep = cloudEntry.sleepQuality
        self.soreness = cloudEntry.sorenessLevel
        self.stress = cloudEntry.stressLevel
        self.pain = cloudEntry.painLevel
    }
}

// ============================================================
// MARK: - Progress Tracking Service (MatReturnRx 2.0)
// ============================================================

@MainActor
final class MRXProgressTracker: ObservableObject {
    static let shared = MRXProgressTracker()
    
    @Published private(set) var allEntries: [MRXReadinessEntry] = []
    
    // UserDefaults keys
    private let entriesKey = "mrx2_progress_entries"
    private let lastSessionKey = "mrx2_last_session_date"
    private let streakKey = "mrx2_streak"
    
    private init() {
        loadEntries()
    }
    
    // MARK: - Add Readiness Entry
    
    /// Adds a readiness check entry with AppState integration
    func addReadinessEntry(
        userId: String,
        score: Double,
        status: TrafficLight,
        sleep: Double,
        soreness: Double,
        stress: Double,
        pain: Double,
        appState: AppState
    ) {
        let entry = MRXReadinessEntry(
            userId: userId,
            readinessScore: score,
            status: status,
            sleep: sleep,
            soreness: soreness,
            stress: stress,
            pain: pain
        )
        
        allEntries.append(entry)
        saveEntries()
        updateStreak()
        refreshAppStateStats(appState)
        
        // Sync to cloud if configured
        Task {
            await syncEntryToCloud(entry)
        }
    }
    
    /// Adds a readiness check entry without AppState
    func addReadinessEntry(
        userId: String,
        score: Double,
        status: TrafficLight,
        sleep: Double,
        soreness: Double,
        stress: Double,
        pain: Double
    ) {
        let entry = MRXReadinessEntry(
            userId: userId,
            readinessScore: score,
            status: status,
            sleep: sleep,
            soreness: soreness,
            stress: stress,
            pain: pain
        )
        
        allEntries.append(entry)
        saveEntries()
        updateStreak()
        
        // Sync to cloud if configured
        Task {
            await syncEntryToCloud(entry)
        }
    }
    
    // MARK: - Add Session Entry
    
    /// Records a module session with full details
    func addSessionEntry(userId: String, moduleName: String, pain: Double, appState: AppState) {
        updateStreak()
        refreshAppStateStats(appState)
        // Could be extended to log module-specific session data if needed
    }
    
    /// Records a session with basic details
    func addSessionEntry(userId: String, appState: AppState) {
        updateStreak()
        refreshAppStateStats(appState)
    }
    
    /// Records a session (minimal)
    func addSessionEntry(userId: String) {
        updateStreak()
    }
    
    // MARK: - Refresh AppState Stats
    
    private func refreshAppStateStats(_ appState: AppState) {
        appState.streak = currentStreak()
        appState.weekSessions = weekSessionsCount()
    }
    
    // MARK: - Readiness Entries by Period
    
    /// Returns readiness entries for a specific time period
    /// - Parameter period: 0 = Week, 1 = Month, 2 = 3 Months
    func readinessEntries(period: Int) -> [MRXReadinessEntry] {
        let now = Date()
        let calendar = Calendar.current
        
        let cutoffDate: Date
        switch period {
        case 0: // Week
            cutoffDate = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case 1: // Month
            cutoffDate = calendar.date(byAdding: .day, value: -30, to: now) ?? now
        case 2: // 3 Months
            cutoffDate = calendar.date(byAdding: .day, value: -90, to: now) ?? now
        default:
            cutoffDate = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        }
        
        return allEntries.filter { $0.timestamp >= cutoffDate }
            .sorted { $0.timestamp < $1.timestamp }
    }
    
    // MARK: - Average Readiness
    
    /// Calculates average readiness score for a period
    func averageReadiness(period: Int) -> Double? {
        let entries = readinessEntries(period: period)
        guard !entries.isEmpty else { return nil }
        
        let sum = entries.reduce(0.0) { $0 + $1.readinessScore }
        return sum / Double(entries.count)
    }
    
    // MARK: - Streak Calculation
    
    /// Returns the current training streak
    func currentStreak() -> Int {
        UserDefaults.standard.integer(forKey: streakKey)
    }
    
    /// Updates the training streak based on current date
    private func updateStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        if let lastSessionString = UserDefaults.standard.string(forKey: lastSessionKey),
           let lastSessionDate = ISO8601DateFormatter().date(from: lastSessionString) {
            let lastSession = calendar.startOfDay(for: lastSessionDate)
            let daysBetween = calendar.dateComponents([.day], from: lastSession, to: today).day ?? 0
            
            if daysBetween == 0 {
                // Same day, don't update streak
                return
            } else if daysBetween == 1 {
                // Consecutive day, increment streak
                let newStreak = currentStreak() + 1
                UserDefaults.standard.set(newStreak, forKey: streakKey)
            } else {
                // Streak broken, reset to 1
                UserDefaults.standard.set(1, forKey: streakKey)
            }
        } else {
            // First session ever
            UserDefaults.standard.set(1, forKey: streakKey)
        }
        
        // Update last session date
        let todayString = ISO8601DateFormatter().string(from: Date())
        UserDefaults.standard.set(todayString, forKey: lastSessionKey)
    }
    
    // MARK: - Week Sessions Count
    
    /// Returns count of unique training days in the last week
    func weekSessionsCount() -> Int {
        let calendar = Calendar.current
        let now = Date()
        guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) else { return 0 }
        
        let weekEntries = allEntries.filter { $0.timestamp >= weekAgo }
        
        // Group by day to count unique days
        let uniqueDays = Set(weekEntries.map { calendar.startOfDay(for: $0.timestamp) })
        return uniqueDays.count
    }
    
    // MARK: - Persistence
    
    private func loadEntries() {
        guard let data = UserDefaults.standard.data(forKey: entriesKey) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let decoded = try? decoder.decode([MRXReadinessEntry].self, from: data) else {
            return
        }
        allEntries = decoded
    }
    
    private func saveEntries() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let encoded = try? encoder.encode(allEntries) else { return }
        UserDefaults.standard.set(encoded, forKey: entriesKey)
    }
    
    // MARK: - Cloud Sync
    
    /// Syncs a single entry to the cloud
    private func syncEntryToCloud(_ entry: MRXReadinessEntry) async {
        do {
            try await AmplifyAPIManager.shared.syncProgress(entry.toCloudEntry())
        } catch {
            print("[MRXProgressTracker] Failed to sync entry: \(error.localizedDescription)")
        }
    }
    
    /// Loads progress entries from cloud on login
    func syncFromCloud(userId: String) async {
        do {
            guard let cloudEntries = try await AmplifyAPIManager.shared.fetchProgress(userId: userId) else {
                return
            }
            
            await MainActor.run {
                // Merge cloud entries with local, preferring cloud
                let localIds = Set(allEntries.map { $0.id.uuidString })
                let converted = cloudEntries.map { MRXReadinessEntry(fromCloud: $0) }
                let newCloudEntries = converted.filter { !localIds.contains($0.id.uuidString) }
                allEntries.append(contentsOf: newCloudEntries)
                allEntries.sort { $0.timestamp < $1.timestamp }
                saveEntries()
            }
        } catch {
            print("[MRXProgressTracker] Failed to sync from cloud: \(error.localizedDescription)")
        }
    }
}
