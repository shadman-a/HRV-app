import Foundation

struct DataPoint: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let timestamp: Date
}
