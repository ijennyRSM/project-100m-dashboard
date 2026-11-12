import SwiftUI

@main
@MainActor
struct PROJECT100MApp: App {
    @StateObject private var health: HealthKitService
    @StateObject private var account: AccountModel
    @StateObject private var training: TrainingModel
    @Environment(\.scenePhase) private var scenePhase

    init() {
        UITestConfiguration.resetIfRequested()
        _health = StateObject(wrappedValue: UITestConfiguration.makeHealthService())
        _account = StateObject(wrappedValue: UITestConfiguration.makeAccount())
        _training = StateObject(wrappedValue: UITestConfiguration.makeTraining())
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .modifier(UITestPresentation())
                .environmentObject(health)
                .environmentObject(account)
                .environmentObject(training)
                .task {
                    // Restore the Keychain session first so the correct account partition opens.
                    await account.restore()
                    training.switchScope(account.scope)
                    if !UITestConfiguration.enabled {
                        await health.restoreOnLaunch()
                    }
                }
                .onChange(of: account.user) { _, _ in
                    if account.phase != .restoring { training.switchScope(account.scope) }
                }
                .onOpenURL { url in
                    // project100m://auth-callback works only if the owner allow-lists it in Supabase Auth.
                    Task { await account.complete(linkText: url.absoluteString) }
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active && !UITestConfiguration.enabled {
                        Task { await health.refreshIfEnabled() }
                    }
                }
        }
    }
}
