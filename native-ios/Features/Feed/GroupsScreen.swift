import SwiftUI

struct GroupsScreen: View {
    @State private var section = "Events"
    var body: some View {
        P100Screen {
            SampleBanner()
            ChipPicker(labels: ["Events", "Clubs", "Challenges"], selection: $section, id: "groups-section")
            Text(section == "Events" ? "นัดกันไปขยับ" : section == "Clubs" ? "หาจังหวะเดียวกัน" : "เป้าหมายเล็ก ๆ ของเรา")
                .font(P100Type.hero)
            P100Card {
                ZStack {
                    RoundedRectangle(cornerRadius: 16).fill(P100Theme.accent.opacity(0.12))
                    VStack(spacing: 12) {
                        Image(systemName: section == "Events" ? "figure.run.circle" : section == "Clubs" ? "person.2.circle" : "flag.checkered.circle")
                            .font(.system(size: 64, weight: .light)).foregroundStyle(P100Theme.accent)
                        Text("100M COMMUNITY").font(.caption.bold()).tracking(2)
                    }.padding(24)
                }.frame(height: 170).accessibilityHidden(true)
                Text(section == "Events" ? "Sunday, slow & steady" : section == "Clubs" ? "The Comeback Club" : "Move a little, every time")
                    .font(P100Type.section).accessibilityIdentifier("groups-content-title")
                Text(section == "Events" ? "นัดวิ่งเบา ๆ · วันและสถานที่สมมติ" : section == "Clubs" ? "กลุ่มตัวอย่างสำหรับคนเริ่มต้นใหม่" : "สะสมการเคลื่อนไหวตามจังหวะตัวเอง")
                    .foregroundStyle(.secondary)
                Label("ตัวอย่างการออกแบบ · ยังเข้าร่วมหรือติดต่อไม่ได้", systemImage: "eye").font(.caption).foregroundStyle(.secondary)
            }
            StatusBanner(title: "พื้นที่สำหรับชุมชน", message: "ยังไม่มีสมาชิกจริง กิจกรรมจริง การสมัคร หรือข้อความในแอปนี้")
        }.navigationTitle("Groups").navigationBarTitleDisplayMode(.inline)
    }
}
