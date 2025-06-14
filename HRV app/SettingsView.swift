import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: UserSettings

    var body: some View {
        Form {
            Toggle("Show HRV", isOn: $settings.showHRV)
            Toggle("Show Resting HR", isOn: $settings.showRestingHR)
            Toggle("Show Sleep", isOn: $settings.showSleep)
            Toggle("Show Mindful Minutes", isOn: $settings.showMindful)
            Toggle("Show Steps", isOn: $settings.showSteps)
            Toggle("Show Active Energy", isOn: $settings.showEnergy)
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    SettingsView(settings: UserSettings())
}
