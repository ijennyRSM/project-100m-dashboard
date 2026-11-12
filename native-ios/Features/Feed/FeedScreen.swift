import SwiftUI

struct FeedScreen: View {
    @State private var filter = "ทั้งหมด"
    private var activities: [SampleActivity] {
        SampleActivity.examples.filter { filter == "ทั้งหมด" || (filter == "Running" ? $0.id == "run" : $0.id == "strength") }
    }
    var body: some View {
        P100Screen {
            SampleBanner()
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top) {
                    introduction.fixedSize(horizontal: true, vertical: false)
                    Spacer(minLength: 8)
                    groupsLink.fixedSize(horizontal: true, vertical: false)
                }
                VStack(alignment: .leading, spacing: 16) { introduction; groupsLink }
            }
            ChipPicker(labels: ["ทั้งหมด", "Running", "Strength"], selection: $filter, id: "feed-filter")
            ForEach(activities) { activity in
                ActivityCard(activity: activity).accessibilityIdentifier("activity-\(activity.id)")
            }
            StatusBanner(title: "คุณเลือกเองว่าจะแชร์อะไร", message: "Workout ใหม่จะเป็นส่วนตัว การสร้างโพสต์และปฏิสัมพันธ์จะเปิดใช้หลังระบบบัญชีและความเป็นส่วนตัวพร้อม", symbol: "lock.shield")
        }.navigationTitle("Feed").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    IconLink(title: "ความเป็นส่วนตัวและการแชร์", symbol: "lock.shield") { PrivacyScreen() }
                }
            }
    }
    private var introduction: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("EVERY MOVE COUNTS").font(.caption.bold()).tracking(1.5).foregroundStyle(P100Theme.accent)
                .fixedSize(horizontal: false, vertical: true)
            Text("ไปต่อด้วยกัน").font(P100Type.hero)
                .fixedSize(horizontal: false, vertical: true).accessibilityIdentifier("feed-title")
        }
    }
    private var groupsLink: some View {
        NavigationLink { GroupsScreen() } label: {
            HStack(spacing: 8) {
                Image(systemName: "person.2").font(.system(size: 20, weight: .semibold))
                Text("Groups").font(.subheadline.bold()).fixedSize(horizontal: false, vertical: true)
            }.padding(12).frame(minHeight: 44).background(P100Theme.surface, in: Capsule())
        }.buttonStyle(.plain).accessibilityIdentifier("open-groups")
    }
}
