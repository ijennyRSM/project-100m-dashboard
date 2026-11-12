import SwiftUI
import MapKit

/// Fictional sample routes drawn over Apple Maps for presentation. They trace public paths
/// around a public park; they are not anyone's recorded GPS track and never the user's location.
struct SampleRoute: Equatable {
    let name: String
    let place: String
    let distance: String
    let coordinates: [CLLocationCoordinate2D]

    static func == (lhs: SampleRoute, rhs: SampleRoute) -> Bool { lhs.name == rhs.name }

    static let easyLoop = SampleRoute(name: "Easy Loop", place: "รอบสวนลุมพินี · ตัวอย่าง", distance: "2.5 km", coordinates: [
        .init(latitude: 13.7323, longitude: 100.5393), .init(latitude: 13.7334, longitude: 100.5414),
        .init(latitude: 13.7331, longitude: 100.5440), .init(latitude: 13.7312, longitude: 100.5452),
        .init(latitude: 13.7287, longitude: 100.5447), .init(latitude: 13.7271, longitude: 100.5429),
        .init(latitude: 13.7273, longitude: 100.5402), .init(latitude: 13.7296, longitude: 100.5390),
        .init(latitude: 13.7323, longitude: 100.5393)])

    static let shortLoop = SampleRoute(name: "Short Loop", place: "ด้านในสวนลุมพินี · ตัวอย่าง", distance: "1.6 km", coordinates: [
        .init(latitude: 13.7314, longitude: 100.5404), .init(latitude: 13.7321, longitude: 100.5424),
        .init(latitude: 13.7309, longitude: 100.5438), .init(latitude: 13.7290, longitude: 100.5436),
        .init(latitude: 13.7283, longitude: 100.5416), .init(latitude: 13.7295, longitude: 100.5401),
        .init(latitude: 13.7314, longitude: 100.5404)])

    /// Camera rectangle fitting the route with padding.
    var cameraRect: MKMapRect {
        let line = MKPolyline(coordinates: coordinates, count: coordinates.count)
        let rect = line.boundingMapRect
        return rect.insetBy(dx: -rect.size.width * 0.35, dy: -rect.size.height * 0.45)
    }
}

/// Apple Maps basemap with a route line. No location permission; the map never shows or
/// requests the user's position. Map tiles are loaded from Apple's map service.
struct RouteMapView: View {
    let route: SampleRoute
    var position: Binding<MapCameraPosition>? = nil
    var interactive = false

    var body: some View {
        Group {
            if let position {
                Map(position: position, interactionModes: interactive ? .all : []) { content }
            } else {
                Map(initialPosition: .rect(route.cameraRect), interactionModes: interactive ? .all : []) { content }
            }
        }
        .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
        .allowsHitTesting(interactive)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("แผนที่ \(route.place) พร้อมเส้นทางตัวอย่าง ไม่ใช่ตำแหน่งของคุณ")
    }

    @MapContentBuilder private var content: some MapContent {
        MapPolyline(coordinates: route.coordinates)
            .stroke(P100Theme.accent, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
        Annotation("", coordinate: route.coordinates[0]) {
            Circle().fill(P100Theme.accent).frame(width: 14, height: 14)
                .overlay(Circle().strokeBorder(.white, lineWidth: 3))
        }
    }
}
