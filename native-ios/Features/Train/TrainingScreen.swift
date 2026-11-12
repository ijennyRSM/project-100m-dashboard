import SwiftUI

struct TrainingScreen: View {
    @EnvironmentObject private var training: TrainingModel

    var body: some View {
        P100Screen {
            VStack(alignment: .leading, spacing: 4) {
                Text("แผนของคุณ").font(.title3.bold()).accessibilityAddTraits(.isHeader).accessibilityIdentifier("screen-train")
                Text("Workout ตามจังหวะของคุณ · ไม่ผูกกับวันในสัปดาห์").font(.subheadline).foregroundStyle(.secondary)
            }
            if let plan = training.activePlan, let overview = training.overview {
                ActivePlanCard(plan: plan, overview: overview)
                NavigationLink { PlanDetailScreen() } label: {
                    HStack {
                        Label("ดูทุก Session ในแผน", systemImage: "list.number").font(.headline)
                        Spacer()
                        Image(systemName: "chevron.right")
                    }.padding(16).frame(minHeight: 48).background(P100Theme.surface, in: RoundedRectangle(cornerRadius: 16))
                }.buttonStyle(.plain).accessibilityIdentifier("open-plan")
            } else if training.isLoaded {
                NoPlanCard()
            }
            NavigationLink { MapsScreen() } label: {
                HStack {
                    Label("Maps · สำรวจหน้าตาเส้นทาง", systemImage: "map").font(.headline)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                }.padding(16).frame(minHeight: 48).background(P100Theme.surface, in: RoundedRectangle(cornerRadius: 16))
            }.buttonStyle(.plain).accessibilityIdentifier("open-maps")
            SectionHeading(title: "ประวัติการฝึก", subtitle: "บันทึกในเครื่องนี้ของบัญชีปัจจุบัน")
            if training.history.isEmpty {
                Text("ยังไม่มีประวัติ เริ่ม Live Workout หรือบันทึกแบบย่อเพื่อเริ่มสะสม").foregroundStyle(.secondary)
            } else {
                ForEach(training.history.prefix(3)) { HistoryRow(entry: $0) }
                NavigationLink("ดูประวัติทั้งหมด (\(training.history.count))") { HistoryScreen() }
                    .frame(minHeight: 44).accessibilityIdentifier("open-history")
            }
            SectionHeading(title: "Training library", subtitle: "ห้าโปรแกรม · เริ่มหรือสลับแผนได้ ประวัติเดิมไม่หาย")
            TemplateList()
            Link("เปิดแผนเดิมบนเว็บ ↗", destination: P100Theme.dashboardURL).frame(minHeight: 44)
        }.navigationTitle("Train").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    IconLink(title: "Maps", symbol: "map") { MapsScreen() }
                }
            }
    }
}
