import SwiftUI
import SwiftData

struct ContentView: View {
    @StateObject private var dataManager = AppDataManager()

    var body: some View {
        TabView {
            SnapshotView(dataManager: dataManager)
                .tabItem {
                    Label("Snapshot", systemImage: "waveform.path.ecg")
                }

            ChatView(dataManager: dataManager)
                .tabItem {
                    Label("Chat", systemImage: "bubble.left.and.bubble.right")
                }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
