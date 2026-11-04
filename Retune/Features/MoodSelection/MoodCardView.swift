import SwiftUI

struct MoodCardView: View {
    let mood: Mood
    var still: Bool
    var artworkSide: CGFloat? = nil
    var compactRow = false
    let action: () -> Void
    private var preferences = UserPreferences()
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiate

    var body: some View {
        Button(action: action) {
            Group {
                if compactRow {
                    HStack(spacing: 12) { artwork; title }
                } else {
                    VStack(spacing: 4) { artwork; title }
                }
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(QuietButtonStyle())
        .accessibilityLabel(mood.title)
        .accessibilityHint(String(localized: "Opens a gentle, endless relaxation experience. \(mood.invitation)"))
        .accessibilityIdentifier("mood.\(mood.rawValue)")
    }

    @ViewBuilder private var artwork: some View {
        if still { orb(breath: 0.5) }
        else {
            PhaseAnimator([false, true]) { expanded in
                orb(breath: expanded ? 1 : 0)
            } animation: { _ in .easeInOut(duration: floatDuration) }
        }
    }
    private var floatDuration: Double {
        switch mood {
        case .anxiety: 3.6
        case .anger: 4.2
        case .sadness: 3.9
        case .disappointment: 4.7
        }
    }
    private var floatDirection: Double {
        mood == .anxiety || mood == .sadness ? 1 : -1
    }
    private var title: some View {
        HStack(spacing: 5) {
            if differentiate { Image(systemName: mood.symbol).font(.caption).accessibilityHidden(true) }
            Text(mood.title).font(.system(.body, design: .rounded, weight: .medium))
                .multilineTextAlignment(compactRow ? .leading : .center)
                .lineLimit(compactRow ? 1 : 2).minimumScaleFactor(compactRow ? 0.45 : 0.65)
                .allowsTightening(true)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 2)
        .frame(maxWidth: .infinity, minHeight: 30, alignment: compactRow ? .leading : .center)
    }
    private func orb(breath: Double) -> some View {
        let movement = (breath - 0.5) * floatDirection
        let drift = min(6, (artworkSide ?? 150) * 0.035)
        return MoodArtworkView(mood: mood, glow: preferences.glow * (0.9 + breath * 0.2))
            .frame(width: artworkSide, height: artworkSide)
            .scaleEffect(0.97 + breath * 0.06)
            .rotationEffect(.degrees(movement * 4))
            .offset(y: movement * 2 * drift)
            .accessibilityHidden(true)
    }
}
