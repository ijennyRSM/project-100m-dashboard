import SwiftUI

/// Material styling compatible with iOS17. This is not the SDK26 glassEffect API.
struct MaterialCapsuleBar: View {
    @Binding var selection: AppTab
    @Environment(\.accessibilityReduceTransparency) private var opaque
    @Environment(\.dynamicTypeSize) private var typeSize
    var body: some View {
        HStack(spacing: 2) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                Button { selection = tab } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.symbol).font(.system(size: 22, weight: .semibold))
                        if !typeSize.isAccessibilitySize {
                            Text(tab.title).font(.caption2.weight(.semibold)).lineLimit(1)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 54)
                    .foregroundStyle(selection == tab ? P100Theme.accent : Color.primary)
                    .background(selection == tab ? P100Theme.canvas.opacity(0.85) : Color.clear, in: Capsule())
                    .contentShape(Capsule())
                }.buttonStyle(.plain)
                    .accessibilityLabel(tab.title)
                    .accessibilityValue(selection == tab ? "selected" : "unselected")
                    .accessibilityAddTraits(selection == tab ? [.isSelected] : [])
                    .accessibilityIdentifier("tab-\(tab.rawValue)")
                    .accessibilityShowsLargeContentViewer { Label(tab.title, systemImage: tab.symbol) }
            }
        }
        .padding(6)
        .background {
            if opaque { Capsule().fill(P100Theme.surface) }
            else { Capsule().fill(.ultraThinMaterial) }
        }
        .overlay(Capsule().strokeBorder(.primary.opacity(0.14), lineWidth: 0.7))
        .shadow(color: .black.opacity(0.12), radius: 16, y: 5)
        .padding(.horizontal, 12).padding(.top, 8).padding(.bottom, 8)
    }
}
