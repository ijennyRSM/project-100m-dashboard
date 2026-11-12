import SwiftUI
import MapKit

/// Full-screen Apple Maps view with sample routes. No location permission or GPS: the camera
/// only frames the selected sample route.
struct MapsScreen: View {
    @State private var route = "Easy Loop"
    @State private var position = MapCameraPosition.rect(SampleRoute.easyLoop.cameraRect)
    @Environment(\.dynamicTypeSize) private var typeSize

    private var selected: SampleRoute { route == "Easy Loop" ? .easyLoop : .shortLoop }

    var body: some View {
        ZStack(alignment: .top) {
            RouteMapView(route: selected, position: $position, interactive: true)
                .ignoresSafeArea(edges: .bottom)
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: "figure.run").foregroundStyle(P100Theme.accent)
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Running · เส้นทางตัวอย่าง").font(.headline)
                        Text("ไม่ใช้ตำแหน่งของคุณ").font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 16).padding(.vertical, 6).frame(minHeight: 48)
                .background(.regularMaterial, in: Capsule())
                SampleBanner().padding(.horizontal, 12).padding(.vertical, 6)
                    .background(.regularMaterial, in: Capsule())
                ChipPicker(labels: ["Easy Loop", "Short Loop"], selection: $route, id: "route-filter")
                Spacer(minLength: 0)
                HStack {
                    Spacer()
                    Button { recenter() } label: {
                        Image(systemName: "scope").font(.system(size: 20, weight: .semibold))
                            .frame(width: 48, height: 48).background(.regularMaterial, in: Circle())
                    }.buttonStyle(.plain).accessibilityLabel("กลับไปที่เส้นทาง").accessibilityIdentifier("map-recenter")
                }
                routeSummary
            }.padding(12)
        }
        .navigationTitle("Maps").navigationBarTitleDisplayMode(.inline)
        .onChange(of: route) { _, _ in recenter() }
    }

    private func recenter() {
        withAnimation { position = .rect(selected.cameraRect) }
    }

    private var routeSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(route).font(P100Type.section).accessibilityIdentifier("route-title")
            Label(selected.place, systemImage: "mappin.and.ellipse").font(.subheadline).foregroundStyle(.secondary)
            if !typeSize.isAccessibilitySize {
                StatStrip(items: [StatItem(label: "ระยะโดยประมาณ", value: selected.distance), StatItem(label: "ความหนัก", value: "Easy")])
            } else {
                Text("\(selected.distance) · Easy").font(.headline)
            }
            Text("แผนที่จาก Apple Maps · ยังบันทึกเส้นทางหรือนำทางไม่ได้").font(.caption).foregroundStyle(.secondary)
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
        .background(P100Theme.canvas.opacity(0.94), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
