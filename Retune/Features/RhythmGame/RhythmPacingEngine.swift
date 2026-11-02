import Foundation
import Observation

protocol SessionTimeSource {
    func now() -> TimeInterval
}
struct MonotonicTimeSource: SessionTimeSource {
    private let origin = ContinuousClock.now
    func now() -> TimeInterval {
        let parts = origin.duration(to: .now).components
        return Double(parts.seconds) + Double(parts.attoseconds) / 1e18
    }
}

struct PacingSnapshot {
    let activeTime: TimeInterval
    let bpm: Double
    let beats: Double
    let progress: Double
    var acceleratesOrbs = false
    private var revealProgress: Double { acceleratesOrbs ? 1 - progress : progress }
    var orbRevealDelay: TimeInterval { 0.08 + 0.72 * revealProgress }
    var orbFadeDuration: TimeInterval { 0.10 + 0.25 * revealProgress }
    var beatPhase: Double { beats.truncatingRemainder(dividingBy: 1) }
    // Four virtual beats form one gentle breath, rather than a flashing beat cue.
    var breath: Double { (sin(beats * .pi / 2) + 1) / 2 }
}

@Observable @MainActor
final class RhythmPacingEngine {
    let configuration: MoodConfiguration
    private(set) var isRunning = false
    private var accumulated: TimeInterval = 0
    private var resumedAt: TimeInterval = 0
    @ObservationIgnored private let timeSource: any SessionTimeSource

    init(configuration: MoodConfiguration, timeSource: any SessionTimeSource = MonotonicTimeSource()) {
        self.configuration = configuration
        self.timeSource = timeSource
    }
    var snapshot: PacingSnapshot {
        let elapsed = accumulated + (isRunning ? max(0, timeSource.now() - resumedAt) : 0)
        return PacingSnapshot(activeTime: elapsed, bpm: configuration.bpm(at: elapsed),
                              beats: configuration.beats(at: elapsed),
                              progress: configuration.easedProgress(at: elapsed),
                              acceleratesOrbs: configuration.acceleratesOrbs)
    }
    func start() {
        accumulated = 0
        resumedAt = timeSource.now()
        isRunning = true
    }
    func pause() {
        guard isRunning else { return }
        accumulated = snapshot.activeTime
        isRunning = false
    }
    func resume() {
        guard !isRunning else { return }
        resumedAt = timeSource.now()
        isRunning = true
    }
    func stop() {
        isRunning = false
        accumulated = 0
    }
}
