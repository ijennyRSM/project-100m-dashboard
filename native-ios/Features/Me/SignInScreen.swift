import SwiftUI
import UIKit

/// Passwordless sign-in to the existing PROJECT 100M Supabase account (same users as the website).
struct SignInScreen: View {
    @EnvironmentObject private var account: AccountModel
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var code = ""
    @State private var link = ""

    var body: some View {
        Form {
            if account.phase == .signedIn {
                Section {
                    Label("เข้าสู่ระบบแล้ว: \(account.user?.email ?? "")", systemImage: "checkmark.seal.fill")
                    Button("กลับ") { dismiss() }
                }
            } else if let pending = account.pendingEmail {
                Section {
                    Text("ส่งอีเมลเข้าสู่ระบบไปที่ \(pending) แล้ว").font(.headline)
                    Text("ถ้าอีเมลมีรหัสตัวเลข ให้กรอกรหัส หรือกดค้างที่ลิงก์ในอีเมล เลือก Copy Link แล้ววางด้านล่าง อย่ากดลิงก์ก่อน เพราะลิงก์ใช้ได้ครั้งเดียวและจะเปิดเว็บไซต์แทน")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                Section("รหัสจากอีเมล") {
                    TextField("123456", text: $code).keyboardType(.numberPad).textContentType(.oneTimeCode)
                        .accessibilityIdentifier("signin-code")
                    Button("ยืนยันรหัส") { Task { if await account.verify(code: code) { dismiss() } } }
                        .disabled(code.count < 6 || account.isBusy).accessibilityIdentifier("signin-verify")
                }
                Section("หรือวางลิงก์จากอีเมล") {
                    TextField("https://…", text: $link, axis: .vertical).lineLimit(1...4)
                        .textInputAutocapitalization(.never).autocorrectionDisabled().keyboardType(.URL)
                        .accessibilityIdentifier("signin-link")
                    Button("วางจากคลิปบอร์ด") { link = UIPasteboard.general.string ?? "" }
                    Button("เข้าสู่ระบบด้วยลิงก์") { Task { if await account.complete(linkText: link) { dismiss() } } }
                        .disabled(link.isEmpty || account.isBusy)
                }
                Section {
                    Button("ส่งอีเมลอีกครั้ง") { Task { await account.requestCode(email: pending) } }.disabled(account.isBusy)
                    Button("เปลี่ยนอีเมล") { account.cancelPendingCode() }
                }
            } else {
                Section {
                    Text("ใช้บัญชีเดียวกับเว็บไซต์ PROJECT 100M ไม่ต้องใช้รหัสผ่าน").font(.subheadline)
                    TextField("อีเมล", text: $email)
                        .keyboardType(.emailAddress).textContentType(.emailAddress)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                        .accessibilityIdentifier("signin-email")
                    Button("ส่งอีเมลเข้าสู่ระบบ") { Task { await account.requestCode(email: email) } }
                        .disabled(email.isEmpty || account.isBusy).accessibilityIdentifier("signin-send")
                } footer: {
                    Text("แอปขอเข้าสู่ระบบเฉพาะบัญชีที่มีอยู่แล้ว ถ้ายังไม่มีบัญชี สร้างผ่านเว็บไซต์ก่อน")
                }
            }
            if account.isBusy { Section { ProgressView("กำลังติดต่อเซิร์ฟเวอร์…") } }
            if let message = account.message {
                Section { Text(message).foregroundStyle(.red).accessibilityIdentifier("signin-error") }
            }
            Section("ความปลอดภัย") {
                Text("Session เก็บใน Keychain ของ iPhone เครื่องนี้เท่านั้น ข้อมูลฝึกแยกตามบัญชี แอปไม่ส่งข้อมูลสุขภาพขึ้นคลาวด์")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("เข้าสู่ระบบ").navigationBarTitleDisplayMode(.inline)
    }
}
