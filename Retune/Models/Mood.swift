import SwiftUI

enum Mood: String, CaseIterable, Identifiable, Hashable {
    case anxiety, anger, sadness, disappointment
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var symbol: String {
        switch self {
        case .anxiety: "wind"
        case .anger: "flame"
        case .sadness: "cloud.rain"
        case .disappointment: "sparkle"
        }
    }
    var invitation: String {
        switch self {
        case .anxiety: "A little room to breathe."
        case .anger: "Let the edges soften."
        case .sadness: "Make space for a little light."
        case .disappointment: "Gently, piece by piece."
        }
    }
    var accent: Color {
        switch self {
        case .anxiety: Color(hex: 0xC6F432)
        case .anger: Color(hex: 0xFF5A36)
        case .sadness: Color(hex: 0x4A6CF7)
        case .disappointment: Color(hex: 0xA78BDB)
        }
    }
    var configuration: MoodConfiguration {
        switch self {
        case .anxiety, .anger, .disappointment: .init(startBPM: 140, targetBPM: 60)
        case .sadness: .init(startBPM: 60, targetBPM: 100, acceleratesOrbs: true)
        }
    }
}

struct MoodConfiguration {
    let startBPM: Double
    let targetBPM: Double
    var transitionDuration: TimeInterval = 8 * 60
    var acceleratesOrbs = false

    func progress(at elapsed: TimeInterval) -> Double {
        guard transitionDuration > 0 else { return 1 }
        return min(max(elapsed / transitionDuration, 0), 1)
    }
    func easedProgress(at elapsed: TimeInterval) -> Double {
        let t = progress(at: elapsed)
        return t * t * (3 - 2 * t)
    }
    func bpm(at elapsed: TimeInterval) -> Double {
        startBPM + (targetBPM - startBPM) * easedProgress(at: elapsed)
    }
    // Integrating the tempo curve keeps phase continuous as the BPM changes.
    func beats(at elapsed: TimeInterval) -> Double {
        let elapsed = max(0, elapsed)
        guard transitionDuration > 0 else { return elapsed * targetBPM / 60 }
        let t = progress(at: elapsed)
        let transitioningTime = min(elapsed, transitionDuration)
        let integral = transitionDuration * (t * t * t - 0.5 * t * t * t * t)
        return (startBPM * transitioningTime + (targetBPM - startBPM) * integral
                + targetBPM * max(0, elapsed - transitionDuration)) / 60
    }
}
