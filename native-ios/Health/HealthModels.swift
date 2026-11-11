import Foundation

/// Display model assembled from the HealthKit data already available on the iPhone.
/// The MVP does not upload any health records to Supabase.
struct HealthSnapshot {
    var lastRead: Date?
    var restingHeartRateBPM: Double?
    var heartRateVariabilityMS: Double?
    var lastSleep: SleepNight?
    var recentWorkouts: [WorkoutPreview] = []

    static let empty = HealthSnapshot()
}

struct SleepNight {
    let nightDate: Date
    let asleepHours: Double
    let coreHours: Double
    let deepHours: Double
    let remHours: Double
    let unknownHours: Double

    var stageTotalHours: Double { coreHours + deepHours + remHours + unknownHours }
}

struct WorkoutPreview: Identifiable {
    let id: UUID
    let date: Date
    let kind: String
    let durationMinutes: Double
    let distanceKilometers: Double?
}

enum HealthConnectionState: Equatable {
    case notRequested
    case requested
    case unavailable
    case failed(String)
}
