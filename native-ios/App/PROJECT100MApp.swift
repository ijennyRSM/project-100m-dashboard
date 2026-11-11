import SwiftUI

@main
struct PROJECT100MApp: App {
    @StateObject private var health = HealthKitService()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(health)
                .task { await health.restoreOnLaunch() }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active {
                        Task { await health.refreshIfEnabled() }
                    }
                }
        }
    }
}
