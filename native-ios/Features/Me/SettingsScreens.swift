import SwiftUI

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
            Section("บัญชีและข้อมูลในเครื่อง") {
                Text("เข้าสู่ระบบด้วยบัญชี PROJECT 100M เดิม Session เก็บใน Keychain และลบเมื่อออกจากระบบ")
                Text("แผนและ Workout ที่บันทึกในแอปเก็บในเครื่องนี้ แยกตามบัญชี ยังไม่ซิงก์ขึ้นคลาวด์ และไม่เขียนทับประวัติบนเว็บ")
                Text("ยังไม่มีการสร้างโพสต์หรือแชร์ Workout สู่สาธารณะ")
                Text("แผนที่โหลดจาก Apple Maps เพื่อแสดงเส้นทางตัวอย่าง แอปไม่ขอและไม่อ่านตำแหน่งของคุณ")
            }
        }.navigationTitle("ความเป็นส่วนตัว").navigationBarTitleDisplayMode(.inline)
    }
}
