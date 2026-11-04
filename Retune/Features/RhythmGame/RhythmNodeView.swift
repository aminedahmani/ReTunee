import SwiftUI

enum OrbAnimationPhase { case appearing, idle, tapped, dissolving }

struct RhythmNodeView: View {
    let node: RhythmNodeModel
    let mood: Mood
    let snapshot: PacingSnapshot
    var reduceMotion: Bool
    let action: () -> Void
    private var preferences = UserPreferences()

    private var appearance: Double { min(1, max(0, snapshot.activeTime - node.appearedAt) / snapshot.orbFadeDuration) }
    private var phase: OrbAnimationPhase { appearance < 1 ? .appearing : .idle }
    private var energy: Double {
        switch mood {
        case .anger, .anxiety: 1 - snapshot.progress * 0.45
        case .sadness: 0.55 + snapshot.progress * 0.35
        case .disappointment: 0.65
        }
    }
    var body: some View {
        Button(action: action) {
            GlassOrbStyle(color: mood.accent, style: preferences.orbStyle,
                          breath: reduceMotion ? 0.5 : snapshot.breath,
                          glow: preferences.glow * energy,
                          intensity: preferences.intensity * energy,
                          warmth: mood == .sadness ? snapshot.progress : 0)
                .frame(width: 174, height: 174)
                .scaleEffect(reduceMotion ? 1 : (phase == .appearing ? 0.85 + appearance * 0.15 : 1))
                .opacity(reduceMotion ? 1 : 0.35 + 0.65 * appearance)
                .frame(width: 108, height: 108)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityRepresentation {
            Button(action: action) {
                Image(systemName: "circle.fill")
            }
                .accessibilityLabel(String(localized: "Glowing orb"))
                .accessibilityHint(String(localized: "Releases this light and reveals another. Take your time."))
                .accessibilityIdentifier("game.orb")
        }
    }
}

struct OrbEchoView: View {
    let echo: OrbEcho
    let elapsed: TimeInterval
    let color: Color
    let effect: VisualEffect
    let reduceMotion: Bool
    var intensity: Double
    private var age: Double { min(1, max(0, elapsed - echo.beganAt) / 0.9) }
    private var phase: OrbAnimationPhase { age < 0.18 ? .tapped : .dissolving }
    var body: some View {
        ZStack {
            Circle().fill(color.opacity(0.08)).frame(width: 90, height: 90)
            if !reduceMotion && effect == .ripple {
                Circle().stroke(color.opacity(0.45), lineWidth: 1)
                    .frame(width: 94 + age * 65, height: 94 + age * 65)
            }
            if !reduceMotion && (effect == .sparkles || effect == .dust) {
                ForEach(0..<6) { index in
                    let angle = Double(index) * .pi / 3
                    Circle().fill(color.opacity(0.5))
                        .frame(width: effect == .dust ? 3 : 2, height: effect == .dust ? 3 : 2)
                        .offset(x: cos(angle) * (48 + age * 28), y: sin(angle) * (48 + age * 28))
                }
            }
            Circle().fill(color.opacity(phase == .tapped ? 0.14 : 0.06))
                .frame(width: 80, height: 80)
                .scaleEffect(reduceMotion ? 1 : 1 + age * 0.25)
        }
        .opacity((1 - age) * intensity)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
