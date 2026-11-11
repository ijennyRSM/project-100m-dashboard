import SwiftUI

private enum P100Style {
    static let forest = Color(red: 0.16, green: 0.40, blue: 0.32)
    static let mint = Color(red: 0.89, green: 0.95, blue: 0.89)
    static let canvas = Color(red: 0.97, green: 0.98, blue: 0.96)
    static let secondary = Color(red: 0.41, green: 0.49, blue: 0.44)
}

struct RootView: View {
    var body: some View {
        TabView {
            NavigationStack { TodayScreen() }
                .tabItem { Label("วันนี้", systemImage: "house.fill") }
            NavigationStack { HealthScreen() }
                .tabItem { Label("สุขภาพ", systemImage: "heart.text.square") }
            NavigationStack { TrainingScreen() }
                .tabItem { Label("แผนฝึก", systemImage: "figure.run") }
            NavigationStack { AccountScreen() }
                .tabItem { Label("บัญชี", systemImage: "person.crop.circle") }
        }
        .tint(P100Style.forest)
    }
}

struct TodayScreen: View {
    @EnvironmentObject private var health: HealthKitService

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 7) {
                    Text("MOVE AT YOUR PACE")
                        .font(.caption2.weight(.bold)).tracking(1.6)
                        .foregroundStyle(P100Style.forest)
                    Text("พร้อมสำหรับก้าวต่อไปหรือยัง?")
                        .font(.system(size: 29, weight: .bold, design: .rounded))
                    Text("ดูการฝึกและการพักฟื้นในที่เดียว")
                        .foregroundStyle(P100Style.secondary)
                }
                .padding(.vertical, 12)

                if !health.hasRequestedAccess {
                    ConnectCard()
                } else {
                    sourceNotice
                }

                HStack(spacing: 12) {
                    MetricTile(
                        icon: "heart.fill", label: "Resting HR",
                        number: health.snapshot.restingHeartRateBPM
                            .map { String(format: "%.0f", $0) } ?? "—",
                        unit: "bpm"
                    )
                    MetricTile(
                        icon: "waveform.path.ecg", label: "HRV (SDNN)",
                        number: health.snapshot.heartRateVariabilityMS
                            .map { String(format: "%.0f", $0) } ?? "—",
                        unit: "ms"
                    )
                }

                VStack(alignment: .leading, spacing: 13) {
                    Label("การนอนล่าสุด", systemImage: "moon.zzz.fill")
                        .font(.headline)
                        .foregroundStyle(P100Style.forest)
                    if let sleep = health.snapshot.lastSleep {
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text(sleep.asleepHours, format: .number.precision(.fractionLength(1)))
                                .font(.system(size: 42, weight: .bold, design: .rounded))
                            Text("ชั่วโมง")
                                .foregroundStyle(P100Style.secondary)
                        }
                        Text("วัดจากช่วงการนอนที่มีข้อมูล ไม่ใช่คะแนน WHOOP")
                            .font(.caption)
                            .foregroundStyle(P100Style.secondary)
                    } else {
                        Text("ยังไม่พบข้อมูลการนอนที่อนุญาตให้แอปอ่าน")
                            .font(.subheadline)
                            .foregroundStyle(P100Style.secondary)
                    }
                }
                .p100Card()

                VStack(alignment: .leading, spacing: 12) {
                    Label("Training Journey", systemImage: "figure.run.circle.fill")
                        .font(.headline)
                        .foregroundStyle(P100Style.forest)
                    Text("โปรแกรม 100M Comeback ของคุณยังอยู่บนเว็บไซต์เดิม เราจะย้ายแผนฝึกเข้ามาใน Native App ใน Milestone ถัดไป")
                        .font(.subheadline)
                        .foregroundStyle(P100Style.secondary)
                    Link(destination: URL(string: "https://ijennyrsm.github.io/project-100m-dashboard/")!) {
                        Label("เปิด Training Plan เดิม", systemImage: "arrow.up.right")
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(13)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(P100Style.forest)
                }
                .p100Card()
            }
            .padding(18)
        }
        .background(P100Style.canvas)
        .navigationTitle("PROJECT 100M")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var sourceNotice: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.shield.fill")
                .foregroundStyle(P100Style.forest)
            VStack(alignment: .leading) {
                Text("Apple Health: ขอสิทธิ์แล้ว")
                    .font(.subheadline.bold())
                Text("เฉพาะข้อมูลที่คุณอนุญาตเท่านั้น")
                    .font(.caption)
                    .foregroundStyle(P100Style.secondary)
            }
            Spacer()
            if health.isLoading { ProgressView() }
        }
        .padding(15)
        .background(P100Style.mint, in: RoundedRectangle(cornerRadius: 17))
    }
}

private struct ConnectCard: View {
    @EnvironmentObject private var health: HealthKitService

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("เชื่อม Apple Health", systemImage: "heart.text.square")
                .font(.headline)
                .foregroundStyle(P100Style.forest)
            Text("อ่านการนอน HRV, Resting HR และ Workout จาก Apple Watch ผ่าน Apple Health โดยไม่ต้อง Export ZIP")
                .font(.subheadline)
                .foregroundStyle(P100Style.secondary)
            Button {
                Task { await health.connect() }
            } label: {
                Label("อนุญาตการอ่านข้อมูล", systemImage: "heart.fill")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
            }
            .buttonStyle(.borderedProminent)
            .tint(P100Style.forest)
            .disabled(health.isLoading)
            if let message = health.message {
                Text(message).font(.caption).foregroundStyle(.red)
            }
        }
        .p100Card()
    }
}

private struct MetricTile: View {
    let icon: String
    let label: String
    let number: String
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon).foregroundStyle(P100Style.forest)
            Text(label)
                .font(.caption)
                .foregroundStyle(P100Style.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text(number)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                Text(unit).font(.caption).foregroundStyle(P100Style.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .p100Card()
    }
}

struct HealthScreen: View {
    @EnvironmentObject private var health: HealthKitService

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("การนอนและการฟื้นตัว")
                    .font(.system(size: 27, weight: .bold, design: .rounded))
                Text("ข้อมูลอ่านจาก HealthKit โดยตรง ไม่มีการสมมติคะแนน Recovery")
                    .font(.subheadline)
                    .foregroundStyle(P100Style.secondary)

                if let sleep = health.snapshot.lastSleep {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("คืนล่าสุด · \(sleep.nightDate.formatted(date: .abbreviated, time: .omitted))")
                            .font(.headline)
                        Text("\(sleep.asleepHours.formatted(.number.precision(.fractionLength(1)))) ชั่วโมง")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(P100Style.forest)
                        SleepStageRow(label: "Core", hours: sleep.coreHours, color: .mint)
                        SleepStageRow(label: "Deep", hours: sleep.deepHours, color: .indigo)
                        SleepStageRow(label: "REM", hours: sleep.remHours, color: .blue)
                        SleepStageRow(label: "ไม่ระบุระยะ", hours: sleep.unknownHours, color: .gray)
                        Text("ค่าระยะการนอนเป็นการประเมินจากแหล่งข้อมูลเดียวของคืนนั้น เพื่อลดการนับข้อมูลซ้ำ")
                            .font(.caption).foregroundStyle(P100Style.secondary)
                    }
                    .p100Card()
                } else {
                    ContentUnavailableView(
                        "ยังไม่มี Sleep Data",
                        systemImage: "moon.zzz",
                        description: Text("สวม Apple Watch ระหว่างนอนและตรวจการอนุญาตใน Health")
                    )
                    .p100Card()
                }

                VStack(alignment: .leading, spacing: 12) {
                    Label("กิจกรรมล่าสุด", systemImage: "figure.run")
                        .font(.headline)
                    if health.snapshot.recentWorkouts.isEmpty {
                        Text("ยังไม่มี Workout ในช่วง 21 วันที่แอปอ่านได้")
                            .font(.subheadline).foregroundStyle(P100Style.secondary)
                    }
                    ForEach(health.snapshot.recentWorkouts.prefix(8)) { workout in
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(workout.kind).font(.subheadline.bold())
                                Text(workout.date.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption).foregroundStyle(P100Style.secondary)
                            }
                            Spacer()
                            Text("\(Int(workout.durationMinutes)) นาที")
                                .font(.subheadline).foregroundStyle(P100Style.forest)
                        }
                        Divider()
                    }
                }
                .p100Card()
            }
            .padding(18)
        }
        .background(P100Style.canvas)
        .navigationTitle("สุขภาพ")
    }
}

private struct SleepStageRow: View {
    let label: String
    let hours: Double
    let color: Color

    var body: some View {
        HStack(spacing: 9) {
            Circle().fill(color).frame(width: 10, height: 10)
            Text(label).font(.subheadline)
            Spacer()
            Text("\(hours.formatted(.number.precision(.fractionLength(1)))) ชม.")
                .font(.subheadline.monospacedDigit())
        }
    }
}

struct TrainingScreen: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                Text("แผนฝึกในชีวิตจริง")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                Text("ไม่มีวันบังคับให้ซ้อม แอปจะบอกว่าครั้งต่อไปต้องทำอะไรเมื่อคุณพร้อม")
                    .foregroundStyle(P100Style.secondary)
                VStack(alignment: .leading, spacing: 12) {
                    Label("100M — The Comeback", systemImage: "figure.run")
                        .font(.headline)
                    Text("แผนและประวัติเดิมยังอยู่บน PROJECT 100M Web ข้อมูลจะไม่ถูกย้ายหรือเขียนทับโดย Native MVP นี้")
                        .font(.subheadline)
                        .foregroundStyle(P100Style.secondary)
                    Link("เปิดแผนฝึกเดิม", destination: URL(string: "https://ijennyrsm.github.io/project-100m-dashboard/")!)
                        .buttonStyle(.borderedProminent)
                        .tint(P100Style.forest)
                }
                .p100Card()
                Text("ถัดไป: อ่านแผนจาก Supabase ด้วยบัญชีเดิม และเพิ่ม Live Workout บน Apple Watch")
                    .font(.footnote)
                    .foregroundStyle(P100Style.secondary)
            }
            .padding(18)
        }
        .background(P100Style.canvas)
        .navigationTitle("แผนฝึก")
    }
}

struct AccountScreen: View {
    @EnvironmentObject private var health: HealthKitService

    var body: some View {
        Form {
            Section("Apple Health") {
                LabeledContent("สถานะ") {
                    Text(health.hasRequestedAccess ? "ขอสิทธิ์แล้ว" : "ยังไม่ได้ขอสิทธิ์")
                }
                if let date = health.snapshot.lastRead {
                    LabeledContent("อ่านข้อมูลล่าสุด") {
                        Text(date.formatted(date: .abbreviated, time: .shortened))
                    }
                }
                Button("อ่านข้อมูลใหม่") {
                    Task { await health.refreshIfEnabled() }
                }
                .disabled(!health.hasRequestedAccess || health.isLoading)
                if !health.hasRequestedAccess {
                    Button("อนุญาต Apple Health") {
                        Task { await health.connect() }
                    }
                }
                if let error = health.message {
                    Text(error).font(.caption).foregroundStyle(.red)
                }
            }
            Section("ความเป็นส่วนตัว") {
                Text("รุ่นเริ่มต้นอ่าน Apple Health ในเครื่องเท่านั้น ยังไม่อัปโหลดสุขภาพไป Supabase หรือส่งให้ AI")
                Text("แอปไม่สามารถยืนยันได้ว่าคุณอนุญาตทุกประเภทหรือไม่ หากข้อมูลไม่มี จะเว้นค่าไว้ ไม่เดา")
            }
            Section("Cloud Account — ขั้นต่อไป") {
                Text("เราจะเพิ่ม Supabase Auth และแยกข้อมูลแต่ละบัญชี ก่อนเปิด Cloud Sync โดยอัตโนมัติ")
            }
        }
        .navigationTitle("บัญชีและข้อมูล")
    }
}

private struct P100Card: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white, in: RoundedRectangle(cornerRadius: 21))
    }
}

private extension View {
    func p100Card() -> some View { modifier(P100Card()) }
}
