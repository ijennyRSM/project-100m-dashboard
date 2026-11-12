import SwiftUI

struct FeedScreen: View {
    @State private var filter = "ทั้งหมด"
    private var activities: [SampleActivity] {
        SampleActivity.examples.filter { filter == "ทั้งหมด" || (filter == "Running" ? $0.id == "run" : $0.id == "strength") }
    }
    var body: some View {
        P100Screen(horizontalPadding: 0, spacing: 0) {
            WeekSummaryCard().padding(.horizontal, P100Space.page).padding(.vertical, 16)
            SectionBand()
            VStack(alignment: .leading, spacing: 12) {
                SampleBanner()
                ChipPicker(labels: ["ทั้งหมด", "Running", "Strength"], selection: $filter, id: "feed-filter")
            }.padding(.horizontal, P100Space.page).padding(.top, 14)
            ForEach(activities) { activity in
                ActivityCard(activity: activity).accessibilityIdentifier("activity-\(activity.id)")
                SectionBand()
            }
            StatusBanner(title: "คุณเลือกเองว่าจะแชร์อะไร", message: "Workout ใหม่จะเป็นส่วนตัว การสร้างโพสต์และปฏิสัมพันธ์จะเปิดใช้หลังระบบบัญชีและความเป็นส่วนตัวพร้อม", symbol: "lock.shield")
                .padding(P100Space.page)
        }.navigationTitle("Feed").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    IconLink(title: "Groups", symbol: "person.2") { GroupsScreen() }
                        .accessibilityIdentifier("open-groups")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    IconLink(title: "ความเป็นส่วนตัวและการแชร์", symbol: "lock.shield") { PrivacyScreen() }
                }
            }
    }
}

/// Real weekly summary from this account's recorded attempts (not sample data).
struct WeekSummaryCard: View {
    @EnvironmentObject private var training: TrainingModel

    var body: some View {
        let week = TrainingStats.weekly(training.history.map(\.attempt), count: 1).last
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("สัปดาห์นี้ของคุณ", systemImage: "flame").font(.headline)
                Spacer()
                NavigationLink("ประวัติ") { HistoryScreen() }.font(.subheadline.bold()).foregroundStyle(P100Theme.accent)
                    .frame(minHeight: 44)
            }
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 14) { ring; summary(week); Spacer(minLength: 8); action.fixedSize() }
                VStack(alignment: .leading, spacing: 12) { HStack(spacing: 14) { ring; summary(week) }; action }
            }
        }.accessibilityIdentifier("week-summary")
    }

    private var ring: some View {
        ZStack {
            Circle().strokeBorder(Color.primary.opacity(0.25), lineWidth: 3)
            Image(systemName: "figure.run").font(.title2.weight(.semibold))
        }.frame(width: 56, height: 56).accessibilityHidden(true)
    }

    private func summary(_ week: WeekSummary?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(week?.sessions ?? 0) ครั้ง · \(week?.minutes ?? 0) นาที").font(.title2.bold())
            Text(training.overview?.next.map { "ครั้งต่อไป: \($0.title)" } ?? "บันทึกจริงในเครื่องนี้")
                .font(.subheadline).foregroundStyle(.secondary).lineLimit(2)
        }
    }

    @ViewBuilder private var action: some View {
        if training.activePlan != nil, training.overview?.next != nil {
            NavigationLink { LiveWorkoutScreen(startKey: nil) } label: {
                Text(training.live == nil ? "เริ่มฝึก" : "ฝึกต่อ").font(.headline)
                    .padding(.horizontal, 22).frame(minHeight: 44)
                    .foregroundStyle(P100Theme.canvas).background(P100Theme.accent, in: Capsule())
            }.buttonStyle(.plain)
        } else {
            NavigationLink { TrainingLibraryScreen() } label: {
                Text("เลือกแผน").font(.headline)
                    .padding(.horizontal, 22).frame(minHeight: 44)
                    .foregroundStyle(P100Theme.canvas).background(P100Theme.accent, in: Capsule())
            }.buttonStyle(.plain)
        }
    }
}
