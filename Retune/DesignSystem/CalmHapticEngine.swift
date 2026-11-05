import CoreHaptics
import UIKit

/// An organic, sensory haptic engine that pairs rhythmic touch and breathing
/// with custom physical feedback, falling back gracefully to UIImpactFeedback.
@MainActor
final class CalmHapticEngine {
    static let shared = CalmHapticEngine()

    private var engine: CHHapticEngine?
    private var isSupported: Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        return CHHapticEngine.capabilitiesForHardware().supportsHaptics
        #endif
    }
    private let fallback = UIImpactFeedbackGenerator(style: .soft)
    private var isEngineRunning = false

    private init() {
        setupEngine()
    }

    private func setupEngine() {
        guard isSupported else { return }
        #if !targetEnvironment(simulator)
        do {
            let eng = try CHHapticEngine()
            eng.resetHandler = { [weak self] in
                Task { @MainActor in
                    self?.restartEngine()
                }
            }
            eng.stoppedHandler = { [weak self] _ in
                Task { @MainActor in
                    self?.isEngineRunning = false
                }
            }
            try eng.start()
            self.engine = eng
            self.isEngineRunning = true
        } catch {
            self.engine = nil
            self.isEngineRunning = false
        }
        #endif
    }

    private func restartEngine() {
        guard isSupported, let engine else { return }
        #if !targetEnvironment(simulator)
        do {
            try engine.start()
            isEngineRunning = true
        } catch {
            isEngineRunning = false
        }
        #endif
    }

    func ensureRunning() {
        guard isSupported else { return }
        if !isEngineRunning {
            restartEngine()
        }
    }

    func stop() {
        guard isSupported else { return }
        #if !targetEnvironment(simulator)
        engine?.stop()
        #endif
        isEngineRunning = false
    }

    /// Plays a luminous, gentle tap when an orb is released.
    func playOrbTap(energy: Double = 1.0) {
        guard isSupported, let engine else {
            #if !targetEnvironment(simulator)
            fallback.impactOccurred(intensity: CGFloat(max(0.2, min(1.0, energy))))
            #endif
            return
        }

        #if !targetEnvironment(simulator)
        ensureRunning()

        let intensityValue = Float(min(1.0, max(0.35, 0.4 + energy * 0.45)))
        let sharpnessValue = Float(min(1.0, max(0.25, 0.3 + energy * 0.4)))

        let transient = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensityValue),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpnessValue)
            ],
            relativeTime: 0
        )

        let resonance = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(0.22 * energy)),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.15)
            ],
            relativeTime: 0.012,
            duration: 0.09
        )

        do {
            let pattern = try CHHapticPattern(events: [transient, resonance], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            fallback.impactOccurred(intensity: CGFloat(energy))
        }
        #endif
    }

    /// Plays a subtle, soothing tactile swell matching the expansion or contraction of the breathing cycle.
    func playBreathSwell(inhale: Bool) {
        guard isSupported, let engine else { return }

        #if !targetEnvironment(simulator)
        ensureRunning()

        let intensity = Float(inhale ? 0.22 : 0.14)
        let event = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.1)
            ],
            relativeTime: 0,
            duration: 0.22
        )

        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {}
        #endif
    }

    /// Plays a soft, harmonious resolution pulse when concluding a session ("I feel better").
    func playSessionCompletion() {
        guard isSupported, let engine else {
            #if !targetEnvironment(simulator)
            fallback.impactOccurred(intensity: 0.85)
            #endif
            return
        }

        #if !targetEnvironment(simulator)
        ensureRunning()

        let first = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.35)
            ],
            relativeTime: 0
        )

        let second = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.55)
            ],
            relativeTime: 0.15
        )

        do {
            let pattern = try CHHapticPattern(events: [first, second], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            fallback.impactOccurred(intensity: 0.85)
        }
        #endif
    }
}
