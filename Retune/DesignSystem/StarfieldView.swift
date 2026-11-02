import SwiftUI

struct StarfieldView: View {
    var theme: UniverseTheme = .midnight
    var time: TimeInterval = 0
    var intensity: Double = 0.65
    var warmth: Double = 0

    private struct Star {
        let x: Double
        let y: Double
        let radius: Double
        let opacity: Double
        let offset: Double
    }
    // Stable seeds: resizing or recomputing a body never regenerates the sky.
    private static let stars: [Star] = (0..<74).map { index in
        let n = Double(index)
        return Star(x: (n * 0.61803398875 + 0.13).truncatingRemainder(dividingBy: 1),
                    y: (n * 0.41421356237 + 0.07).truncatingRemainder(dividingBy: 1),
                    radius: index % 13 == 0 ? 1.25 : (index % 3 == 0 ? 0.8 : 0.5),
                    opacity: index % 7 == 0 ? 0.65 : 0.26, offset: n * 1.7)
    }
    var body: some View {
        ZStack {
            ReTuneTheme.midnight
            RadialGradient(colors: [theme.tint.opacity(0.25 * intensity), .clear],
                           center: .init(x: 0.8, y: 0.28), startRadius: 5, endRadius: 440)
            RadialGradient(colors: [Color(hex: 0x5C4E97).opacity(0.13 * intensity), .clear],
                           center: .init(x: 0.1, y: 0.87), startRadius: 5, endRadius: 350)
            if warmth > 0 {
                RadialGradient(colors: [Color(hex: 0xDAA992).opacity(warmth * 0.08), .clear],
                               center: .center, startRadius: 0, endRadius: 350)
            }
            Canvas { context, size in
                for star in Self.stars {
                    let drift = sin(time / 28 + star.offset) * 3
                    let center = CGPoint(x: star.x * size.width + drift, y: star.y * size.height + drift * 0.45)
                    let rect = CGRect(x: center.x, y: center.y, width: star.radius * 2, height: star.radius * 2)
                    context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(star.opacity * (0.5 + intensity * 0.5))))
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct AmbientBackground: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    private var preferences = UserPreferences()
    @State private var origin = ContinuousClock.now
    var body: some View {
        let animate = preferences.backgroundAnimation && !preferences.reduceMotion && !systemReduceMotion && scenePhase == .active
        TimelineView(.animation(minimumInterval: 1.0 / 20, paused: !animate)) { _ in
            let parts = origin.duration(to: .now).components
            let time = animate ? Double(parts.seconds) + Double(parts.attoseconds) / 1e18 : 0
            StarfieldView(theme: preferences.theme, time: time, intensity: preferences.intensity)
        }
    }
}
