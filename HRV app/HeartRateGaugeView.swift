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
        // Slightly larger to better fill the list card
        .frame(width: 200, height: 200)
    }
}

#Preview {
    HRVGaugeView(hrv: 65)
}
