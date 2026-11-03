import Testing
import Foundation
import AVFoundation
@testable import Retune

@Suite(.serialized) @MainActor struct MusicTests {
    @Test func allTwelveTracksAreBundledAndHaveRealDurations() throws {
        #expect(MusicTrack.all.count == 12)
        for mood in Mood.allCases {
            let tracks = MusicTrack.tracks(for: mood)
            #expect(tracks.map(\.number) == [1, 2, 3])
            for track in tracks {
                let url = try #require(track.url)
                let audio = try AVAudioPlayer(contentsOf: url)
                #expect(audio.prepareToPlay())
                #expect(track.duration > 0)
                #expect(abs(track.duration - audio.duration) < 0.001)
                let model = RhythmGameViewModel(mood: mood, trackDuration: track.duration)
                #expect(model.pacing.configuration.transitionDuration == audio.duration)
            }
        }
    }
    @Test func selectionsRememberedIndependentlyPerMood() throws {
        let name = "MusicTests-\(UUID())"
        let store = try #require(UserDefaults(suiteName: name))
        defer { store.removePersistentDomain(forName: name) }
        let anxiety = MusicTrack.tracks(for: .anxiety)[2]
        let sadness = MusicTrack.tracks(for: .sadness)[1]
        anxiety.remember(in: store)
        sadness.remember(in: store)
        #expect(MusicTrack.preferred(for: .anxiety, store: store) == anxiety)
        #expect(MusicTrack.preferred(for: .sadness, store: store) == sadness)
        #expect(MusicTrack.preferred(for: .anger, store: store).number == 1)
    }
    @Test func playbackSwitchPauseAndStop() async throws {
        let player = MusicPlayer()
        let tracks = MusicTrack.tracks(for: .anger)
        #expect(player.load(tracks[0], looping: false))
        player.play()
        for _ in 0..<50 {
            if player.isPlaying { break }
            try await Task.sleep(for: .milliseconds(20))
        }
        #expect(player.isPlaying)
        player.pause()
        #expect(!player.isPlaying)
        #expect(player.trackID == tracks[0].id)
        #expect(player.load(tracks[1], looping: true))
        #expect(!player.isPlaying)
        #expect(player.currentTime == 0)
        #expect(player.trackID == tracks[1].id)
        player.play()
        for _ in 0..<50 {
            if player.isPlaying { break }
            try await Task.sleep(for: .milliseconds(20))
        }
        #expect(player.isPlaying)
        player.stop()
        #expect(!player.isPlaying)
        #expect(player.trackID == nil)
        #expect(player.errorMessage == nil)
    }
    @Test func volumePersistsAndStaysWithinRange() throws {
        let name = "VolumeTests-\(UUID())"
        let store = try #require(UserDefaults(suiteName: name))
        defer { store.removePersistentDomain(forName: name) }
        let player = MusicPlayer(store: store)
        player.setVolume(0.27)
        #expect(MusicPlayer(store: store).volume == 0.27)
        player.setVolume(4)
        #expect(player.volume == 1)
        player.setVolume(-1)
        #expect(player.volume == 0)
        player.setVolume(.nan)
        #expect(player.volume == 0)
    }
    @Test func playbackReloadsVolumeChangedInSettings() async throws {
        let name = "SettingsVolumeTests-\(UUID())"
        let store = try #require(UserDefaults(suiteName: name))
        defer { store.removePersistentDomain(forName: name) }
        store.set(0.8, forKey: "music.volume")
        let player = MusicPlayer(store: store)
        defer { player.stop(fade: false) }
        #expect(player.load(MusicTrack.tracks(for: .anxiety)[0], looping: true))
        // Settings can change the shared level after the game created its player.
        store.set(0.35, forKey: "music.volume")
        player.play()
        for _ in 0..<100 {
            if player.isPlaying { break }
            try await Task.sleep(for: .milliseconds(20))
        }
        #expect(player.isPlaying)
        #expect(player.volume == 0.35)
    }
    @Test func fadePausesAtTheRightPositionAndCannotCancelAQuickResume() async throws {
        let player = MusicPlayer()
        #expect(player.load(MusicTrack.tracks(for: .anxiety)[0], looping: true))
        player.play()
        for _ in 0..<100 {
            if player.isPlaying { break }
            try await Task.sleep(for: .milliseconds(20))
        }
        #expect(player.isAudioRunning)
        try await Task.sleep(for: .milliseconds(80))
        player.pause()
        let pausedAt = player.currentTime
        #expect(!player.isPlaying)
        #expect(player.isAudioRunning)
        try await Task.sleep(for: .milliseconds(300))
        #expect(!player.isAudioRunning)
        #expect(abs(player.currentTime - pausedAt) < 0.01)
        player.play()
        for _ in 0..<100 {
            if player.isPlaying { break }
            try await Task.sleep(for: .milliseconds(20))
        }
        player.pause()
        player.play()
        try await Task.sleep(for: .milliseconds(500))
        #expect(player.isPlaying)
        #expect(player.isAudioRunning)
        player.stop(fade: false)
        #expect(!player.isAudioRunning)
    }

    @Test func muteKeepsPlaybackClockAndRestoresSavedLevel() async throws {
        let name = "MuteTests-\(UUID())"
        let store = try #require(UserDefaults(suiteName: name))
        defer { store.removePersistentDomain(forName: name) }
        store.set(0.42, forKey: "music.volume")
        store.set(false, forKey: "music.enabled")
        let player = MusicPlayer(store: store)
        defer { player.stop(fade: false) }
        let track = MusicTrack.tracks(for: .sadness)[0]
        #expect(player.load(track, looping: false))
        player.play()
        for _ in 0..<100 {
            if player.isPlaying { break }
            try await Task.sleep(for: .milliseconds(20))
        }
        #expect(player.isAudioRunning)
        #expect(player.effectiveVolume == 0)
        try await Task.sleep(for: .milliseconds(100))
        #expect(player.currentTime > 0)
        player.setVolume(0.31)
        #expect(player.effectiveVolume == 0)
        #expect(player.volume == 0.31)
        player.pause(fade: false)
        let pausedAt = player.currentTime
        store.set(true, forKey: "music.enabled")
        player.play()
        for _ in 0..<100 {
            if player.isPlaying { break }
            try await Task.sleep(for: .milliseconds(20))
        }
        #expect(player.isAudioRunning)
        #expect(player.effectiveVolume == 0.31)
        #expect(player.trackID == track.id)
        #expect(player.currentTime >= pausedAt)
    }

}
