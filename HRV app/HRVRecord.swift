import Foundation

struct HRVRecord: Identifiable, Codable {
    let id = UUID()
    let date: Date
    let value: Int
}
