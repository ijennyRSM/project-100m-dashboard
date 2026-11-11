import SwiftUI

enum AppTab: String, CaseIterable {
    case feed, today, train, health, me
    var title: String { rawValue.capitalized }
    var symbol: String {
        switch self {
        case .feed: return "rectangle.stack"
        case .today: return "sun.max"
        case .train: return "figure.run"
        case .health: return "heart.text.square"
        case .me: return "person.crop.circle"
        }
    }
}

struct RootView: View {
    @AppStorage("project100m.selectedTab") private var storedTab = AppTab.today.rawValue
    @State private var feedPath = NavigationPath()
    @State private var todayPath = NavigationPath()
    @State private var trainPath = NavigationPath()
    @State private var healthPath = NavigationPath()
    @State private var mePath = NavigationPath()
    private var selection: Binding<AppTab> {
        Binding(get: { AppTab(rawValue: storedTab) ?? .today }, set: { storedTab = $0.rawValue })
    }
    var body: some View {
        TabView(selection: selection) {
            NavigationStack(path: $feedPath) { FeedScreen() }
                .tabItem { Label(AppTab.feed.title, systemImage: AppTab.feed.symbol) }.tag(AppTab.feed)
            NavigationStack(path: $todayPath) { TodayScreen() }
                .tabItem { Label(AppTab.today.title, systemImage: AppTab.today.symbol) }.tag(AppTab.today)
            NavigationStack(path: $trainPath) { TrainingScreen() }
                .tabItem { Label(AppTab.train.title, systemImage: AppTab.train.symbol) }.tag(AppTab.train)
            NavigationStack(path: $healthPath) { HealthScreen() }
                .tabItem { Label(AppTab.health.title, systemImage: AppTab.health.symbol) }.tag(AppTab.health)
            NavigationStack(path: $mePath) { MeScreen() }
                .tabItem { Label(AppTab.me.title, systemImage: AppTab.me.symbol) }.tag(AppTab.me)
        }.tint(P100Theme.accent)
    }
}

#Preview { RootView().environmentObject(HealthKitService()) }
