import SwiftUI

struct RhythmGameView: View {
    @State private var model: RhythmGameViewModel
    @State private var music: MusicPlayer
    private let track: MusicTrack
    @State private var showingSettings = false
    @State private var showingPause = false
    @State private var finishAfterPause = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
    private var preferences = UserPreferences()

    init(track: MusicTrack) {
        self.track = track
        let player = MusicPlayer()
        player.load(track, looping: true)
        _music = State(initialValue: player)
        _model = State(initialValue: RhythmGameViewModel(mood: track.mood, trackDuration: player.duration))
    }
    private var reduceMotion: Bool { systemReduceMotion || preferences.reduceMotion }

    var body: some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 1.0 / 15 : 1.0 / 30, paused: !model.pacing.isRunning)) { _ in
            let snapshot = model.pacing.snapshot
            ZStack {
                StarfieldView(theme: preferences.theme,
                              time: preferences.backgroundAnimation && !reduceMotion ? snapshot.activeTime * environmentalPace(snapshot) : 0,
                              intensity: preferences.intensity * environmentalPace(snapshot),
                              warmth: model.mood == .sadness ? snapshot.progress : 0)
                GeometryReader { container in
                    if container.size.width > container.size.height {
                        HStack(spacing: 24) {
                            playfield(snapshot)
                            VStack(spacing: 0) {
                                header
                                Spacer(minLength: 0)
                                footer
                            }
                            .frame(width: min(300, container.size.width * 0.42))
                        }
                        .padding(.horizontal, 24)
                    } else {
                        VStack(spacing: 0) {
                            header
                            playfield(snapshot)
                            footer
                        }
                        .padding(.horizontal, 24)
                    }
                }
            }
            .onChange(of: snapshot.activeTime) { _, _ in model.advance() }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { reconcileActivity() }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { music.pause(fade: false) }
            reconcileActivity()
        }
        .onChange(of: showingSettings) { _, _ in reconcileActivity() }
        .onChange(of: showingPause) { _, _ in reconcileActivity() }
        .onChange(of: model.pacing.isRunning, initial: true) { _, running in
            if running { music.play() } else { music.pause() }
        }
        .onChange(of: music.isInterrupted) { _, interrupted in
            if interrupted {
                if !model.isPaused { model.togglePause() }
                showingPause = true
            }
        }
        .onChange(of: music.errorMessage) { _, error in
            if error != nil { model.setAppActive(false) }
        }
        .onDisappear { music.stop(); model.exit() }
        .alert("Music unavailable", isPresented: Binding(
            get: { music.errorMessage != nil },
            set: { if !$0 { music.clearError() } }
        )) {
            Button("Back to moods", action: endExperience)
        } message: { Text(music.errorMessage ?? "Please choose another track.") }
        .sheet(isPresented: $showingSettings) { SettingsView() }
        .sheet(isPresented: $showingPause, onDismiss: closePausePanel) {
            SessionPauseView(track: track, volume: Binding(get: { music.volume }, set: { music.setVolume($0) }),
                             onResume: { showingPause = false }, onFinish: {
                finishAfterPause = true
                showingPause = false
            })

        }
        .sensoryFeedback(trigger: model.tapEvent) { _, _ in
            preferences.haptics ? .impact(weight: .light, intensity: model.hapticIntensity) : nil
        }
    }
    private func playfield(_ snapshot: PacingSnapshot) -> some View {
        GeometryReader { geometry in
            ZStack {
                if model.mood == .disappointment {
                    ReconstructionView(progress: model.reconstruction, reduceMotion: reduceMotion,
                                       intensity: preferences.intensity)
                        .frame(width: min(geometry.size.width, 300), height: min(geometry.size.height, 300))
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                }
                ForEach(model.echoes) { echo in
                    OrbEchoView(echo: echo, elapsed: snapshot.activeTime, color: model.mood.accent,
                                effect: preferences.effect, reduceMotion: reduceMotion, intensity: preferences.intensity)
                        .position(echo.position)
                }
                if let orb = model.activeOrb {
                    RhythmNodeView(node: orb, mood: model.mood, snapshot: snapshot, reduceMotion: reduceMotion) {
                        model.tap(orbID: orb.id)
                    }
                    .position(orb.position)
                    .disabled(!model.pacing.isRunning)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .onChange(of: geometry.size, initial: true) { _, size in model.updateLayout(size: size) }
        }
        .padding(.vertical, 24)
    }
    private func environmentalPace(_ snapshot: PacingSnapshot) -> Double {
        switch model.mood {
        case .anger, .anxiety, .disappointment: 1 - snapshot.progress * 0.4
        case .sadness: 0.65 + snapshot.progress * 0.35
        }
    }
    private func reconcileActivity() {
        model.setAppActive(scenePhase == .active && !showingSettings && !showingPause && music.errorMessage == nil)
    }
    private func endExperience() {
        music.stop()
        model.exit()
        dismiss()
    }
    private func closePausePanel() {
        if finishAfterPause {
            finishAfterPause = false
            endExperience()
        } else {
            // Resume and swiping the sheet down both continue the same session.
            music.acknowledgeInterruption()
            if model.isPaused { model.togglePause() }
            reconcileActivity()
        }
    }
    private var header: some View {
        HStack(alignment: .center, spacing: 10) {
            Button(action: endExperience) {
                Image(systemName: "chevron.left").frame(width: 44, height: 44).calmSurface(radius: 22)
            }
            .accessibilityLabel("Back to moods")
            .accessibilityHint("Ends this experience and returns to mood selection.")
            .accessibilityIdentifier("game.exit")
            Text(model.mood.title)
                .font(.system(.headline, design: .rounded, weight: .medium))
                .foregroundStyle(model.mood == .sadness ? Color(hex: 0x91A5FF) : model.mood.accent)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 0)
            Button {
                if !model.isPaused { model.togglePause() }
                showingPause = true
            } label: {
                Image(systemName: "pause").frame(width: 44, height: 44).calmSurface(radius: 22)
            }
            .accessibilityLabel("Pause experience")
            .accessibilityValue(track.title)
            .accessibilityIdentifier("game.pause")
            Button { showingSettings = true } label: {
                Image(systemName: "gearshape").frame(width: 44, height: 44).calmSurface(radius: 22)
            }
            .accessibilityLabel("Settings").accessibilityIdentifier("game.settings")
        }
        .padding(.top, 12).padding(.bottom, 8)
    }
    private var footer: some View {
        VStack(spacing: 0) {
            if preferences.stationaryControl || voiceOver {
                Button {
                    if let orb = model.activeOrb { model.tap(orbID: orb.id) }
                } label: {
                    Label("Tap", systemImage: "hand.tap")
                        .font(.body).frame(maxWidth: .infinity).padding(.vertical, 15)
                        .calmSurface(radius: 28)
                }
                .disabled(!model.pacing.isRunning || model.activeOrb == nil)
                .accessibilityLabel("Tap orb")
                .accessibilityHint("Releases the current orb from this fixed button.")
                .accessibilityIdentifier("game.stationaryTap")
            }
        }
        .padding(.bottom, 12).padding(.top, 10)
    }
}
