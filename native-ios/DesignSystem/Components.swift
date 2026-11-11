import SwiftUI

enum P100Theme {
    static let accent = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.64, green: 0.88, blue: 0.73, alpha: 1)
            : UIColor(red: 0.16, green: 0.40, blue: 0.32, alpha: 1)
    })
    static let canvas = Color(uiColor: .systemGroupedBackground)
    static let surface = Color(uiColor: .secondarySystemGroupedBackground)
    static let spacing: CGFloat = 16
    static let radius: CGFloat = 24
    static let dashboardURL = URL(string: "https://ijennyrsm.github.io/project-100m-dashboard/")!
}

struct P100Screen<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: P100Theme.spacing) { content }
                .padding(P100Theme.spacing).frame(maxWidth: 620).frame(maxWidth: .infinity)
        }.background(P100Theme.canvas)
    }
}

struct P100Card<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 12) { content }
            .padding(20).frame(maxWidth: .infinity, alignment: .leading)
            .background(P100Theme.surface, in: RoundedRectangle(cornerRadius: P100Theme.radius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: P100Theme.radius, style: .continuous)
                    .strokeBorder(.primary.opacity(0.06), lineWidth: 1)
            }
    }
}

struct SectionHeading: View {
    let title: String
    var subtitle: String? = nil
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.title3.bold()).accessibilityAddTraits(.isHeader)
            if let subtitle { Text(subtitle).font(.subheadline).foregroundStyle(.secondary) }
        }
    }
}

struct StatusBanner: View {
    let title: String
    let message: String
    var symbol = "info.circle"
    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.subheadline.bold())
                Text(message).font(.caption).foregroundStyle(.secondary)
            }
        } icon: { Image(systemName: symbol).foregroundStyle(P100Theme.accent) }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
        .background(P100Theme.accent.opacity(0.09), in: RoundedRectangle(cornerRadius: 18))
        .accessibilityElement(children: .combine)
    }
}

struct SampleBanner: View {
    var body: some View {
        StatusBanner(title: "ตัวอย่างหน้าจอ · M0", message: "ข้อมูลสมมติสำหรับดูหน้าตาแอป ยังไม่เชื่อมบัญชี แผนฝึก หรือ Feed จริง", symbol: "eye")
            .accessibilityIdentifier("sample-banner")
    }
}

struct MetricTile: View {
    let title: String
    let value: String
    let unit: String
    var measuredAt: Date? = nil
    var metricID: String = ""
    var body: some View {
        P100Card {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.title2.bold()).monospacedDigit()
            Text(unit).font(.caption).foregroundStyle(.secondary)
            Text("ค่าล่าสุดภายใน 21 วัน").font(.caption).foregroundStyle(.secondary)
            if let date = measuredAt {
                Text("วัดเมื่อ \(date.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }.accessibilityElement(children: .combine)
            .accessibilityIdentifier("metric-\(metricID)")
    }
}

struct ActivityCard: View {
    let activity: SampleActivity
    var body: some View {
        P100Card {
            Label("\(activity.name) · ตัวอย่าง", systemImage: "person.crop.circle.fill").font(.subheadline.bold())
            Text(activity.time).font(.caption).foregroundStyle(.secondary)
            Label(activity.title, systemImage: activity.symbol).font(.title3.bold())
            Text(activity.description)
            Text(activity.summary).font(.headline).foregroundStyle(P100Theme.accent)
            Label("เผยแพร่โดยเจ้าของ · ตัวอย่างเท่านั้น", systemImage: "globe.asia.australia").font(.caption).foregroundStyle(.secondary)
        }
    }
}
