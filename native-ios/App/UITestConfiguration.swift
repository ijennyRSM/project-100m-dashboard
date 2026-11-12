import SwiftUI

#if DEBUG
enum HealthTestState: String { case notRequested, unavailable, failed, missing, loading, stale }
#endif

/// All overrides are DEBUG-only and require an explicit UI-testing launch.
enum UITestConfiguration {
    static var enabled: Bool {
        #if DEBUG
        return ProcessInfo.processInfo.arguments.contains("--ui-testing")
        #else
        return false
        #endif
    }
    static func argument(_ name: String) -> String? {
        guard enabled else { return nil }
        return ProcessInfo.processInfo.arguments.first { $0.hasPrefix(name + "=") }?.split(separator: "=", maxSplits: 1).last.map(String.init)
    }
    static var healthWidth: CGFloat? { argument("--ui-content-width").flatMap(Double.init).map { CGFloat(min(393, max(320, $0))) } }
    static func resetIfRequested() {
        if enabled && ProcessInfo.processInfo.arguments.contains("--ui-reset") {
            UserDefaults.standard.removeObject(forKey: "project100m.selectedTab")
        }
    }
    /// UI testing never contacts Supabase and uses an isolated, resettable training directory.
    @MainActor static func makeAccount() -> AccountModel {
        enabled ? AccountModel.uiTesting() : AccountModel.live()
    }
    @MainActor static func makeTraining() -> TrainingModel {
        if enabled {
            return TrainingModel(root: TrainingModel.uiTestingRoot(reset: ProcessInfo.processInfo.arguments.contains("--ui-reset")))
        }
        return TrainingModel(root: TrainingModel.liveRoot())
    }
    @MainActor static func makeHealthService() -> HealthKitService {
        #if DEBUG
        if enabled { return HealthKitService(testState: HealthTestState(rawValue: argument("--ui-health-state") ?? "missing") ?? .missing) }
        #endif
        return HealthKitService()
    }
}

struct UITestPresentation: ViewModifier {
    func body(content: Content) -> some View {
        if UITestConfiguration.enabled {
            content
                .preferredColorScheme(UITestConfiguration.argument("--ui-theme") == "dark" ? .dark : .light)
                .environment(\.dynamicTypeSize, textSize)
        } else { content }
    }
    private var textSize: DynamicTypeSize {
        switch UITestConfiguration.argument("--ui-text-size") {
        case "AX5": return .accessibility5
        case "xLarge": return .xLarge
        default: return .large
        }
    }
}
