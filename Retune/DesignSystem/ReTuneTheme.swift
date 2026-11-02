import SwiftUI

extension Color {
    init(hex: UInt32) {
        self.init(.sRGB, red: Double((hex >> 16) & 255) / 255,
                  green: Double((hex >> 8) & 255) / 255, blue: Double(hex & 255) / 255, opacity: 1)
    }
}
enum ReTuneTheme {
    static let midnight = Color(hex: 0x070A14)
    static let secondary = Color(hex: 0xB9BDCF)
    static let surfaceTop = Color(hex: 0x202638)
    static let surfaceBottom = Color(hex: 0x141927)
}

struct CalmSurface: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    var radius: CGFloat = 26
    func body(content: Content) -> some View {
        if reduceTransparency {
            content.background(Color(hex: 0x191E30), in: RoundedRectangle(cornerRadius: radius))
                .overlay(RoundedRectangle(cornerRadius: radius).stroke(.white.opacity(0.14), lineWidth: 1))
        } else {
            // A dark backing keeps text contrast predictable over the moving sky.
            // Native lensing is reserved for the luminous orb itself.
            content.background {
                RoundedRectangle(cornerRadius: radius)
                    .fill(LinearGradient(colors: [ReTuneTheme.surfaceTop, ReTuneTheme.surfaceBottom],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
            }
            .overlay {
                RoundedRectangle(cornerRadius: radius)
                    .stroke(LinearGradient(colors: [.white.opacity(0.22), .white.opacity(0.04), .white.opacity(0.1)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 0.8)
                    .allowsHitTesting(false)
            }
        }
    }
}
extension View {
    func calmSurface(radius: CGFloat = 26) -> some View { modifier(CalmSurface(radius: radius)) }
}

struct QuietButtonStyle: ButtonStyle {
    private var preferences = UserPreferences()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.75 : 1)
            .scaleEffect(configuration.isPressed && !reduceMotion && !preferences.reduceMotion ? 0.97 : 1)
            .animation(reduceMotion || preferences.reduceMotion ? nil : .easeOut(duration: 0.16), value: configuration.isPressed)
    }
}
