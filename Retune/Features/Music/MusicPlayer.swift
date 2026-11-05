import AVFoundation
import MediaPlayer
import Observation
import UIKit

// Audio-session ownership prevents an old preview from silencing a new track.
@MainActor
private final class MusicAudioSession {
    static let shared = MusicAudioSession()
    private var owner: UUID?
    func activate(owner: UUID) throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default)
        try session.setActive(true)
        self.owner = owner
    }
    func deactivate(owner: UUID) {
        guard self.owner == owner else { return }
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        self.owner = nil
    }
}

@Observable @MainActor
final class MusicPlayer: NSObject, AVAudioPlayerDelegate {
    private(set) var trackID: String?
    private(set) var currentTrack: MusicTrack?
    private(set) var isPlaying = false
    private(set) var isInterrupted = false
    private(set) var errorMessage: String?
    private(set) var volume: Double
    private(set) var musicEnabled: Bool
    @ObservationIgnored private let store: UserDefaults
    @ObservationIgnored private var player: AVAudioPlayer?
    @ObservationIgnored private var playbackRequest: UUID?
    @ObservationIgnored private var fadeTask: Task<Void, Never>?
    @ObservationIgnored private var fading: (player: AVAudioPlayer, owner: UUID?, position: TimeInterval)?
    var currentTime: TimeInterval { fading?.position ?? player?.currentTime ?? 0 }
    var duration: TimeInterval { player?.duration ?? 0 }
    var isAudioRunning: Bool { player?.isPlaying ?? fading?.player.isPlaying ?? false }
    var effectiveVolume: Double { musicEnabled ? volume : 0 }

    init(store: UserDefaults = .standard) {
        self.store = store
        let saved = store.object(forKey: "music.volume") as? Double ?? 1
        volume = saved.isFinite ? min(1, max(0, saved)) : 1
        musicEnabled = store.object(forKey: "music.enabled") as? Bool ?? true
        super.init()
        setupRemoteCommands()
        NotificationCenter.default.addObserver(self, selector: #selector(interrupted(_:)),
            name: AVAudioSession.interruptionNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(routeChanged(_:)),
            name: AVAudioSession.routeChangeNotification, object: nil)
    }

    @discardableResult
    func load(_ track: MusicTrack, looping: Bool) -> Bool {
        stop(fade: false)
        errorMessage = nil
        do {
            guard let url = track.url else { throw CocoaError(.fileNoSuchFile) }
            let next = try AVAudioPlayer(contentsOf: url)
            guard next.duration > 0 else { throw CocoaError(.fileReadCorruptFile) }
            next.numberOfLoops = looping ? -1 : 0
            next.delegate = self
            next.volume = 0
            player = next
            trackID = track.id
            currentTrack = track
            return true
        } catch {
            errorMessage = String(localized: "This track couldn’t play. Please choose another.")
            return false
        }
    }

    func setVolume(_ value: Double) {
        guard value.isFinite else { return }
        volume = min(1, max(0, value))
        store.set(volume, forKey: "music.volume")
        musicEnabled = store.object(forKey: "music.enabled") as? Bool ?? true
        if isPlaying { player?.setVolume(Float(effectiveVolume), fadeDuration: 0.08) }
        updateNowPlaying()
    }

    func play() {
        // Settings can change while this player is paused behind its sheet.
        let saved = store.object(forKey: "music.volume") as? Double ?? 1
        volume = saved.isFinite ? min(1, max(0, saved)) : 1
        musicEnabled = store.object(forKey: "music.enabled") as? Bool ?? true
        guard !isPlaying, playbackRequest == nil, !isInterrupted, let player else { return }
        finishFade()
        let request = UUID()
        playbackRequest = request
        do {
            try MusicAudioSession.shared.activate(owner: request)
            guard playbackRequest == request else {
                MusicAudioSession.shared.deactivate(owner: request)
                return
            }
            player.volume = 0
            guard player.play() else { throw CocoaError(.fileReadCorruptFile) }
            // Muting preserves the audio clock and the selected track's pacing.
            player.setVolume(Float(effectiveVolume), fadeDuration: 0.35)
            isPlaying = true
            updateNowPlaying(rate: 1.0)
        } catch {
            guard playbackRequest == request else { return }
            errorMessage = String(localized: "Music couldn’t start. Please try again.")
            pause(fade: false)
        }
    }

    func pause(fade: Bool = true) {
        if !fade { finishFade() }
        guard playbackRequest != nil || isPlaying else { return }
        let owner = playbackRequest
        playbackRequest = nil
        isPlaying = false
        updateNowPlaying(rate: 0.0)
        if fade, let player, player.isPlaying {
            fading = (player, owner, player.currentTime)
            player.setVolume(0, fadeDuration: 0.2)
            // Hold the player through the short fade, even when its view closes.
            fadeTask = Task { [self] in
                do { try await Task.sleep(for: .milliseconds(220)) } catch { return }
                finishFade()
            }
        } else {
            player?.pause()
            releaseSession(owner)
        }
    }

    private func finishFade() {
        fadeTask?.cancel()
        fadeTask = nil
        guard let fading else { return }
        self.fading = nil
        fading.player.pause()
        // Keep the soundtrack aligned with the game, which paused immediately.
        fading.player.currentTime = fading.position
        releaseSession(fading.owner)
    }

    private func releaseSession(_ owner: UUID?) {
        if let owner { MusicAudioSession.shared.deactivate(owner: owner) }
    }

    func stop(fade: Bool = true) {
        pause(fade: fade)
        clearNowPlaying()
        player = nil
        trackID = nil
        currentTrack = nil
        isInterrupted = false
    }

    func clearError() { errorMessage = nil }
    func acknowledgeInterruption() { isInterrupted = false }

    private nonisolated func setupRemoteCommands() {
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, self.player != nil else { return }
                self.acknowledgeInterruption()
                self.play()
            }
            return .success
        }
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, self.player != nil else { return }
                self.pause(fade: true)
            }
            return .success
        }
        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, self.player != nil else { return }
                if self.isPlaying {
                    self.pause(fade: true)
                } else {
                    self.acknowledgeInterruption()
                    self.play()
                }
            }
            return .success
        }
    }

    private nonisolated static func makeArtwork(for image: UIImage) -> MPMediaItemArtwork {
        MPMediaItemArtwork(boundsSize: image.size) { _ in
            image
        }
    }

    private func updateNowPlaying(rate: Float? = nil) {
        guard let track = currentTrack, let player else {
            clearNowPlaying()
            return
        }
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: track.title,
            MPMediaItemPropertyArtist: "ReTune — \(track.mood.title)",
            MPMediaItemPropertyPlaybackDuration: player.duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: player.currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: rate ?? (isPlaying ? 1.0 : 0.0)
        ]
        if let image = UIImage(named: "MoodArtwork-\(track.mood.rawValue)") ?? UIImage(named: "LaunchLogo"),
           image.size.width > 0, image.size.height > 0 {
            info[MPMediaItemPropertyArtwork] = Self.makeArtwork(for: image)
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func clearNowPlaying() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    @objc private func interrupted(_ notification: Notification) {
        guard let raw = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: raw) else { return }
        if type == .began {
            pause(fade: false)
            isInterrupted = true
        }
    }

    @objc private func routeChanged(_ notification: Notification) {
        guard let raw = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
              raw == AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue else { return }
        pause(fade: false)
        isInterrupted = true
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        pause(fade: false)
        player.currentTime = 0
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: (any Error)?) {
        pause(fade: false)
        errorMessage = String(localized: "This track couldn’t play. Please choose another.")
    }
}
