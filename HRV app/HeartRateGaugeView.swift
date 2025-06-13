import SwiftUI

/// Circular gauge to visualize Heart Rate Variability (HRV).
struct HRVGaugeView: View {
    /// HRV value in milliseconds
    let hrv: Double

    var body: some View {
        Gauge(value: hrv, in: 0...200) {
            Text("HRV")
        } currentValueLabel: {
            Text("\(Int(hrv)) ms")
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

/// Circular gauge to visualize Resting Heart Rate.
struct HeartRateGaugeView: View {
    /// Resting heart rate in beats per minute
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
    VStack {
        HRVGaugeView(hrv: 65)
        HeartRateGaugeView(heartRate: 60)
    }
}
