import SwiftUI

extension SessionKind {
    var symbol: String {
        switch self {
        case .sprint: return "bolt.fill"
        case .easy: return "figure.run"
        case .strength: return "dumbbell.fill"
        case .walk: return "figure.walk"
        }
    }
}

struct TrainingScreen: View {
    @EnvironmentObject private var training: TrainingModel

    var body: some View {
        P100Screen {
            Text("แผนของคุณ").font(.title3.bold()).accessibilityAddTraits(.isHeader).accessibilityIdentifier("screen-train")
            if let plan = training.activePlan, let overview = training.overview {
                if let next = overview.next {
                    SessionStartCard(
                        symbol: next.kind.symbol, title: next.title,
                        subtitle: "\(TrainingCatalog.template(plan.templateId)?.name ?? "") · Block \(next.block) · Session \(next.slot)\n\(next.summary)",
                        startLabel: training.live?.key == next.key ? "ฝึกต่อ" : "เริ่ม",
                        startID: "train-start-live") {
                        SessionDetailScreen(sessionKey: next.key)
                    } start: {
                        LiveWorkoutScreen(startKey: next.key)
                    }
                    if overview.statusByKey[next.key] == .partial {
                        Label("ทำบางส่วนไว้แล้ว เริ่มต่อจากส่วนที่ทำแล้วได้", systemImage: AttemptStatus.partial.symbol)
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                } else {
                    P100Card {
                        Label("จบแผนนี้แล้ว ยินดีด้วย!", systemImage: "flag.checkered").font(.title3.bold())
                        Text("เลือกโปรแกรมถัดไปจากด้านล่าง ประวัติเดิมยังอยู่ครบ").foregroundStyle(.secondary)
                    }
                }
                NavigationLink { PlanDetailScreen() } label: {
                    Text("ทุก Session ในแผน · \(overview.percent)%")
                }.buttonStyle(OutlineAction(accent: true)).accessibilityIdentifier("open-plan")
            } else if training.isLoaded {
                NoPlanCard()
            }
            NavigationLink { MapsScreen() } label: {
                ListRowLabel(symbol: "map", title: "Maps", value: "สำรวจหน้าตาเส้นทาง · ตัวอย่าง")
                    .padding(.horizontal, -P100Space.page)
            }.buttonStyle(.plain).accessibilityIdentifier("open-maps")
            library
            history
        }.navigationTitle("Train").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    IconLink(title: "Maps", symbol: "map") { MapsScreen() }
                }
            }
    }

    private var library: some View {
        VStack(alignment: .leading, spacing: 12) {
            NavigationLink { TrainingLibraryScreen() } label: {
                HStack(spacing: 12) {
                    Image(systemName: "square.stack.3d.up.fill").font(.title2).foregroundStyle(P100Theme.accent)
                        .accessibilityHidden(true)
                    Text("โปรแกรมฝึก").font(.title2.bold())
                    Spacer()
                    Image(systemName: "chevron.right").foregroundStyle(.secondary)
                }.contentShape(Rectangle())
            }.buttonStyle(.plain).frame(minHeight: 44).accessibilityIdentifier("open-library")
            Text("ห้าโปรแกรมจากแผนเดิม ฝึกตามจังหวะของคุณ สลับแผนได้โดยประวัติไม่หาย").foregroundStyle(.secondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(TrainingCatalog.templates) { template in
                        NavigationLink { ProgramScreen(template: template) } label: {
                            ProgramTile(template: template, isActive: training.activePlan?.templateId == template.id)
                        }.buttonStyle(.plain).accessibilityIdentifier("program-card-\(template.id)")
                    }
                }.padding(.horizontal, P100Space.page)
            }.padding(.horizontal, -P100Space.page)
        }
    }

    @ViewBuilder private var history: some View {
        HStack {
            Text("ประวัติการฝึก").font(.title2.bold())
            Spacer()
            if !training.history.isEmpty {
                NavigationLink("ดูทั้งหมด") { HistoryScreen() }.font(.subheadline.bold())
                    .frame(minHeight: 44).accessibilityIdentifier("open-history")
            }
        }
        if training.history.isEmpty {
            Text("ยังไม่มีประวัติ เริ่ม Live Workout หรือบันทึกแบบย่อเพื่อเริ่มสะสม").foregroundStyle(.secondary)
        } else {
            ForEach(training.history.prefix(3)) { HistoryRow(entry: $0) }
        }
    }
}
