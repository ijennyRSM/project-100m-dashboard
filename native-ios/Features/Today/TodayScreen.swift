import SwiftUI

struct TodayScreen: View {
    @EnvironmentObject private var account: AccountModel
    @EnvironmentObject private var training: TrainingModel

    var body: some View {
        P100Screen {
            VStack(alignment: .leading, spacing: 8) {
                Text("MOVE AT YOUR PACE").font(.caption.bold()).tracking(1.5).foregroundStyle(P100Theme.accent)
                Text(account.phase == .signedIn ? "สวัสดี, \(account.displayName)" : "สวัสดี").font(P100Type.hero)
                    .accessibilityIdentifier("screen-today")
                Text("กลับมาเมื่อพร้อม แล้วไปต่อได้เลย").foregroundStyle(.secondary)
            }
            if let notice = training.notice {
                StatusBanner(title: "กู้คืนข้อมูลในเครื่อง", message: notice, symbol: "exclamationmark.triangle")
            }
            if let live = training.live {
                P100Card {
                    Label("Live Workout ค้างอยู่", systemImage: "timer").font(.subheadline.bold()).foregroundStyle(P100Theme.accent)
                    Text(live.title).font(.title3.bold())
                    Text("สำเร็จ \(live.unitsDone)/\(live.unitsTotal) ขั้นย่อย · บันทึกไว้ในเครื่องแล้ว").foregroundStyle(.secondary)
                    NavigationLink { LiveWorkoutScreen(startKey: nil) } label: {
                        Label("ฝึกต่อ", systemImage: "play.fill")
                    }.buttonStyle(PrimaryAction()).accessibilityIdentifier("resume-live")
                }
            }
            if !training.isLoaded {
                ProgressView("กำลังเปิดข้อมูลฝึก…")
            } else if let plan = training.activePlan, let overview = training.overview {
                ActivePlanCard(plan: plan, overview: overview)
            } else {
                NoPlanCard()
            }
            P100Card {
                SectionHeading(title: "Recovery แบบสั้น")
                Text("ดูข้อมูลจริงที่อนุญาตใน Health ส่วนคะแนนและคำแนะนำกำลังพัฒนา").foregroundStyle(.secondary)
                NavigationLink("ดูการเชื่อมต่อ Apple Health") { HealthConnectionScreen() }.frame(minHeight: 44)
                    .accessibilityIdentifier("today-health-connection")
            }
            SectionHeading(title: "กิจกรรมล่าสุด")
            if let latest = training.history.first {
                HistoryRow(entry: latest)
            } else {
                Text("ยังไม่มีการบันทึกการฝึกในเครื่องนี้ เริ่มครั้งแรกจากแผนด้านบน").foregroundStyle(.secondary)
                    .accessibilityIdentifier("today-empty-history")
            }
            P100Card {
                SectionHeading(title: "Quick Actions")
                if account.phase != .signedIn {
                    NavigationLink { SignInScreen() } label: { Label("เข้าสู่ระบบบัญชี PROJECT 100M", systemImage: "person.badge.key") }
                        .frame(minHeight: 44)
                }
                Link("เปิดแผนและประวัติเดิมบนเว็บ ↗", destination: P100Theme.dashboardURL).frame(minHeight: 44)
                Text("ประวัติบนเว็บยังไม่ถูกนำเข้าหรือแก้ไขโดยแอป Native การฝึกในแอปเก็บในเครื่องนี้")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }.navigationTitle("Today").navigationBarTitleDisplayMode(.inline)
    }
}
