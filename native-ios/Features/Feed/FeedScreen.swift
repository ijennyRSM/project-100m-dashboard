import SwiftUI

struct FeedScreen: View {
    @State private var filter = "ทั้งหมด"
    private var activities: [SampleActivity] {
        SampleActivity.examples.filter { filter == "ทั้งหมด" || (filter == "Running" ? $0.id == "run" : $0.id == "strength") }
    }
    var body: some View {
        P100Screen {
            SampleBanner()
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("EVERY MOVE COUNTS").font(.caption.bold()).tracking(1.5).foregroundStyle(P100Theme.accent)
                    Text("ไปต่อด้วยกัน").font(P100Type.hero)
                }
                Spacer(minLength: 8)
                NavigationLink { GroupsScreen() } label: {
                    Label("Groups", systemImage: "person.2").font(.subheadline.bold()).padding(12)
                        .background(P100Theme.surface, in: Capsule())
                }.buttonStyle(.plain).accessibilityIdentifier("open-groups")
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
}
