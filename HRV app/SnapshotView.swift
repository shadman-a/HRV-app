import SwiftUI

struct SnapshotView: View {
    @ObservedObject var dataManager: AppDataManager
    @ObservedObject var settings: UserSettings
    @StateObject private var insightVM: InsightViewModel

    init(dataManager: AppDataManager, settings: UserSettings) {
        self.dataManager = dataManager
        self.settings = settings
        _insightVM = StateObject(wrappedValue: InsightViewModel(dataProvider: { dataManager.dataPoints }))
    }

    private var hrvValue: Double? {
        if let point = dataManager.dataPoints.first(where: { $0.title == "HRV" }) {
            let value = point.value.replacingOccurrences(of: " ms", with: "")
            return Double(value)
        }
        return nil
    }

    private func shouldShow(_ title: String) -> Bool {
        switch title {
        case "HRV": return settings.showHRV
        case "Resting HR": return settings.showRestingHR
        case "Sleep": return settings.showSleep
        case "Mindful Minutes": return settings.showMindful
        case "Steps": return settings.showSteps
        case "Active Energy": return settings.showEnergy
        default: return true
        }
    }

    var body: some View {
        NavigationStack {
            List {
                InsightCardView(viewModel: insightVM)
                    .listRowInsets(EdgeInsets())
                if let value = hrvValue, settings.showHRV {
                    HRVGaugeView(hrv: value)
                        .frame(maxWidth: .infinity)
                        .listRowInsets(EdgeInsets())
                }
                ForEach(dataManager.dataPoints.filter { shouldShow($0.title) }) { point in
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
    SnapshotView(dataManager: AppDataManager(), settings: UserSettings())
}
