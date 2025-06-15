import Foundation

/// Generic health data record used for trend charts.
struct HealthRecord: Identifiable, Codable {
    let id = UUID()
    let date: Date
    let value: Double
}
