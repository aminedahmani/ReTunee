import SwiftUI

struct SessionPauseView: View {
    let track: MusicTrack
    let musicEnabled: Bool
    @Binding var volume: Double
    let onResume: () -> Void
    let onFinish: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                Text("Paused")
                    .font(.system(.title2, design: .rounded, weight: .medium))
                    .accessibilityAddTraits(.isHeader)
                VStack(spacing: 20) {
                    Label(track.title, systemImage: "music.note")
                        .font(.system(.headline, design: .rounded))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityIdentifier("pause.track")
                    HStack(spacing: 12) {
                        Image(systemName: !musicEnabled || volume == 0 ? "speaker.slash.fill" : "speaker.fill")
                            .accessibilityHidden(true)
                        Slider(value: $volume, in: 0...1)
                            .disabled(!musicEnabled)
                            .tint(.white).accessibilityLabel(String(localized: "Music volume"))
                            .accessibilityValue(String(localized: "\(Int((volume * 100).rounded())) percent"))
                            .accessibilityHint(musicEnabled ? "" : String(localized: "Turn Music on in Settings to adjust the volume."))
                            .accessibilityIdentifier("pause.volume")
                        Image(systemName: "speaker.wave.3.fill").accessibilityHidden(true)
                    }
                    .frame(minHeight: 44)
                }
                .padding(20).calmSurface(radius: 24)
                VStack(spacing: 24) {
                    Button(action: onResume) {
                        Label("Resume", systemImage: "play.fill")
                            .font(.system(.body, design: .rounded, weight: .semibold))
                            .foregroundStyle(ReTuneTheme.midnight)
                            .frame(maxWidth: .infinity, minHeight: 56)
                            .background(.white, in: Capsule())
                    }
                    .accessibilityIdentifier("pause.resume")
                    Button(action: onFinish) {
                        Text("I feel better")
                            .font(.system(.body, design: .rounded, weight: .medium))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, minHeight: 56)
                            .calmSurface(radius: 28)
                    }
                    .accessibilityHint(String(localized: "Ends this experience and returns to mood selection."))
                    .accessibilityIdentifier("pause.finish")
                }
            }
            .frame(maxWidth: 480)
            .padding(.horizontal, 24).padding(.top, 32).padding(.bottom, 24)
            .frame(maxWidth: .infinity)
        }
        .scrollBounceBehavior(.basedOnSize)
        .buttonStyle(QuietButtonStyle())
        .presentationDetents(dynamicTypeSize.isAccessibilitySize ? [.large] : [.height(500)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(32)
        .presentationBackground(ReTuneTheme.midnight)
        .preferredColorScheme(.dark)
    }
}
