import SwiftUI

struct SettingsView: View {
    private var preferences = UserPreferences()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Sound") {
                    settingToggle("Music", symbol: "speaker.wave.2", color: .blue,
                                  isOn: preferences.$musicEnabled, id: "settings.music")
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Volume")
                        HStack(spacing: 12) {
                            Image(systemName: preferences.musicEnabled && volume.wrappedValue > 0
                                  ? "speaker.fill" : "speaker.slash.fill")
                                .accessibilityHidden(true)
                            Slider(value: volume, in: 0...1)
                                .tint(.blue)
                                .disabled(!preferences.musicEnabled)
                                .accessibilityLabel(String(localized: "Music volume"))
                                .accessibilityValue(String(localized: "\(Int((volume.wrappedValue * 100).rounded())) percent"))
                                .accessibilityHint(preferences.musicEnabled ? "" : String(localized: "Turn Music on to adjust the volume."))
                                .accessibilityIdentifier("settings.volume")
                            Image(systemName: "speaker.wave.3.fill")
                                .accessibilityHidden(true)
                        }
                        .foregroundStyle(.secondary)
                        .frame(minHeight: 44)
                    }
                    .padding(.vertical, 4)
                }

                Section("Experience") {
                    settingToggle("Haptics", symbol: "iphone.radiowaves.left.and.right", color: .orange,
                                  isOn: preferences.$haptics, id: "settings.haptics")
                    settingToggle("Background animation", symbol: "sparkles", color: .purple,
                                  isOn: preferences.$backgroundAnimation, id: "settings.backgroundAnimation")
                }

                Section("Accessibility") {
                    settingToggle("Reduce Motion", symbol: "circle.dotted", color: .blue,
                                  isOn: preferences.$reduceMotion, id: "settings.reduceMotion")
                    settingToggle("Fixed tap button", symbol: "hand.tap", color: .blue,
                                  isOn: preferences.$stationaryControl, id: "settings.stationaryControl")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .accessibilityIdentifier("settings.close")
                }
            }
        }
        .tint(.blue)
        .preferredColorScheme(.dark)
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
    }

    private var volume: Binding<Double> {
        Binding {
            let saved = preferences.musicVolume
            return saved.isFinite ? min(1, max(0, saved)) : 1
        } set: { preferences.musicVolume = $0 }
    }

    private func settingToggle(_ title: LocalizedStringKey, symbol: String, color: Color,
                               isOn: Binding<Bool>, id: String) -> some View {
        Toggle(isOn: isOn) {
            HStack(spacing: 12) {
                Image(systemName: symbol)
                    .font(.system(size: 20))
                    .foregroundStyle(color)
                    .frame(width: 26)
                    .accessibilityHidden(true)
                Text(title)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(minHeight: 44)
        }
        .toggleStyle(.switch)
        .tint(.green)
        .accessibilityIdentifier(id)
    }
}
