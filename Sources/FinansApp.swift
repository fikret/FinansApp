import SwiftUI

@main
struct FinansApp: App {
    @StateObject private var appState = AppState()
    @State private var isOnboardingComplete = UserDefaults.standard.bool(forKey: "onboarding_completed")

    var body: some Scene {
        WindowGroup {
            if isOnboardingComplete {
                ContentView()
                    .environmentObject(appState)
            } else {
                OnboardingView(isOnboardingComplete: $isOnboardingComplete)
                    .environmentObject(appState)
            }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: isOnboardingComplete ? 1200 : 600, height: isOnboardingComplete ? 800 : 500)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
