import SwiftUI
import Charts

struct TrendsView: View {
    @ObservedObject var dataManager: AppDataManager

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(dataManager.metricHistories.keys.sorted(), id: \.elf) { key in
                        if let records = dataManager.metricHistories[key] {
                            MetricChartCard(title: key, records: records)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Health Trends")
        }
    }
}

private struct MetricChartCard: View {
    let title: String
    let records: [HealthRecord]

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
                .padding(.leading, 12)
            Chart(records) { rec in
                LineMark(
                    x: .value("Date", rec.date),
                    y: .value("Value", rec.value)
                )
                PointMark(
                    x: .value("Date", rec.date),
                    y: .value("Value", rec.value)
                )
            }
            .chartYScale(domain: scaleDomain)
            .frame(height: 150)
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .padding(.horizontal)
    }

    private var scaleDomain: ClosedRange<Double> {
        let values = records.map { $0.value }
        guard let min = values.min(), let max = values.max(), min != max else {
            let val = values.first ?? 0
            return (val - 1)...(val + 1)
        }
        let range = max - min
        return (min - range * 0.1)...(max + range * 0.1)
    }
}

#Preview {
    TrendsView(dataManager: .preview)
}
