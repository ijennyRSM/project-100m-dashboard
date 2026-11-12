import SwiftUI

struct MapsScreen: View {
    @State private var route = "Easy Loop"
    var body: some View {
        P100Screen {
            SampleBanner()
            ChipPicker(labels: ["Easy Loop", "Short Loop"], selection: $route, id: "route-filter")
            ZStack(alignment: .topLeading) {
                RouteIllustration()
                Label("Running · ตัวอย่าง", systemImage: "figure.run")
                    .font(.subheadline.bold()).padding(12)
                    .background(.regularMaterial, in: Capsule()).padding(12)
            }.frame(height: 360).clipShape(RoundedRectangle(cornerRadius: 24))
            P100Card {
                Text(route).font(P100Type.section).accessibilityIdentifier("route-title")
                StatStrip(items: [StatItem(label: "ระยะสมมติ", value: route == "Easy Loop" ? "3.2 km" : "1.6 km"), StatItem(label: "ความหนัก", value: "Easy")])
                Text("ภาพประกอบไม่มีพิกัด ไม่มีการอ่านตำแหน่งหรือเส้นทางจริง และยังบันทึกเส้นทางไม่ได้")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            StatusBanner(title: "เส้นทางของคุณเป็นเรื่องส่วนตัว", message: "เมื่อมี GPS จริง การแชร์ต้องยืนยันเองและต้องซ่อนบริเวณที่อ่อนไหวก่อนเผยแพร่", symbol: "location.slash")
        }.navigationTitle("Maps").navigationBarTitleDisplayMode(.inline)
    }
}
