import SwiftUI

struct ReconstructionView: View, Animatable {
    var progress: Double
    var reduceMotion: Bool
    var intensity: Double
    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }
    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) * 0.31
            for index in 0..<7 {
                let angle = Double(index) * .pi * 2 / 7 - .pi / 2
                let nextAngle = Double(index + 1) * .pi * 2 / 7 - .pi / 2
                let spread = (1 - progress) * (reduceMotion ? 7 : 24)
                let offset = CGVector(dx: cos(angle + .pi / 7) * spread, dy: sin(angle + .pi / 7) * spread)
                var shard = Path()
                shard.move(to: CGPoint(x: center.x + offset.dx, y: center.y + offset.dy))
                shard.addLine(to: CGPoint(x: center.x + cos(angle) * radius + offset.dx,
                                         y: center.y + sin(angle) * radius + offset.dy))
                shard.addLine(to: CGPoint(x: center.x + cos(nextAngle) * radius + offset.dx,
                                         y: center.y + sin(nextAngle) * radius + offset.dy))
                shard.closeSubpath()
                context.fill(shard, with: .color(Mood.disappointment.accent.opacity((0.025 + progress * 0.045) * intensity)))
                context.stroke(shard, with: .color(Mood.disappointment.accent.opacity((0.13 + progress * 0.1) * intensity)), lineWidth: 0.8)
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.7), value: progress)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
