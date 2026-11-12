import SwiftUI

struct MeScreen: View {
    @EnvironmentObject private var account: AccountModel
    @EnvironmentObject private var training: TrainingModel
    @State private var section = "Progress"
    @State private var confirmSignOut = false
    @State private var confirmImport = false

    private var completedCount: Int { training.history.filter { $0.attempt.status == .completed }.count }
    private var liveCount: Int { training.history.filter { $0.attempt.mode == "live" }.count }

    var body: some View {
        P100Screen {
            identity
            StatStrip(items: [StatItem(label: "ฝึกครบ", value: "\(completedCount)"),
                              StatItem(label: "บันทึกทั้งหมด", value: "\(training.history.count)"),
                              StatItem(label: "Live Workout", value: "\(liveCount)")])
            if account.phase == .signedIn && training.guestImportAvailable {
                P100Card {
                    Label("พบข้อมูลฝึกโหมด Guest ในเครื่องนี้", systemImage: "tray.and.arrow.down").font(.headline)
                    Text("บัญชีนี้ยังไม่มีแผนในเครื่อง คัดลอกแผนและประวัติจากโหมด Guest เข้าบัญชีนี้ได้ ข้อมูล Guest เดิมยังอยู่ และไม่มีการส่งขึ้นคลาวด์")
                        .font(.subheadline).foregroundStyle(.secondary)
                    Button("คัดลอกเข้าบัญชีนี้…") { confirmImport = true }.buttonStyle(SecondaryAction())
                        .accessibilityIdentifier("import-guest")
                }
            }
            ChipPicker(labels: ["Progress", "Activities", "Gallery", "More"], selection: $section, id: "profile-section")
            Group {
                switch section {
                case "Activities":
                    if training.history.isEmpty {
                        Text("ยังไม่มีกิจกรรมที่บันทึกในเครื่องนี้").foregroundStyle(.secondary)
                            .accessibilityIdentifier("profile-activities-empty")
                    } else {
                        ForEach(training.history.prefix(20)) { HistoryRow(entry: $0) }
                    }
                case "Gallery":
                    SampleBanner()
                    P100Card {
                        RouteIllustration().frame(height: 210)
                        Text("Gallery ตัวอย่าง").font(P100Type.section)
                        Text("ภาพประกอบต้นฉบับเท่านั้น ยังไม่มีรูปส่วนตัวหรือการอัปโหลดภาพ").foregroundStyle(.secondary)
                    }.accessibilityIdentifier("profile-gallery")
                case "More": settings
                default:
                    P100Card {
                        SectionHeading(title: "แผนปัจจุบัน", subtitle: training.activeTemplate?.name ?? "ยังไม่ได้เลือกแผน")
                        if let overview = training.overview {
                            ProgressView(value: Double(overview.completed + overview.skipped), total: Double(max(overview.total, 1)))
                            Text("\(overview.percent)% · ฝึกครบ \(overview.completed) · ข้าม \(overview.skipped) · ทั้งหมด \(overview.total)")
                                .font(.subheadline.bold())
                        } else {
                            NavigationLink("เลือกแผนฝึก") { TrainingLibraryScreen() }.frame(minHeight: 44)
                        }
                    }.accessibilityIdentifier("profile-progress")
                    P100Card {
                        Label("ทีละก้าว ก็ไปได้ไกล", systemImage: "flag.checkered").font(.headline)
                        Text("Personal Records และ Achievements ยังไม่คำนวณ จะไม่แสดงตัวเลขที่ไม่ได้มาจากการบันทึกจริง").foregroundStyle(.secondary)
                    }
                }
            }
            Link("เปิดประวัติเดิมบนเว็บ ↗", destination: P100Theme.dashboardURL).frame(minHeight: 44)
        }.navigationTitle("Me").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    IconLink(title: "ความเป็นส่วนตัวและการแชร์", symbol: "gearshape") { PrivacyScreen() }
                }
            }
            .confirmationDialog("คัดลอกข้อมูล Guest เข้าบัญชีนี้?", isPresented: $confirmImport, titleVisibility: .visible) {
                Button("คัดลอก") { training.importGuestData() }
                Button("ยกเลิก", role: .cancel) {}
            } message: {
                Text("แผน ประวัติ และ Live Workout ที่ค้างอยู่ในโหมด Guest จะถูกคัดลอกเข้าบัญชี \(account.user?.email ?? "")")
            }
            .confirmationDialog("ออกจากระบบ?", isPresented: $confirmSignOut, titleVisibility: .visible) {
                Button("ออกจากระบบ (เก็บข้อมูลฝึกในเครื่องไว้)") { Task { await signOut(removeData: false) } }
                Button("ออกจากระบบและลบข้อมูลฝึกของบัญชีนี้ในเครื่อง", role: .destructive) { Task { await signOut(removeData: true) } }
                Button("ยกเลิก", role: .cancel) {}
            } message: {
                Text("Session ใน Keychain จะถูกลบ ข้อมูลฝึกของบัญชีนี้จะถูกซ่อนจนกว่าจะเข้าสู่ระบบอีกครั้ง เว้นแต่เลือกลบ")
            }
    }

    @ViewBuilder private var identity: some View {
        HStack(alignment: .top, spacing: 16) {
            ProfileAvatar(initial: String(account.displayName.prefix(1)).uppercased(), size: 76)
            VStack(alignment: .leading, spacing: 4) {
                if account.phase == .signedIn {
                    Text(account.displayName).font(P100Type.hero).accessibilityIdentifier("screen-me")
                    Text(account.user?.email ?? "").font(.subheadline).foregroundStyle(.secondary)
                    Text(account.isOffline ? "บัญชี PROJECT 100M · ออฟไลน์ (ใช้ Session ที่บันทึกไว้)" : "บัญชี PROJECT 100M")
                        .font(.caption).foregroundStyle(.secondary)
                } else {
                    Text(account.phase == .restoring ? "กำลังตรวจสอบบัญชี…" : "ยังไม่ได้เข้าสู่ระบบ").font(P100Type.section)
                        .accessibilityIdentifier("screen-me")
                    Text("ข้อมูลฝึกตอนนี้อยู่ในโหมด Guest บนเครื่องนี้").font(.caption).foregroundStyle(.secondary)
                    NavigationLink { SignInScreen() } label: { Label("เข้าสู่ระบบ", systemImage: "person.badge.key") }
                        .buttonStyle(SecondaryAction()).accessibilityIdentifier("me-sign-in")
                }
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
            if account.phase == .signedIn {
                Button(role: .destructive) { confirmSignOut = true } label: {
                    Label("ออกจากระบบ", systemImage: "rectangle.portrait.and.arrow.right").frame(minHeight: 44)
                }.accessibilityIdentifier("me-sign-out")
            } else {
                NavigationLink { SignInScreen() } label: {
                    Label("เข้าสู่ระบบ", systemImage: "person.badge.key").frame(minHeight: 44)
                }
            }
            Text("การแก้ไขโปรไฟล์สาธารณะยังไม่เปิดใช้งาน").font(.caption).foregroundStyle(.secondary)
        }.accessibilityIdentifier("profile-settings")
    }

    private func signOut(removeData: Bool) async {
        let scope = account.scope
        await account.signOut()
        if removeData { training.deleteLocalData(for: scope) }
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
            Section("บัญชีและข้อมูลในเครื่อง") {
                Text("เข้าสู่ระบบด้วยบัญชี PROJECT 100M เดิม Session เก็บใน Keychain และลบเมื่อออกจากระบบ")
                Text("แผนและ Workout ที่บันทึกในแอปเก็บในเครื่องนี้ แยกตามบัญชี ยังไม่ซิงก์ขึ้นคลาวด์ และไม่เขียนทับประวัติบนเว็บ")
                Text("ยังไม่มีการสร้างโพสต์หรือแชร์ Workout สู่สาธารณะ")
            }
        }.navigationTitle("ความเป็นส่วนตัว").navigationBarTitleDisplayMode(.inline)
    }
}
