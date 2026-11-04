import SwiftUI

/// The approved opening is drawn only while a fresh launch is in progress.
struct LaunchAnimationView: View {
    static let duration: TimeInterval = 1.3
    static let reducedDuration: TimeInterval = 0.3

    let startedAt: Date
    let reduceMotion: Bool
    let onFinish: () -> Void

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60)) { timeline in
            let elapsed = max(0, timeline.date.timeIntervalSince(startedAt))
            let focus = reduceMotion ? 1 : eased(elapsed, from: 0.3, to: 0.7)
            let dissolve = reduceMotion
                ? eased(elapsed, from: 0, to: Self.reducedDuration)
                : eased(elapsed, from: 0.7, to: Self.duration)

            Button(action: onFinish) {
                GeometryReader { geometry in
                    let side = min(geometry.size.width * 0.56, 224)
                    ZStack {
                        ReTuneTheme.midnight
                        Image("LaunchLogo")
                            .resizable()
                            .interpolation(.high)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: side, height: side)
                            .clipShape(RoundedRectangle(cornerRadius: side * 0.23, style: .continuous))
                            .opacity(reduceMotion ? 1 : 0.12 + 0.88 * eased(elapsed, from: 0, to: 0.3))
                            .blur(radius: 18 * (1 - focus))
                            .scaleEffect(reduceMotion ? 1 : 0.96 + 0.04 * focus)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
                }
            }
            .buttonStyle(.plain)
            .opacity(1 - dissolve)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("ReTune")
            .accessibilityHint(String(localized: "Skip opening animation."))
            .accessibilityIdentifier("launch.animation")
        }
        .ignoresSafeArea()
    }

    private func eased(_ elapsed: TimeInterval, from start: TimeInterval, to end: TimeInterval) -> Double {
        let progress = min(1, max(0, (elapsed - start) / (end - start)))
        return progress * progress * (3 - 2 * progress)
    }
}
