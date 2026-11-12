import SwiftUI

struct MapsScreen: View {
    @State private var route = "Easy Loop"
    @Environment(\.dynamicTypeSize) private var typeSize
    var body: some View {
        P100Screen(horizontalPadding: 0, spacing: 14) {
            SampleBanner().padding(.horizontal, P100Space.page)
            ZStack(alignment: .top) {
                RouteIllustration(showsCaption: false)
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 10) {
                        Image(systemName: "figure.run").foregroundStyle(P100Theme.accent)
                        Text("Running · ตัวอย่าง").font(.headline)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 16).frame(minHeight: 48)
                    .background(.regularMaterial, in: Capsule())
                    ChipPicker(labels: ["Easy Loop", "Short Loop"], selection: $route, id: "route-filter")
                    Spacer(minLength: 0)
                    if !typeSize.isAccessibilitySize { routeSummary }
                }.padding(12)
            }.frame(height: 520)
            if typeSize.isAccessibilitySize { routeSummary.padding(.horizontal, P100Space.page) }
            VStack(alignment: .leading, spacing: 14) {
                Text("ภาพประกอบไม่มีพิกัด ไม่มีการอ่านตำแหน่งหรือเส้นทางจริง และยังบันทึกเส้นทางไม่ได้")
                    .font(.subheadline).foregroundStyle(.secondary)
                StatusBanner(title: "เส้นทางของคุณเป็นเรื่องส่วนตัว", message: "เมื่อมี GPS จริง การแชร์ต้องยืนยันเองและต้องซ่อนบริเวณที่อ่อนไหวก่อนเผยแพร่", symbol: "location.slash")
            }.padding(.horizontal, P100Space.page)
        }.navigationTitle("Maps").navigationBarTitleDisplayMode(.inline)
    }

    private var routeSummary: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(route).font(P100Type.section).accessibilityIdentifier("route-title")
            StatStrip(items: [StatItem(label: "ระยะสมมติ", value: route == "Easy Loop" ? "3.2 km" : "1.6 km"),
                              StatItem(label: "ความหนัก", value: "Easy")])
        }
        .padding(18).frame(maxWidth: .infinity, alignment: .leading)
        .background(P100Theme.canvas.opacity(0.92), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
