import SwiftUI

struct HeartRateGaugeView: View {
    let heartRate: Double

    var body: some View {
        Gauge(value: heartRate, in: 40...120) {
            Text("Resting HR")
        } currentValueLabel: {
            Text("\(Int(heartRate)) bpm")
                .font(.headline)
        }
        .gaugeStyle(.accessoryCircular)
        .tint(AngularGradient(
            gradient: Gradient(colors: [.green, .yellow, .orange, .red]),
            center: .center)
        )
        .frame(width: 150, height: 150)
    }
}

#Preview {
    HeartRateGaugeView(heartRate: 65)
}
