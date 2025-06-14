import Foundation
import SwiftUI
import Combine

@MainActor
class UserSettings: ObservableObject {
    @AppStorage("showHRV") var showHRV: Bool = true
    @AppStorage("showRestingHR") var showRestingHR: Bool = true
    @AppStorage("showSleep") var showSleep: Bool = true
    @AppStorage("showMindful") var showMindful: Bool = true
    @AppStorage("showSteps") var showSteps: Bool = true
    @AppStorage("showEnergy") var showEnergy: Bool = true
}
