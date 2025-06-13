import SwiftUI

struct SnapshotView: View {
    @ObservedObject var dataManager: AppDataManager

    private var hrvValue: Double? {
        if let point = dataManager.dataPoints.first(where: { $0.title == "HRV" }) {
            let value = point.value.replacingOccurrences(of: " ms", with: "")
            return Double(value)
        }
        return nil
    }

    var body: some View {
        NavigationStack {
            List {
                if let value = hrvValue {
                    Section {
                        HRVGaugeView(hrv: value)
                            .frame(maxWidth: .infinity)
                    }
                }
                ForEach(dataManager.dataPoints) { point in
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
