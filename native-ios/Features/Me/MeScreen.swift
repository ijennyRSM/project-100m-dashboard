import SwiftUI

struct MeScreen: View {
    var body: some View {
        P100Screen {
            SampleBanner()
            P100Card {
                Image(systemName: "person.crop.circle.fill").font(.system(size: 60)).foregroundStyle(P100Theme.accent).accessibilityHidden(true)
                Text("เมย์ · ตัวอย่างโปรไฟล์").font(.title2.bold())
                Text("@may_example").foregroundStyle(.secondary)
                Text("กลับมาขยับในจังหวะของตัวเอง 🌱")
                Text("ยังไม่ได้เข้าสู่ระบบ").font(.caption).foregroundStyle(.secondary)
            }
            P100Card {
                SectionHeading(title: "เส้นทางและความทรงจำ")
                Text("โพสต์สาธารณะ · ประวัติ Workout\nPersonal Records · Achievements")
                Text("รายการเหล่านี้ยังไม่เชื่อมข้อมูลจริง ดูประวัติเดิมบนเว็บได้").font(.caption).foregroundStyle(.secondary)
                Link("เปิดประวัติบนเว็บ ↗", destination: P100Theme.dashboardURL).frame(minHeight: 44)
            }
            P100Card {
                SectionHeading(title: "การตั้งค่าบนอุปกรณ์นี้")
                NavigationLink { HealthConnectionScreen() } label: {
                    Label("Apple Health และอุปกรณ์", systemImage: "applewatch").frame(minHeight: 44)
                }
                NavigationLink { PrivacyScreen() } label: {
                    Label("ความเป็นส่วนตัวและการแชร์", systemImage: "lock.shield").frame(minHeight: 44)
                }
            }
        }.navigationTitle("Me")
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
