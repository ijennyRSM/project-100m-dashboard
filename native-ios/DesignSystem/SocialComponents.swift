import SwiftUI

enum P100Space {
    static let page: CGFloat = 16
    static let section: CGFloat = 24
    static let small: CGFloat = 8
}

enum P100Type {
    static let hero = Font.largeTitle.weight(.bold)
    static let section = Font.title2.weight(.bold)
    static let number = Font.title2.weight(.semibold)
}

struct ProfileAvatar: View {
    let initial: String
    var size: CGFloat = 64
    var body: some View {
        Text(initial).font(.system(size: size * 0.38, weight: .bold, design: .rounded))
            .frame(width: size, height: size)
            .foregroundStyle(P100Theme.accent)
            .background(P100Theme.accent.opacity(0.12), in: Circle())
            .overlay(Circle().strokeBorder(P100Theme.accent.opacity(0.25)))
            .accessibilityHidden(true)
    }
}

struct StatItem: Identifiable {
    let label: String
    let value: String
    var id: String { label }
}

struct StatStrip: View {
    let items: [StatItem]
    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 20) {
                ForEach(items) { item in stat(item).fixedSize(horizontal: true, vertical: false) }
            }
            VStack(alignment: .leading, spacing: 16) { ForEach(items) { stat($0) } }
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
    private func stat(_ item: StatItem) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.label).font(.caption).foregroundStyle(.secondary)
            Text(item.value).font(P100Type.number).monospacedDigit()
        }.accessibilityElement(children: .combine)
    }
}

struct ChipPicker: View {
    let labels: [String]
    @Binding var selection: String
    var id: String
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(labels, id: \.self) { label in
                    Button { selection = label } label: {
                        Text(label).font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 16).frame(minHeight: 44)
                            .foregroundStyle(selection == label ? P100Theme.accent : Color.primary)
                            .background(selection == label ? P100Theme.accent.opacity(0.1) : P100Theme.surface, in: Capsule())
                            .overlay(Capsule().strokeBorder(selection == label ? P100Theme.accent : Color.primary.opacity(0.15)))
                    }.buttonStyle(.plain)
                        .accessibilityIdentifier("\(id)-\(label)")
                        .accessibilityAddTraits(selection == label ? [.isSelected] : [])
                }
            }.padding(.vertical, 2)
        }.accessibilityIdentifier(id)
    }
}

struct PrimaryAction: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.headline)
            .padding(.horizontal, 20).padding(.vertical, 12).frame(maxWidth: .infinity, minHeight: 48)
            .foregroundStyle(P100Theme.canvas)
            .background(P100Theme.accent.opacity(configuration.isPressed ? 0.75 : 1), in: Capsule())
    }
}

struct IconLink<Destination: View>: View {
    let title: String
    let symbol: String
    @ViewBuilder let destination: Destination
    @Environment(\.accessibilityReduceTransparency) private var opaque
    var body: some View {
        NavigationLink { destination } label: {
            Image(systemName: symbol).font(.system(size: 20, weight: .semibold))
                .frame(width: 44, height: 44)
                .background {
                    if opaque { Circle().fill(P100Theme.surface) }
                    else { Circle().fill(.thinMaterial) }
                }
                .overlay(Circle().strokeBorder(.primary.opacity(0.1)))
        }.buttonStyle(.plain).accessibilityLabel(title)
            .accessibilityShowsLargeContentViewer { Label(title, systemImage: symbol) }
    }
}

/// Original coordinate-free illustration. Never a tile map, location, GPS trace or copied route.
struct RouteIllustration: View {
    var showsCaption = true
    var body: some View {
        Canvas { context, size in
            let rect = CGRect(origin: .zero, size: size)
            context.fill(Path(rect), with: .color(P100Theme.surface))
            for index in 0..<9 {
                let x = CGFloat(index) * size.width / 7
                var street = Path()
                street.move(to: CGPoint(x: x - 50, y: 0))
                street.addLine(to: CGPoint(x: x + 60, y: size.height))
                context.stroke(street, with: .color(.primary.opacity(0.07)), lineWidth: 8)
            }
            for index in 0..<5 {
                let y = CGFloat(index) * size.height / 4
                var street = Path()
                street.move(to: CGPoint(x: 0, y: y))
                street.addLine(to: CGPoint(x: size.width, y: y - 25))
                context.stroke(street, with: .color(.primary.opacity(0.07)), lineWidth: 6)
            }
            var trail = Path()
            trail.move(to: CGPoint(x: size.width * 0.18, y: size.height * 0.75))
            trail.addCurve(to: CGPoint(x: size.width * 0.77, y: size.height * 0.24),
                           control1: CGPoint(x: size.width * 0.15, y: size.height * 0.1),
                           control2: CGPoint(x: size.width * 0.8, y: size.height * 0.9))
            trail.addLine(to: CGPoint(x: size.width * 0.52, y: size.height * 0.18))
            context.stroke(trail, with: .color(P100Theme.accent), style: StrokeStyle(lineWidth: 5, lineCap: .round))
        }
        .overlay(alignment: .bottomLeading) {
            if showsCaption {
                Text("เส้นทางสมมติ · ไม่มีพิกัด").font(.caption2.bold())
                    .padding(8).background(.regularMaterial, in: Capsule()).padding(12)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("ภาพเส้นทางสมมติ ไม่มีพิกัดจริง")
    }
}
