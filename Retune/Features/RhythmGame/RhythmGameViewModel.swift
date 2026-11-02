import Foundation
import CoreGraphics
import Observation

struct RhythmNodeModel: Identifiable {
    let id = UUID()
    var position: CGPoint
    let appearedAt: TimeInterval
}
struct OrbEcho: Identifiable {
    let id = UUID()
    let position: CGPoint
    let beganAt: TimeInterval
}

@Observable @MainActor
final class RhythmGameViewModel {
    let mood: Mood
    private(set) var pacing: RhythmPacingEngine
    private(set) var activeOrb: RhythmNodeModel?
    private(set) var echoes: [OrbEcho] = []
    private(set) var reconstruction: Double = 0
    private(set) var tapEvent = UUID()
    private(set) var isPaused = false
    private(set) var hasStarted = false
    private(set) var hasExited = false
    private var appIsActive = true
    private var bounds: CGRect = .zero
    private let radius: CGFloat = 58
    private struct PendingReveal {
        let readyAt: TimeInterval
        let previousPosition: CGPoint
    }
    private var pendingReveal: PendingReveal?
    @ObservationIgnored private let timeSource: any SessionTimeSource
    @ObservationIgnored private var spawner: OrbSpawnCoordinator

    init(mood: Mood, trackDuration: TimeInterval? = nil, timeSource: any SessionTimeSource = MonotonicTimeSource(),
         spawner: OrbSpawnCoordinator = .init()) {
        self.mood = mood
        self.timeSource = timeSource
        var configuration = mood.configuration
        if let trackDuration, trackDuration.isFinite, trackDuration > 0 {
            configuration.transitionDuration = trackDuration
        }
        pacing = RhythmPacingEngine(configuration: configuration, timeSource: timeSource)
        self.spawner = spawner
    }
    func restart(trackDuration: TimeInterval) {
        guard !hasExited, trackDuration.isFinite, trackDuration > 0 else { return }
        pacing.stop()
        var configuration = mood.configuration
        configuration.transitionDuration = trackDuration
        pacing = RhythmPacingEngine(configuration: configuration, timeSource: timeSource)
        activeOrb = nil
        pendingReveal = nil
        echoes.removeAll()
        reconstruction = 0
        hasStarted = false
        updateLayout(size: bounds.size)
    }
    func updateLayout(size: CGSize) {
        bounds = CGRect(origin: .zero, size: size)
        guard !hasExited else { return }
        if !hasStarted {
            hasStarted = true
            pacing.start()
            if !appIsActive || isPaused { pacing.pause() }
        }
        // Rotation or layout changes must not bypass a tap's pending wait.
        guard pendingReveal == nil else {
            echoes.removeAll()
            return
        }
        if let orb = activeOrb, spawner.isValid(orb.position, in: bounds, radius: radius) { return }
        activeOrb = makeOrb(avoiding: activeOrb?.position)
        echoes.removeAll()
    }
    private func makeOrb(avoiding position: CGPoint?) -> RhythmNodeModel? {
        guard let next = spawner.position(in: bounds, radius: radius, avoiding: position) else { return nil }
        return RhythmNodeModel(position: next, appearedAt: pacing.snapshot.activeTime)
    }
    @discardableResult
    func tap(orbID: UUID) -> Bool {
        guard !hasExited, pacing.isRunning, let orb = activeOrb, orb.id == orbID else { return false }
        let snapshot = pacing.snapshot
        let now = snapshot.activeTime
        // A valid tap schedules exactly one reveal. Empty-space and duplicate taps do nothing.
        pendingReveal = PendingReveal(readyAt: now + snapshot.orbRevealDelay, previousPosition: orb.position)
        activeOrb = nil
        echoes = Array(echoes.filter { now - $0.beganAt < 0.9 }.suffix(3))
        echoes.append(OrbEcho(position: orb.position, beganAt: now))
        if mood == .disappointment { reconstruction = min(1, reconstruction + 1.0 / 18) }
        tapEvent = UUID()
        return true
    }
    /// Called by the view's existing timeline; no timers or background tasks spawn orbs.
    func advance() {
        guard !hasExited, pacing.isRunning, let pending = pendingReveal,
              pacing.snapshot.activeTime >= pending.readyAt,
              let next = makeOrb(avoiding: pending.previousPosition) else { return }
        activeOrb = next
        pendingReveal = nil
    }
    func setAppActive(_ active: Bool) {
        appIsActive = active
        reconcilePacing()
    }
    func togglePause() {
        guard !hasExited else { return }
        isPaused.toggle()
        reconcilePacing()
    }
    private func reconcilePacing() {
        guard hasStarted, !hasExited else { return }
        if appIsActive && !isPaused { pacing.resume() } else { pacing.pause() }
    }
    func exit() {
        pacing.stop()
        activeOrb = nil
        pendingReveal = nil
        echoes.removeAll()
        hasExited = true
    }
    var hapticIntensity: Double {
        switch mood {
        case .anger, .anxiety: 0.4 - 0.25 * pacing.snapshot.progress
        case .sadness, .disappointment: 0.2
        }
    }
}
