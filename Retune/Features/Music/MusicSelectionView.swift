import SwiftUI

struct MusicSelectionView: View {
    let mood: Mood
    let startLabel: String
    let onStart: (MusicTrack) -> Void
    @State private var selected: MusicTrack
    @State private var preview = MusicPlayer()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    init(mood: Mood, initialTrack: MusicTrack? = nil, startLabel: String = "Start", onStart: @escaping (MusicTrack) -> Void) {
        self.mood = mood
        self.startLabel = startLabel
        self.onStart = onStart
        _selected = State(initialValue: initialTrack ?? MusicTrack.preferred(for: mood))
    }
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(mood.title).font(.system(.headline, design: .rounded))
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark").frame(width: 44, height: 44).calmSurface(radius: 22)
                }
                .accessibilityLabel("Close music selection").accessibilityIdentifier("music.close")
            }
            .padding(.horizontal, 24).padding(.top, 24)
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Choose your music")
                        .font(.system(.title, design: .rounded, weight: .semibold))
                        .accessibilityAddTraits(.isHeader)
                    VStack(spacing: 16) {
                        ForEach(MusicTrack.tracks(for: mood)) { track in trackRow(track) }
                    }
                    if let error = preview.errorMessage {
                        Text(error).font(.callout).foregroundStyle(ReTuneTheme.secondary)
                            .accessibilityIdentifier("music.error")
                    }
                }
                .padding(24).frame(maxWidth: 550).frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
            Button {
                preview.stop(fade: false)
                selected.remember()
                onStart(selected)
            } label: {
                Text(startLabel).font(.system(.headline, design: .rounded))
                    .frame(maxWidth: .infinity).frame(minHeight: 56)
                    .foregroundStyle(ReTuneTheme.midnight).background(.white, in: Capsule())
            }
            .disabled(selected.duration <= 0)
            .accessibilityIdentifier("music.start")
            .padding(24).frame(maxWidth: 550)
        }
        .background(ReTuneTheme.midnight)
        .buttonStyle(QuietButtonStyle())
        .preferredColorScheme(.dark)
        .presentationDetents([.large]).presentationDragIndicator(.visible)
        .onDisappear { preview.stop() }
        .onChange(of: scenePhase) { _, phase in if phase != .active { preview.pause(fade: false) } }
    }
    private func trackRow(_ track: MusicTrack) -> some View {
        let chosen = selected.id == track.id
        let playing = preview.trackID == track.id && preview.isPlaying
        return HStack(spacing: 12) {
            Button {
                if selected.id != track.id { preview.stop() }
                selected = track
                track.remember()
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: chosen ? "checkmark.circle.fill" : "circle")
                        .font(.title2).foregroundStyle(chosen ? .white : ReTuneTheme.secondary)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(track.title).font(.system(.headline, design: .rounded))
                        Text(track.durationLabel).font(.subheadline).foregroundStyle(ReTuneTheme.secondary)
                    }
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, minHeight: 64).contentShape(Rectangle())
            }
            .accessibilityLabel("\(track.title), \(track.durationLabel)")
            .accessibilityValue(chosen ? "Selected" : "Not selected")
            .accessibilityIdentifier("music.select.\(track.number)")
            Button {
                selected = track
                track.remember()
                if playing { preview.pause() }
                else {
                    if preview.trackID != track.id { preview.load(track, looping: false) }
                    preview.acknowledgeInterruption()
                    preview.play()
                }
            } label: {
                Image(systemName: playing ? "pause.fill" : "play.fill")
                    .font(.body).frame(width: 52, height: 52).calmSurface(radius: 26)
            }
            .accessibilityLabel("\(playing ? "Pause" : "Preview") \(track.title)")
            .accessibilityIdentifier("music.preview.\(track.number)")
            .disabled(track.duration <= 0)
        }
        .padding(16).calmSurface(radius: 24)
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(chosen ? mood.accent.opacity(0.7) : .clear, lineWidth: 1))
    }
}
