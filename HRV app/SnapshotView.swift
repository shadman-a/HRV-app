import SwiftUI

struct SnapshotView: View {
    @ObservedObject var dataManager: AppDataManager

    var body: some View {
        NavigationStack {
            List(dataManager.dataPoints) { point in
                VStack(alignment: .leading, spacing: 4) {
                    Text(point.title)
                        .font(.headline)
                    Text(point.value)
                        .font(.subheadline)
                    Text(point.timestamp, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(4)
            }
            .navigationTitle("Health Snapshot")
            .onAppear {
                dataManager.requestAuthorization()
            }
            .refreshable {
                await dataManager.refreshAll()
            }
        }
    }
}

#Preview {
    SnapshotView(dataManager: AppDataManager())
}
