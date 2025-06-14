import SwiftUI
import Charts

struct TrendsView: View {
    @ObservedObject var dataManager: AppDataManager

    var body: some View {
        NavigationStack {
            Chart(dataManager.hrvHistory) { record in
                LineMark(
                    x: .value("Date", record.date),
                    y: .value("HRV", record.value)
                )
            }
            .chartYScale(domain: 0...200)
            .padding()
            .navigationTitle("HRV Trends")
        }
    }
}

#Preview {
    TrendsView(dataManager: .preview)
}
