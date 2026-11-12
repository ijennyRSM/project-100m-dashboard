import SwiftUI

enum P100Theme {
    static let accent = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.64, green: 0.88, blue: 0.73, alpha: 1)
            : UIColor(red: 0.16, green: 0.40, blue: 0.32, alpha: 1)
    })
    static let canvas = Color(uiColor: .systemBackground)
    static let surface = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.075, green: 0.085, blue: 0.08, alpha: 1)
            : UIColor(red: 0.955, green: 0.96, blue: 0.95, alpha: 1)
    })
    static let spacing: CGFloat = 16
    static let radius: CGFloat = 20
    static let dashboardURL = URL(string: "https://ijennyrsm.github.io/project-100m-dashboard/")!
}

struct P100Screen<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: P100Space.section) { content }
                .padding(.horizontal, P100Space.page).padding(.vertical, 12)
                .frame(maxWidth: 620).frame(maxWidth: .infinity)
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
        Label("ตัวอย่างการออกแบบ · ข้อมูลสมมติ", systemImage: "eye")
            .font(.caption).foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityElement(children: .combine)
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
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                ProfileAvatar(initial: String(activity.name.prefix(1)), size: 44)
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(activity.name) · ตัวอย่าง").font(.headline)
                    Text(activity.time).font(.caption).foregroundStyle(.secondary)
                    Label("กิจกรรมสาธารณะสมมติ", systemImage: activity.symbol).font(.caption).foregroundStyle(.secondary)
                }
            }
            Text(activity.title).font(P100Type.section)
            Text(activity.description)
            StatStrip(items: activity.stats)
            if activity.id == "run" {
                RouteIllustration().frame(height: 190).clipShape(RoundedRectangle(cornerRadius: 16))
                    .accessibilityLabel("ภาพเส้นทางสมมติ ไม่มีพิกัดจริง")
            }
            Label("ตัวอย่างเท่านั้น · ยังไม่มี Like หรือ Comment", systemImage: "bubble.left.and.bubble.right")
                .font(.caption).foregroundStyle(.secondary)
            Divider().padding(.top, 4)
        }
    }
}
