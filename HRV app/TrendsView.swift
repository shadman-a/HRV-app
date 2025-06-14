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
    let dm = AppDataManager()
    dm.hrvHistory = [
        HRVRecord(date: .now.addingTimeInterval(-3600*24*4), value: 60),
        HRVRecord(date: .now.addingTimeInterval(-3600*24*3), value: 55),
        HRVRecord(date: .now.addingTimeInterval(-3600*24*2), value: 70),
        HRVRecord(date: .now.addingTimeInterval(-3600*24), value: 65)
    ]
    TrendsView(dataManager: dm)
}
