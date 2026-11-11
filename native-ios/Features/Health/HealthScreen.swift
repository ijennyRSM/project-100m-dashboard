import SwiftUI

struct HealthScreen: View {
    @EnvironmentObject private var health: HealthKitService
    @Environment(\.dynamicTypeSize) private var typeSize
    private var rings: some View {
        ForEach(WellnessMetric.allCases) { metric in
            NavigationLink { WellnessDetailScreen(metric: metric) } label: {
                HealthRing(metric: metric, state: .missing)
            }.buttonStyle(.plain)
        }
    }
    var body: some View {
        P100Screen {
            // First content in Health; never duplicated on Me.
            if typeSize.isAccessibilitySize {
                VStack(spacing: 16) { rings }
            } else {
                HStack(alignment: .top, spacing: 8) { rings }
            }
            StatusBanner(title: "ข้อมูลจริง แยกจากคะแนน", message: "วงแหวนยังไม่คำนวณคะแนนใน M0 ข้อมูลด้านล่างอ่านจาก Apple Health ที่คุณอนุญาตเท่านั้น")
            NavigationLink { HealthConnectionScreen() } label: {
                Label("การเชื่อมต่อ Apple Health", systemImage: "heart.text.square").frame(minHeight: 44)
            }.accessibilityIdentifier("health-connection")
            if let message = health.message {
                StatusBanner(title: "อ่านข้อมูลไม่สำเร็จ", message: message, symbol: "exclamationmark.circle")
            }
            if health.isLoading { ProgressView("กำลังอ่านข้อมูล…") }
            if let date = health.snapshot.lastRead {
                Text("อ่านล่าสุด \(date.formatted(date: .abbreviated, time: .shortened)) · ค่าที่แสดงอาจเป็นข้อมูลจากครั้งก่อน")
                    .font(.caption).foregroundStyle(.secondary)
            }
            if typeSize.isAccessibilitySize {
                VStack { heartMetrics }
            } else {
                HStack { heartMetrics }
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
        }.navigationTitle("Health")
    }
    @ViewBuilder private var heartMetrics: some View {
        MetricTile(title: "Resting HR", value: health.snapshot.restingHeartRateBPM.map { String(format: "%.0f", $0) } ?? "—", unit: "bpm · ล่าสุดที่อ่านได้")
        MetricTile(title: "HRV SDNN", value: health.snapshot.heartRateVariabilityMS.map { String(format: "%.0f", $0) } ?? "—", unit: "ms · ล่าสุดที่อ่านได้")
    }
}

struct SleepDataCard: View {
    @EnvironmentObject private var health: HealthKitService
    var body: some View {
        P100Card {
            SectionHeading(title: "การนอนล่าสุดที่อ่านได้")
            if let sleep = health.snapshot.lastSleep {
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
