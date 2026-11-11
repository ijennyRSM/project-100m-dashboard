import SwiftUI

@main
@MainActor
struct PROJECT100MApp: App {
    @StateObject private var health: HealthKitService
    @Environment(\.scenePhase) private var scenePhase

    init() {
        UITestConfiguration.resetIfRequested()
        _health = StateObject(wrappedValue: UITestConfiguration.makeHealthService())
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .modifier(UITestPresentation())
                .environmentObject(health)
                .task {
                    if !UITestConfiguration.enabled {
                        await health.restoreOnLaunch()
                    }
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active && !UITestConfiguration.enabled {
                        Task { await health.refreshIfEnabled() }
                    }
                }
        }
    }
}
