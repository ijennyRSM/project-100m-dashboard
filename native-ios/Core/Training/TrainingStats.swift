import Foundation

/// One calendar week of self-reported training, derived only from recorded attempts.
struct WeekSummary: Hashable, Identifiable {
    var weekStart: Date
    var sessions: Int
    var minutes: Int
    var id: Date { weekStart }
}

/// Profile/feed statistics computed from real history. Weeks are calendar weeks used only for
/// display; they never influence plan progression. Skipped attempts are not counted as training.
enum TrainingStats {
    static func weekStart(_ date: Date, calendar: Calendar) -> Date {
        calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? calendar.startOfDay(for: date)
    }

    /// The last `count` weeks, oldest first, including the current week (zero-filled).
    static func weekly(_ attempts: [SessionAttempt], now: Date = Date(), count: Int = 12,
                       calendar: Calendar = .current) -> [WeekSummary] {
        let current = weekStart(now, calendar: calendar)
        var weeks: [Date] = []
        for offset in stride(from: count - 1, through: 0, by: -1) {
            if let start = calendar.date(byAdding: .weekOfYear, value: -offset, to: current) { weeks.append(start) }
        }
        var sessions: [Date: Int] = [:], minutes: [Date: Int] = [:]
        for attempt in attempts where attempt.status != .skipped {
            let start = weekStart(attempt.at, calendar: calendar)
            sessions[start, default: 0] += 1
            minutes[start, default: 0] += attempt.duration ?? 0
        }
        return weeks.map { WeekSummary(weekStart: $0, sessions: sessions[$0] ?? 0, minutes: minutes[$0] ?? 0) }
    }

    /// Consecutive weeks with at least one Completed or Partial attempt, ending this week, or
    /// last week when this week has none yet (the streak is still alive).
    static func weekStreak(_ attempts: [SessionAttempt], now: Date = Date(), calendar: Calendar = .current) -> Int {
        let active = Set(attempts.filter { $0.status != .skipped }.map { weekStart($0.at, calendar: calendar) })
        var cursor = weekStart(now, calendar: calendar)
        if !active.contains(cursor), let previous = calendar.date(byAdding: .weekOfYear, value: -1, to: cursor) {
            cursor = previous
        }
        var streak = 0
        while active.contains(cursor) {
            streak += 1
            guard let previous = calendar.date(byAdding: .weekOfYear, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return streak
    }
}
