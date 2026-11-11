import SwiftUI

struct HealthScreen: View {
    @EnvironmentObject private var health: HealthKitService
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.colorScheme) private var colorScheme
    @ScaledMetric(relativeTo: .title2) private var ringDiameter: CGFloat = 88
    @ScaledMetric(relativeTo: .body) private var tileWidth: CGFloat = 150

    private func ringLink(_ metric: WellnessMetric) -> some View {
        NavigationLink { WellnessDetailScreen(metric: metric) } label: {
            HealthRing(metric: metric, state: .missing)
        }.buttonStyle(.plain)
    }
    private var presentation: String {
        let size = typeSize == .accessibility5 ? "AX5" : typeSize == .xLarge ? "xLarge" : "large"
        return "\(colorScheme == .dark ? "dark" : "light")|\(size)"
    }
    var body: some View {
        P100Screen {
            // Width, including scaled ring geometry, decides the layout on every text size.
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 8) {
                    ForEach(WellnessMetric.allCases) { ringLink($0).frame(width: min(160, ringDiameter) + 16) }
                }.fixedSize(horizontal: true, vertical: false)
                VStack(spacing: 16) { ForEach(WellnessMetric.allCases) { ringLink($0) } }
            }
            StatusBanner(title: "ข้อมูลจริง แยกจากคะแนน", message: "วงแหวนยังไม่คำนวณคะแนน ข้อมูลด้านล่างอ่านจาก Apple Health ที่คุณอนุญาตเท่านั้น")
                .accessibilityIdentifier("health-presentation")
                .accessibilityValue(UITestConfiguration.enabled ? presentation : "")
            if UITestConfiguration.enabled {
                StatusBanner(title: "ข้อมูลทดสอบ UI เท่านั้น", message: "ไม่อ่าน HealthKit และไม่ใช่ข้อมูลสุขภาพจริง")
            }
            connectionContent
        }
        .accessibilityIdentifier("health-content")
        .frame(width: UITestConfiguration.healthWidth)
        .frame(maxWidth: .infinity)
        .background(P100Theme.canvas)
        .navigationTitle("Health")
    }
    @ViewBuilder private var connectionContent: some View {
        switch health.connection {
        case .notRequested:
            P100Card {
                SectionHeading(title: "เริ่มเชื่อมต่อ Apple Health")
                Text("ยังไม่ได้ขอสิทธิ์อ่านข้อมูล คุณเลือกประเภทข้อมูลที่อนุญาตได้เอง").foregroundStyle(.secondary)
                connectionLink("เชื่อมต่อ Apple Health")
            }.accessibilityIdentifier("health-state-notRequested")
        case .unavailable:
            StatusBanner(title: "HealthKit ไม่พร้อมใช้งาน", message: "อุปกรณ์นี้ไม่รองรับการอ่าน Apple Health ข้อมูลจึงยังไม่พร้อม", symbol: "heart.slash")
                .accessibilityIdentifier("health-state-unavailable")
        case .failed(let reason):
            P100Card {
                SectionHeading(title: "Apple Health มีปัญหา")
                Text(reason).foregroundStyle(.secondary)
                connectionLink("ตรวจสอบการเชื่อมต่อ")
            }.accessibilityIdentifier("health-state-failed")
        case .requested:
            connectionLink("การเชื่อมต่อ Apple Health")
            if health.isLoading {
                ProgressView("กำลังอ่านข้อมูล…").accessibilityIdentifier("health-state-loading")
            } else {
                if let date = health.snapshot.lastRead {
                    Text("เวลาอ่านข้อมูล \(date.formatted(date: .abbreviated, time: .shortened)) · ไม่ใช่เวลาที่วัด")
                        .font(.caption).foregroundStyle(.secondary).accessibilityIdentifier("health-read-time")
                }
                if health.snapshot.restingHeartRateBPM == nil && health.snapshot.heartRateVariabilityMS == nil && health.snapshot.lastSleep == nil && health.snapshot.recentWorkouts.isEmpty {
                    StatusBanner(title: "ยังไม่พบข้อมูลที่อ่านได้", message: "อาจยังไม่มีข้อมูลหรือไม่ได้อนุญาต แอปแยกสองกรณีนี้ไม่ได้")
                        .accessibilityIdentifier("health-state-missing")
                }
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: 16) {
                        heartMetric("rhr").frame(width: min(300, tileWidth))
                        heartMetric("hrv").frame(width: min(300, tileWidth))
                    }.fixedSize(horizontal: true, vertical: false)
                    VStack(spacing: 16) { heartMetric("rhr"); heartMetric("hrv") }
                }
                SleepDataCard()
                P100Card {
                    SectionHeading(title: "กิจกรรมที่อ่านได้", subtitle: "21 วันล่าสุด · ไม่ใช่หลักฐานว่าทำ Session ตามแผนครบ")
                    if health.snapshot.recentWorkouts.isEmpty { Text("ยังไม่พบ Workout ที่แอปอ่านได้").foregroundStyle(.secondary) }
                    ForEach(health.snapshot.recentWorkouts.prefix(8)) { workout in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(workout.kind).font(.headline)
                            Text(workout.date.formatted(date: .abbreviated, time: .shortened)).font(.caption).foregroundStyle(.secondary)
                            Text("\(Int(workout.durationMinutes)) นาที")
                            if let distance = workout.distanceKilometers {
                                Text("\(distance.formatted(.number.precision(.fractionLength(2)))) km").font(.subheadline)
                            }
                        }
                        Divider()
                    }
                }
            }
        }
    }
    private func connectionLink(_ title: String) -> some View {
        NavigationLink { HealthConnectionScreen() } label: {
            Label(title, systemImage: "heart.text.square").frame(minHeight: 44)
        }.accessibilityIdentifier("health-connection")
    }
    private func heartMetric(_ id: String) -> some View {
        MetricTile(title: id == "rhr" ? "Resting HR" : "HRV SDNN",
                   value: (id == "rhr" ? health.snapshot.restingHeartRateBPM : health.snapshot.heartRateVariabilityMS).map { String(format: "%.0f", $0) } ?? "—",
                   unit: id == "rhr" ? "bpm" : "ms",
                   measuredAt: id == "rhr" ? health.snapshot.restingHeartRateDate : health.snapshot.heartRateVariabilityDate,
                   metricID: id)
    }
}

struct SleepDataCard: View {
    @EnvironmentObject private var health: HealthKitService
    var body: some View {
        P100Card {
            SectionHeading(title: "การนอนล่าสุดที่อ่านได้")
            if health.connection == .notRequested {
                Text("ยังไม่ได้ขอสิทธิ์อ่าน Apple Health").foregroundStyle(.secondary)
            } else if health.connection == .unavailable {
                Text("HealthKit ไม่พร้อมใช้งานบนอุปกรณ์นี้").foregroundStyle(.secondary)
            } else if case .failed = health.connection {
                Text("ยังอ่านข้อมูลการนอนไม่สำเร็จ ตรวจสอบการเชื่อมต่อ Apple Health").foregroundStyle(.secondary)
            } else if let sleep = health.snapshot.lastSleep {
                Text(sleep.nightDate.formatted(date: .abbreviated, time: .omitted)).font(.caption).foregroundStyle(.secondary)
                Text("\(sleep.asleepHours.formatted(.number.precision(.fractionLength(1)))) ชั่วโมง").font(.title.bold())
                stage("Core", sleep.coreHours)
                stage("Deep", sleep.deepHours)
                stage("REM", sleep.remHours)
                stage("ไม่ระบุระยะ", sleep.unknownHours)
                Text("ใช้แหล่งข้อมูลเดียวต่อคืนเพื่อลดการนับซ้ำ ระยะการนอนเป็นค่าประเมิน และอาจซ้อนกันได้ ยังไม่แสดงแหล่งข้อมูลรายรายการในรุ่นนี้")
                    .font(.caption).foregroundStyle(.secondary)
            } else {
                Text("ยังไม่พบข้อมูลการนอนที่แอปอ่านได้").foregroundStyle(.secondary)
                Text("อาจยังไม่มีข้อมูลหรือไม่ได้อนุญาต แอปแยกสองกรณีนี้ไม่ได้").font(.caption).foregroundStyle(.secondary)
            }
        }
    }
    private func stage(_ name: String, _ hours: Double) -> some View {
        LabeledContent(name, value: "\(hours.formatted(.number.precision(.fractionLength(1)))) ชม.").font(.subheadline)
    }
}

struct WellnessDetailScreen: View {
    let metric: WellnessMetric
    var body: some View {
        P100Screen {
            StatusBanner(title: "\(metric.rawValue) · ยังไม่มีคะแนน", message: "กำลังพัฒนาโมเดลต้นฉบับที่อธิบายได้ ยังไม่ใช่คะแนนที่ผ่านการตรวจสอบทางการแพทย์")
            if metric == .sleep { SleepDataCard() }
            P100Card {
                SectionHeading(title: "ข้อมูลที่ต้องใช้")
                switch metric {
                case .sleep: Text("เวลานอน ความสม่ำเสมอ และประสิทธิภาพเมื่อมีข้อมูล In Bed ที่เชื่อถือได้")
                case .recovery: Text("HRV และ Resting HR เทียบฐานส่วนตัว การนอน และความล้าหรือปวดเมื่อยที่คุณบันทึก")
                case .strain: Text("โซนหัวใจ ระยะเวลา ความหนัก ภาระฝึกที่ผ่านมา RPE และพื้นฐานความฟิตของคุณ")
                }
                Text("ยังไม่คำนวณคะแนนหรือเติมค่าที่ขาด แผนฝึกจะไม่ถูกปรับโดยอัตโนมัติ").font(.subheadline).foregroundStyle(.secondary)
            }
        }.navigationTitle(metric.rawValue).navigationBarTitleDisplayMode(.inline)
    }
}
