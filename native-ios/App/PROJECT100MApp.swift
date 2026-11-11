import SwiftUI

@main
struct PROJECT100MApp: App {
    @StateObject private var health = HealthKitService()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(health)
                .task {
                    if !ProcessInfo.processInfo.arguments.contains("--ui-testing") {
                        await health.restoreOnLaunch()
                    }
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active && !ProcessInfo.processInfo.arguments.contains("--ui-testing") {
                        Task { await health.refreshIfEnabled() }
                    }
                }
        }
    }
}
