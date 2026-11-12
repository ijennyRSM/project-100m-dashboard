import SwiftUI

struct MeScreen: View {
    @State private var section = "Progress"
    var body: some View {
        P100Screen {
            SampleBanner()
            HStack(alignment: .top, spacing: 16) {
                ProfileAvatar(initial: "ม", size: 76)
                VStack(alignment: .leading, spacing: 4) {
                    Text("เมย์").font(P100Type.hero)
                    Text("@may_example").font(.subheadline).foregroundStyle(.secondary)
                    Text("ตัวอย่างโปรไฟล์ · ยังไม่ได้เข้าสู่ระบบ").font(.caption).foregroundStyle(.secondary)
                }
            }
            Text("กลับมาขยับในจังหวะของตัวเอง 🌱")
            StatStrip(items: [StatItem(label: "กิจกรรมสมมติ", value: "12"), StatItem(label: "PR สมมติ", value: "2"), StatItem(label: "สัปดาห์สมมติ", value: "4")])
            ChipPicker(labels: ["Progress", "Activities", "Gallery", "More"], selection: $section, id: "profile-section")
            Group {
                switch section {
                case "Activities":
                    ForEach(SampleActivity.examples) { ActivityCard(activity: $0) }
                case "Gallery":
                    P100Card {
                        RouteIllustration().frame(height: 210)
                        Text("Gallery ตัวอย่าง").font(P100Type.section)
                        Text("ภาพประกอบต้นฉบับเท่านั้น ยังไม่มีรูปส่วนตัวหรือการอัปโหลดภาพ").foregroundStyle(.secondary)
                    }.accessibilityIdentifier("profile-gallery")
                case "More": settings
                default:
                    P100Card {
                        SectionHeading(title: "This week", subtitle: "ความคืบหน้าสมมติ ไม่ใช่ประวัติของคุณ")
                        StatStrip(items: [StatItem(label: "ระยะทาง", value: "3.2 km"), StatItem(label: "เวลา", value: "24 นาที")])
                        HStack(alignment: .bottom, spacing: 10) {
                            ForEach(Array([0.25, 0.42, 0.32, 0.75, 0.58, 0.9, 0.65].enumerated()), id: \.offset) { _, value in
                                Capsule().fill(P100Theme.accent.opacity(0.6)).frame(maxWidth: .infinity).frame(height: 100 * value)
                            }
                        }.frame(height: 108).accessibilityHidden(true)
                        Text("ภาพความเคลื่อนไหวสมมติ 7 สัปดาห์").font(.caption).foregroundStyle(.secondary)
                    }.accessibilityIdentifier("profile-progress")
                    P100Card {
                        Label("ทีละก้าว ก็ไปได้ไกล", systemImage: "flag.checkered").font(.headline)
                        Text("พื้นที่สำหรับ Personal Records และ Achievements — ยังไม่คำนวณหรือมอบรางวัลจริง").foregroundStyle(.secondary)
                    }
                }
            }
            Link("เปิดประวัติจริงบนเว็บ ↗", destination: P100Theme.dashboardURL).frame(minHeight: 44)
        }.navigationTitle("Me").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    IconLink(title: "ความเป็นส่วนตัวและการแชร์", symbol: "gearshape") { PrivacyScreen() }
                }
            }
    }
    private var settings: some View {
        P100Card {
            SectionHeading(title: "การตั้งค่าบนอุปกรณ์นี้")
            NavigationLink { HealthConnectionScreen() } label: {
                Label("Apple Health และอุปกรณ์", systemImage: "applewatch").frame(minHeight: 44)
            }
            NavigationLink { PrivacyScreen() } label: {
                Label("ความเป็นส่วนตัวและการแชร์", systemImage: "lock.shield").frame(minHeight: 44)
            }
            Text("บัญชีและการแก้ไขโปรไฟล์ยังไม่เปิดใช้งาน").font(.caption).foregroundStyle(.secondary)
        }.accessibilityIdentifier("profile-settings")
    }
}

struct HealthConnectionScreen: View {
    @EnvironmentObject private var health: HealthKitService
    var body: some View {
        Form {
            Section("Apple Health · สถานะจริงบนเครื่องนี้") {
                LabeledContent("การเชื่อมต่อ", value: health.connection.title)
                Text("การขอสิทธิ์สำเร็จไม่ได้ยืนยันว่าอ่านได้ทุกประเภท หากข้อมูลไม่มี แอปจะเว้นค่าไว้").font(.caption).foregroundStyle(.secondary)
                if let date = health.snapshot.lastRead {
                    LabeledContent("อ่านล่าสุด", value: date.formatted(date: .abbreviated, time: .shortened))
                }
                if health.isLoading { ProgressView("กำลังอ่านข้อมูล…") }
                if health.connection == .unavailable {
                    Text("HealthKit ไม่พร้อมใช้งานบนอุปกรณ์นี้")
                } else {
                    Button(health.hasRequestedAccess ? "ขอสิทธิ์อ่าน Apple Health อีกครั้ง" : "อนุญาตการอ่าน Apple Health") {
                        Task { await health.connect() }
                    }.disabled(health.isLoading)
                    Button("อ่านข้อมูลใหม่") { Task { await health.refreshIfEnabled() } }
                        .disabled(!health.hasRequestedAccess || health.isLoading)
                }
                if let message = health.message { Text(message).foregroundStyle(.red) }
            }
            Section("ข้อมูลและอุปกรณ์") {
                Text("Apple Watch ส่งข้อมูลเข้า Apple Health ผ่านระบบของ Apple แอปอ่านเฉพาะข้อมูลที่คุณอนุญาต")
                Text("อ่านในเครื่องเท่านั้น ยังไม่มี Cloud Health Sync หรือการส่งให้ AI")
                Text("จัดการสิทธิ์ในแอป Health หรือ Settings ของ iPhone แอปไม่สามารถเปิดสิทธิ์ที่คุณปฏิเสธให้เองได้")
            }
        }.navigationTitle("Apple Health").navigationBarTitleDisplayMode(.inline)
    }
}

struct PrivacyScreen: View {
    var body: some View {
        Form {
            Section("ส่วนตัวเป็นค่าเริ่มต้น") {
                Text("Workout ใหม่ต้องเป็นส่วนตัว การเผยแพร่ต้องเป็นการเลือกของคุณเอง")
                Text("ข้อมูลนอน HRV และ Resting HR ไม่ถูกเผยแพร่เป็นโพสต์หรือส่งไป AI โดยอัตโนมัติ")
            }
            Section("สถานะรุ่น M0") {
                Text("ยังไม่มีบัญชี การสร้างโพสต์ Cloud Sync หรือการบันทึก Workout ใน Native จึงยังไม่มีการตั้งค่าแชร์ที่เปลี่ยนข้อมูลได้")
                Text("แผนและข้อมูลจริงบนเว็บยังอยู่ที่เดิม")
            }
        }.navigationTitle("ความเป็นส่วนตัว").navigationBarTitleDisplayMode(.inline)
    }
}
