import SwiftUI

// Original SwiftUI components following the owner's screenshot-led activity-app structure:
// flat full-width sections, bold titles and numbers, capsule actions, underline section tabs.
// No third-party logos, artwork, icons or copy; SF Symbols and PROJECT 100M colours only.

/// Thick band separating flat full-width feed/profile sections.
struct SectionBand: View {
    var body: some View {
        Rectangle().fill(P100Theme.surface).frame(height: 8).accessibilityHidden(true)
    }
}

/// Outlined capsule action (profile buttons, secondary "more" actions).
struct OutlineAction: ButtonStyle {
    var accent = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.headline)
            .padding(.horizontal, 16).padding(.vertical, 10).frame(maxWidth: .infinity, minHeight: 46)
            .foregroundStyle(accent ? P100Theme.accent : Color.primary)
            .background(Color.primary.opacity(configuration.isPressed ? 0.08 : 0), in: Capsule())
            .overlay(Capsule().strokeBorder(accent ? P100Theme.accent : Color.primary.opacity(0.35), lineWidth: 1.2))
    }
}

/// Avatar, name, meta and context line above an activity title.
struct ActivityHeader: View {
    let initial: String
    let name: String
    let meta: String
    var context: String? = nil
    var symbol: String = "figure.run"
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ProfileAvatar(initial: initial, size: 48)
            VStack(alignment: .leading, spacing: 3) {
                Text(name).font(.headline)
                Text(meta).font(.subheadline).foregroundStyle(.secondary)
                if let context {
                    Label(context, systemImage: symbol).font(.subheadline).foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }.accessibilityElement(children: .combine)
    }
}

/// Flat activity post: header, bold title, stat columns, optional full-bleed media.
struct ActivityPost<Media: View>: View {
    let header: ActivityHeader
    let title: String
    var description: String? = nil
    let stats: [StatItem]
    var footnote: String? = nil
    @ViewBuilder var media: Media

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 14) {
                header
                Text(title).font(.title2.bold()).fixedSize(horizontal: false, vertical: true)
                if let description, !description.isEmpty { Text(description) }
                if !stats.isEmpty { StatStrip(items: stats) }
                if let footnote {
                    Text(footnote).font(.caption).foregroundStyle(.secondary)
                }
            }.padding(.horizontal, P100Space.page).padding(.vertical, 18)
            media
        }
    }
}

extension ActivityPost where Media == EmptyView {
    init(header: ActivityHeader, title: String, description: String? = nil, stats: [StatItem], footnote: String? = nil) {
        self.init(header: header, title: title, description: description, stats: stats, footnote: footnote) { EmptyView() }
    }
}

/// Underlined section tabs (text or icon-over-text). Buttons keep ChipPicker's `id-label`
/// identifiers and the selected trait.
struct UnderlineTabs: View {
    let labels: [String]
    var symbols: [String]? = nil
    @Binding var selection: String
    var id: String
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        VStack(spacing: 0) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 0) { items(equal: true) }
                ScrollView(.horizontal, showsIndicators: false) { HStack(spacing: 4) { items(equal: false) } }
            }
            Divider()
        }
        // No container identifier: it would mask the per-tab identifiers (ADR-013).
    }

    @ViewBuilder private func items(equal: Bool) -> some View {
        ForEach(Array(labels.enumerated()), id: \.element) { index, label in
            let selected = selection == label
            Button { selection = label } label: {
                VStack(spacing: 6) {
                    if let symbols, symbols.indices.contains(index), !typeSize.isAccessibilitySize {
                        Image(systemName: symbols[index]).font(.system(size: 22, weight: .regular))
                    }
                    Text(label).font(.subheadline.weight(.semibold)).lineLimit(1).fixedSize()
                    Rectangle().fill(selected ? P100Theme.accent : Color.clear).frame(height: 3)
                }
                .padding(.top, 8).padding(.horizontal, equal ? 2 : 14)
                .frame(maxWidth: equal ? .infinity : nil, minHeight: 44)
                .foregroundStyle(selected ? Color.primary : Color.secondary)
                .contentShape(Rectangle())
            }.buttonStyle(.plain)
                .accessibilityIdentifier("\(id)-\(label)")
                .accessibilityAddTraits(selected ? [.isSelected] : [])
        }
    }
}

/// Sport/session start card: icon + large title + chevron row, full-width Start capsule.
struct SessionStartCard<Detail: View, Start: View>: View {
    let symbol: String
    let title: String
    let subtitle: String
    let startLabel: String
    var startID: String
    @ViewBuilder var detail: Detail
    @ViewBuilder var start: Start

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            NavigationLink { detail } label: {
                HStack(alignment: .center, spacing: 14) {
                    Image(systemName: symbol).font(.system(size: 30, weight: .semibold)).frame(width: 40)
                        .foregroundStyle(P100Theme.accent).accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title).font(.title2.bold()).fixedSize(horizontal: false, vertical: true)
                        Text(subtitle).font(.subheadline).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 4)
                    Image(systemName: "chevron.right").font(.title3.weight(.semibold)).foregroundStyle(.secondary)
                }.contentShape(Rectangle())
            }.buttonStyle(.plain)
            NavigationLink { start } label: {
                Label(startLabel, systemImage: "play.fill")
            }.buttonStyle(PrimaryAction()).accessibilityIdentifier(startID)
        }
        .padding(20).frame(maxWidth: .infinity, alignment: .leading)
        .background(P100Theme.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

/// Program tile for horizontal carousels: abstract original artwork, name and summary.
struct ProgramTile: View {
    let template: PlanTemplate
    var isActive = false
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                LinearGradient(colors: [P100Theme.accent.opacity(0.85), P100Theme.accent.opacity(0.35)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                Image(systemName: template.symbol).font(.system(size: 54, weight: .bold))
                    .foregroundStyle(P100Theme.canvas.opacity(0.9))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing).padding(16)
                if isActive || !template.isAvailable {
                    Text(isActive ? "กำลังใช้" : "เร็ว ๆ นี้").font(.caption.bold())
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(.regularMaterial, in: Capsule()).padding(12)
                }
            }.frame(height: 120).clipped().accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(template.name).font(.headline).lineLimit(2).fixedSize(horizontal: false, vertical: true)
                Text(template.isAvailable ? "\(template.blocks) blocks · \(TrainingCatalog.sessions(for: template.id).count) sessions"
                                          : "ยังไม่เปิด")
                    .font(.caption).foregroundStyle(.secondary)
            }.padding(14).frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: 220)
        .background(P100Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

/// List row: icon, title, value line, chevron (profile "More").
struct ListRowLabel: View {
    let symbol: String
    let title: String
    var value: String? = nil
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: symbol).font(.system(size: 22)).frame(width: 32).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.body)
                if let value { Text(value).font(.subheadline).foregroundStyle(.secondary) }
            }
            Spacer(minLength: 8)
            Image(systemName: "chevron.right").foregroundStyle(.secondary).accessibilityHidden(true)
        }
        .padding(.horizontal, P100Space.page).frame(minHeight: 64).contentShape(Rectangle())
    }
}
