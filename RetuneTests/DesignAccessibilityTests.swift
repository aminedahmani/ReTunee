import Testing
import UIKit
import SwiftUI
@testable import Retune

@MainActor struct DesignAccessibilityTests {
    @Test func moodLabelsHaveStrongContrastEvenWhenPressed() {
        for surface in [ReTuneTheme.surfaceTop, ReTuneTheme.surfaceBottom] {
            var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
            UIColor(surface).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            let background = [Double(red), Double(green), Double(blue)]
            func luminance(_ channels: [Double]) -> Double {
                let linear = channels.map { $0 <= 0.04045 ? $0 / 12.92 : pow(($0 + 0.055) / 1.055, 2.4) }
                return linear[0] * 0.2126 + linear[1] * 0.7152 + linear[2] * 0.0722
            }
            #expect((1.0 + 0.05) / (luminance(background) + 0.05) >= 7)
            let pressed = background.map { 0.75 + $0 * 0.25 }
            #expect((luminance(pressed) + 0.05) / (luminance(background) + 0.05) >= 4.5)
        }
    }
}
