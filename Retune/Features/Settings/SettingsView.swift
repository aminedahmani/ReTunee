import SwiftUI

struct SettingsView: View {
    private var preferences = UserPreferences()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 17, weight: .medium))
                            .frame(width: 48, height: 48).calmSurface(radius: 24)
                    }
                    .accessibilityLabel("Close settings")
                    .accessibilityIdentifier("settings.close")
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    settingButton("Gentle haptics", symbol: "waveform", isOn: preferences.$haptics, id: "settings.haptics")
                    settingButton("Reduce motion", symbol: "pause.circle", isOn: preferences.$reduceMotion, id: "settings.reduceMotion")
                    settingButton("Animate background", symbol: "sparkles", isOn: preferences.$backgroundAnimation, id: "settings.backgroundAnimation")
                    settingButton("Fixed tap button", symbol: "hand.tap", isOn: preferences.$stationaryControl, id: "settings.stationaryControl")
                }

                VStack(spacing: 24) {
                    settingSlider("Visual intensity", value: preferences.$intensity, range: 0.2...1,
                                  low: "sun.min", high: "sun.max.fill", id: "settings.intensity")
                    settingSlider("Orb glow", value: preferences.$glow, range: 0...1,
                                  low: "circle", high: "sparkle", id: "settings.glow")
                }
                .padding(20).calmSurface(radius: 26)
            }
            .padding(24)
            .frame(maxWidth: 480)
            .frame(maxWidth: .infinity)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(ReTuneTheme.midnight)
        .buttonStyle(QuietButtonStyle())
        .tint(Mood.disappointment.accent)
        .preferredColorScheme(.dark)
        .presentationDragIndicator(.visible)
        .presentationDetents([.large])
    }

    private func settingButton(_ title: String, symbol: String, isOn: Binding<Bool>, id: String) -> some View {
        Button { isOn.wrappedValue.toggle() } label: {
            Image(systemName: symbol)
                .font(.system(size: 30, weight: .regular))
                .foregroundStyle(isOn.wrappedValue ? .white : ReTuneTheme.secondary)
                .frame(maxWidth: .infinity, minHeight: 100)
                .background(isOn.wrappedValue ? Mood.disappointment.accent.opacity(0.2) : .clear,
                            in: RoundedRectangle(cornerRadius: 26))
                .calmSurface(radius: 26)
                .overlay(alignment: .topTrailing) {
                    Image(systemName: isOn.wrappedValue ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(isOn.wrappedValue ? .white : ReTuneTheme.secondary)
                        .padding(12)
                }
        }
        .accessibilityLabel(title)
        .accessibilityValue(isOn.wrappedValue ? "On" : "Off")
        .accessibilityHint("Double-tap to toggle.")
        .accessibilityIdentifier(id)
    }

    private func settingSlider(_ title: String, value: Binding<Double>, range: ClosedRange<Double>,
                               low: String, high: String, id: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: low).frame(width: 24).accessibilityHidden(true)
            Slider(value: value, in: range, step: 0.05)
                .accessibilityLabel(title)
                .accessibilityValue("\(Int((value.wrappedValue * 100).rounded())) percent")
                .accessibilityIdentifier(id)
            Image(systemName: high).frame(width: 24).accessibilityHidden(true)
        }
        .foregroundStyle(.white)
        .frame(minHeight: 44)
    }
}
