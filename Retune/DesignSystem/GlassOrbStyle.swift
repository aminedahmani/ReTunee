import SwiftUI

struct GlassOrbStyle: View {
    var color: Color
    var style: OrbStyle = .glass
    var breath: Double = 0.5
    var glow: Double = 0.7
    var intensity: Double = 0.65
    var warmth: Double = 0
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    private var highlight: Color { style == .pearl ? Color(hex: 0xF1E3D4) : .white }
    var body: some View {
        GeometryReader { geometry in
            let side = min(geometry.size.width, geometry.size.height)
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [color.opacity(glow * (0.28 + intensity * 0.12)), color.opacity(0.06 * glow), .clear],
                                         center: .center, startRadius: side * 0.18, endRadius: side * 0.5))
                Circle()
                    .fill(RadialGradient(colors: [highlight.opacity(style == .pearl ? 0.9 : 0.6),
                                                  color.opacity(0.95), color.opacity(reduceTransparency ? 1 : 0.35)],
                                         center: .init(x: 0.32, y: 0.25), startRadius: 0, endRadius: side * 0.65))
                    .frame(width: side * 0.57, height: side * 0.57)
                    .overlay {
                        if style == .glass && !reduceTransparency {
                            Circle().fill(.clear)
                                .glassEffect(.clear.tint(color.opacity(0.15)), in: .circle)
                                .opacity(0.55)
                                .frame(width: side * 0.57, height: side * 0.57)
                        }
                    }
                    .overlay {
                        Circle().stroke(LinearGradient(colors: [.white.opacity(0.7), color.opacity(0.1), .white.opacity(0.3)],
                                                       startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 0.8)
                            .frame(width: side * 0.57, height: side * 0.57)
                    }
                if style == .nebula {
                    Ellipse().fill(Color(hex: 0xE7A9EE).opacity(0.55))
                        .frame(width: side * 0.4, height: side * 0.16).blur(radius: 8).rotationEffect(.degrees(-35))
                }
                if warmth > 0 {
                    Circle().fill(Color(hex: 0xFFD4A8).opacity(warmth * 0.34)).frame(width: side * 0.48, height: side * 0.48)
                }
                Ellipse().fill(.white.opacity(style == .glow ? 0.2 : 0.6))
                    .frame(width: side * 0.16, height: side * 0.065)
                    .rotationEffect(.degrees(-32)).offset(x: -side * 0.1, y: -side * 0.16)
                    .blur(radius: style == .glow ? 5 : 2)
                Circle().stroke(color.opacity(0.09 * glow), lineWidth: 0.7)
                    .frame(width: side * 0.83, height: side * 0.83)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .scaleEffect(0.97 + breath * 0.055)
        }
    }
}
