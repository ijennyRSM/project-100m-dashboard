import SwiftUI

struct GroupsScreen: View {
    @State private var section = "Events"

    private var heading: String { section == "Events" ? "อีเวนต์" : section == "Clubs" ? "คลับ" : "ชาเลนจ์" }
    private var symbol: String { section == "Events" ? "figure.run" : section == "Clubs" ? "person.3.fill" : "flag.checkered" }
    private var title: String {
        section == "Events" ? "Sunday, slow & steady" : section == "Clubs" ? "The Comeback Club" : "Move a little, every time"
    }

    var body: some View {
        P100Screen(horizontalPadding: 0, spacing: 16) {
            UnderlineTabs(labels: ["Challenges", "Clubs", "Events"], selection: $section, id: "groups-section")
            VStack(alignment: .leading, spacing: 16) {
                SampleBanner()
                Text(heading).font(.title.bold())
                VStack(alignment: .leading, spacing: 0) {
                    ZStack(alignment: .topTrailing) {
                        LinearGradient(colors: [P100Theme.accent.opacity(0.9), P100Theme.accent.opacity(0.3)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                        RouteIllustration(showsCaption: false).opacity(0.35)
                        Image(systemName: symbol).font(.system(size: 72, weight: .bold))
                            .foregroundStyle(P100Theme.canvas.opacity(0.9))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        Text(section == "Events" ? "วันสมมติ" : "ตัวอย่าง").font(.subheadline.bold())
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8)).padding(12)
                    }.frame(height: 200).clipped().accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 8) {
                        Text(title).font(.title3.bold()).accessibilityIdentifier("groups-content-title")
                        Label(section == "Events" ? "สถานที่สมมติ" : "ชุมชนตัวอย่าง", systemImage: "mappin.and.ellipse")
                        Label(section == "Events" ? "5 km · Easy" : section == "Clubs" ? "สำหรับคนเริ่มต้นใหม่" : "ตามจังหวะตัวเอง",
                              systemImage: "figure.run")
                        Label("ยังไม่มีสมาชิกจริง · เข้าร่วมไม่ได้", systemImage: "person.2")
                    }.font(.subheadline).foregroundStyle(.primary).padding(16)
                }
                .background(P100Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                StatusBanner(title: "พื้นที่สำหรับชุมชน", message: "ยังไม่มีสมาชิกจริง กิจกรรมจริง การสมัคร หรือข้อความในแอปนี้")
            }.padding(.horizontal, P100Space.page)
        }.navigationTitle("Groups").navigationBarTitleDisplayMode(.inline)
    }
}
