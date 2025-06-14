import SwiftUI
import SwiftData

struct ContentView: View {
    @StateObject private var dataManager = AppDataManager()
    @StateObject private var settings = UserSettings()

    var body: some View {
        TabView {
            SnapshotView(dataManager: dataManager, settings: settings)
                .tabItem {
                    Label("Snapshot", systemImage: "waveform.path.ecg")
                }

            TrendsView(dataManager: dataManager)
                .tabItem {
                    Label("Trends", systemImage: "chart.line.uptrend.xyaxis")
                }

            ChatView(dataManager: dataManager)
                .tabItem {
                    Label("Chat", systemImage: "bubble.left.and.bubble.right")
                }

            SettingsView(settings: settings)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
