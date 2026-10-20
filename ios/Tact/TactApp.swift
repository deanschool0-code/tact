import SwiftData
import SwiftUI

@main
struct TactApp: App {
    @StateObject private var app = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(app)
                .environmentObject(app.store)
                .preferredColorScheme(.dark)
                .tint(Theme.accent)
                .task { await app.start() }
        }
        .modelContainer(for: Generation.self)
    }
}

struct RootView: View {
    @AppStorage(Pref.onboarded) private var onboarded = false
    @EnvironmentObject private var app: AppState

    var body: some View {
        Group {
            if onboarded {
                MainTabs()
            } else {
                OnboardingView()
            }
        }
        .sheet(isPresented: $app.showPaywall) {
            PaywallView()
                .environmentObject(app)
                .environmentObject(app.store)
        }
    }
}

struct MainTabs: View {
    var body: some View {
        TabView {
            NavigationStack { HomeView() }
                .tabItem { Label("Write", systemImage: "bubble.left.and.text.bubble.right.fill") }
            NavigationStack { CoachView() }
                .tabItem { Label("Coach", systemImage: "graduationcap.fill") }
            NavigationStack { HistoryView() }
                .tabItem { Label("Saved", systemImage: "clock.arrow.circlepath") }
            NavigationStack { SettingsView() }
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}
