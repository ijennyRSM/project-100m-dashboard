import Foundation
import HealthKit
import Combine

/// HealthKit-first integration. Apple Watch measurements reach HealthKit through Apple's own sync.
/// This service reads only the types the user authorizes, without a ZIP or a watch BLE hack.
///
/// MVP scope: foreground refresh + change observers. Background delivery will be added and tested
/// in a signed iOS build before we claim unattended cloud synchronization.
@MainActor
final class HealthKitService: ObservableObject {
    @Published private(set) var connection: HealthConnectionState = .notRequested
    @Published private(set) var snapshot: HealthSnapshot = .empty
    @Published private(set) var isLoading = false
    @Published private(set) var message: String?

    private let healthStore = HKHealthStore()
    private var observers: [HKObserverQuery] = []
    private let requestedKey = "project100m.healthkit.permissionRequested"

    var hasRequestedAccess: Bool { UserDefaults.standard.bool(forKey: requestedKey) }

    private var readTypes: Set<HKObjectType> {
        var types: [HKObjectType] = [
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis),
            HKObjectType.workoutType()
        ]
        let quantities: [HKQuantityTypeIdentifier] = [
            .restingHeartRate, .heartRateVariabilitySDNN, .heartRate, .stepCount
        ]
        types += quantities.compactMap { HKObjectType.quantityType(forIdentifier: $0) }
        return Set(types)
    }

    /// The app may call this on every launch. Do not reprompt before the user first opts in.
    func restoreOnLaunch() async {
        guard hasRequestedAccess else { return }
        guard HKHealthStore.isHealthDataAvailable() else {
            connection = .unavailable
            return
        }
        connection = .requested
        await refresh()
        startForegroundObservers()
    }

    func connect() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            connection = .unavailable
            message = "HealthKit ไม่พร้อมใช้งานบนอุปกรณ์นี้"
            return
        }
        do {
            // A successful request only means the prompt completed. Apple deliberately doesn't
            // reveal which read types were denied. Missing metrics must remain "no data".
            try await healthStore.requestAuthorization(toShare: [], read: readTypes)
            UserDefaults.standard.set(true, forKey: requestedKey)
            connection = .requested
            message = nil
            await refresh()
            startForegroundObservers()
        } catch {
            connection = .failed(error.localizedDescription)
            message = "ไม่สามารถขอสิทธิ์ Apple Health ได้: \(error.localizedDescription)"
        }
    }

    func refreshIfEnabled() async {
        guard hasRequestedAccess else { return }
        await refresh()
    }

    func refresh() async {
        guard HKHealthStore.isHealthDataAvailable(), !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let since = Calendar.current.date(byAdding: .day, value: -21, to: Date()) ?? Date()
            let rhrType = HKObjectType.quantityType(forIdentifier: .restingHeartRate)!
            let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
            let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)
            let workoutType = HKObjectType.workoutType()

            async let rhrSamples = fetchSamples(rhrType, since: since, limit: 128)
            async let hrvSamples = fetchSamples(hrvType, since: since, limit: 128)
            async let sleepSamples = fetchSamples(sleepType, since: since, limit: 10000)
            async let workoutSamples = fetchSamples(workoutType, since: since, limit: 200)

            let (rhr, hrv, sleep, workouts) = try await (
                rhrSamples, hrvSamples, sleepSamples, workoutSamples
            )
            let bpmUnit = HKUnit.count().unitDivided(by: .minute())
            let hrvUnit = HKUnit.secondUnit(with: .milli)

            let latestRHR = (rhr.first as? HKQuantitySample)?
                .quantity.doubleValue(for: bpmUnit)
            let latestHRV = (hrv.first as? HKQuantitySample)?
                .quantity.doubleValue(for: hrvUnit)
            let workoutItems: [WorkoutPreview] = workouts.compactMap { item in
                guard let workout = item as? HKWorkout else { return nil }
                let label: String
                switch workout.workoutActivityType {
                case .running: label = "Running"
                case .walking: label = "Walking"
                case .functionalStrengthTraining, .traditionalStrengthTraining:
                    label = "Strength"
                default: label = "Workout"
                }
                return WorkoutPreview(
                    id: workout.uuid,
                    date: workout.startDate,
                    kind: label,
                    durationMinutes: workout.duration / 60,
                    distanceKilometers: workout.totalDistance?
                        .doubleValue(for: .meter()).map { $0 / 1000 }
                )
            }

            snapshot = HealthSnapshot(
                lastRead: Date(),
                restingHeartRateBPM: latestRHR,
                heartRateVariabilityMS: latestHRV,
                lastSleep: Self.latestSleepNight(sleep.compactMap { $0 as? HKCategorySample }),
                recentWorkouts: workoutItems
            )
            message = nil
        } catch {
            message = "อ่านข้อมูลสุขภาพไม่สำเร็จ: \(error.localizedDescription)"
        }
    }

    /// Query samples within a bounded recent window. HealthKit returns samples from newest to oldest.
    private func fetchSamples(
        _ type: HKSampleType, since: Date, limit: Int
    ) async throws -> [HKSample] {
        try await withCheckedThrowingContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(
                withStart: since, end: Date(), options: []
            )
            let sort = NSSortDescriptor(
                key: HKSampleSortIdentifierEndDate, ascending: false
            )
            let query = HKSampleQuery(
                sampleType: type, predicate: predicate, limit: limit,
                sortDescriptors: [sort]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: samples ?? [])
                }
            }
            healthStore.execute(query)
        }
    }

    private func startForegroundObservers() {
        guard observers.isEmpty else { return }
        for type in readTypes.compactMap({ $0 as? HKSampleType }) {
            let observer = HKObserverQuery(sampleType: type, predicate: nil) {
                [weak self] _, completion, error in
                guard error == nil else {
                    completion()
                    return
                }
                Task { @MainActor [weak self] in
                    await self?.refreshIfEnabled()
                    completion()
                }
            }
            observers.append(observer)
            healthStore.execute(observer)
        }
    }

    /// A sleep "night" spans midnight. Shift the grouping boundary to local noon.
    /// Prefer one source per night to avoid double-counting parallel iPhone/Watch/apps.
    private static func latestSleepNight(
        _ samples: [HKCategorySample]
    ) -> SleepNight? {
        let asleep = samples.filter { sleepStage($0) != nil }
        guard !asleep.isEmpty else { return nil }

        func nightKey(_ sample: HKCategorySample) -> Date {
            Calendar.current.startOfDay(
                for: sample.endDate.addingTimeInterval(-12 * 3600)
            )
        }

        let nights = Dictionary(grouping: asleep, by: nightKey)
        guard let latest = nights.keys.max(), let nightSamples = nights[latest] else {
            return nil
        }
        let sources = Dictionary(
            grouping: nightSamples,
            by: { $0.sourceRevision.source.bundleIdentifier }
        )
        guard let best = sources.max(by: {
            unionSeconds($0.value) < unionSeconds($1.value)
        })?.value else { return nil }

        func hours(for stage: String) -> Double {
            unionSeconds(best.filter { sleepStage($0) == stage }) / 3600
        }
        return SleepNight(
            nightDate: latest,
            asleepHours: unionSeconds(best) / 3600,
            coreHours: hours(for: "core"),
            deepHours: hours(for: "deep"),
            remHours: hours(for: "rem"),
            unknownHours: hours(for: "unspecified")
        )
    }

    private static func sleepStage(_ sample: HKCategorySample) -> String? {
        guard let value = HKCategoryValueSleepAnalysis(rawValue: sample.value) else {
            return nil
        }
        switch value {
        case .asleepCore: return "core"
        case .asleepDeep: return "deep"
        case .asleepREM: return "rem"
        case .asleepUnspecified, .asleep: return "unspecified"
        default: return nil
        }
    }

    private static func unionSeconds(_ samples: [HKCategorySample]) -> Double {
        let sorted = samples.sorted { $0.startDate < $1.startDate }
        guard let first = sorted.first else { return 0 }
        var currentStart = first.startDate
        var currentEnd = first.endDate
        var seconds = 0.0
        for item in sorted.dropFirst() {
            if item.startDate <= currentEnd {
                currentEnd = max(currentEnd, item.endDate)
            } else {
                seconds += currentEnd.timeIntervalSince(currentStart)
                currentStart = item.startDate
                currentEnd = item.endDate
            }
        }
        return seconds + currentEnd.timeIntervalSince(currentStart)
    }
}
