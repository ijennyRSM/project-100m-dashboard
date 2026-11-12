import Foundation

/// Display model assembled from the HealthKit data already available on the iPhone.
/// The MVP does not upload any health records to Supabase.
struct HealthSnapshot {
    var lastRead: Date?
    var restingHeartRateBPM: Double?
    var restingHeartRateDate: Date?
    var heartRateVariabilityMS: Double?
    var heartRateVariabilityDate: Date?
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

    var title: String {
        switch self {
        case .notRequested: return "ยังไม่ได้ขอสิทธิ์"
        case .requested: return "เคยขอสิทธิ์แล้ว · ไม่ยืนยันการอ่าน"
        case .unavailable: return "HealthKit ไม่พร้อมใช้งาน"
        case .failed: return "มีข้อผิดพลาด"
        }
    }
}
