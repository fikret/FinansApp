import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationSplitView {
            SidebarView()
        } detail: {
            Group {
                switch appState.selectedNav {
                case .dashboard:
                    DashboardView()
                case .statements:
                    StatementsView()
                case .transactions:
                    TransactionsView()
                case .cards:
                    CardsView()
                case .comparison:
                    ComparisonView()
                case .insights:
                    InsightsView()
                case .settings:
                    SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationSplitViewStyle(.balanced)
    }
}

struct SidebarView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        List(NavigationItem.allCases, selection: $appState.selectedNav) { item in
            Label(item.rawValue, systemImage: item.icon)
                .tag(item)
        }
        .listStyle(.sidebar)
        .navigationTitle("FinansApp")
        .frame(minWidth: 200)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
