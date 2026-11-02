import SwiftUI

/// The approved glass artwork, sized by its visible sphere rather than its PNG padding.
struct MoodArtworkView: View {
    let mood: Mood
    var glow: Double

    private var sphereFraction: CGFloat {
        switch mood {
        case .anxiety: 0.538
        case .anger: 0.58
        case .sadness: 0.55
        case .disappointment: 0.65
        }
    }

    var body: some View {
        GeometryReader { geometry in
            let side = min(geometry.size.width, geometry.size.height)
            let diameter = side * 0.72
            let imageSide = diameter / sphereFraction
            ZStack {
                if mood == .anxiety {
                    ForEach([1.2, 1.4], id: \.self) { scale in
                        Circle()
                            .stroke(mood.accent.opacity(0.24 + glow * 0.25), lineWidth: 0.65)
                            .frame(width: diameter * scale, height: diameter * scale)
                    }
                }

                // Keep the art's highlights while giving every mood the same restrained halo.
                // The image-generator's broad outer haze is outside this circular viewport.
                Image("MoodArtwork-\(mood.rawValue)")
                    .resizable()
                    .interpolation(.high)
                    .frame(width: imageSide, height: imageSide)
                    .offset(x: mood == .anxiety || mood == .anger ? imageSide * 0.008 : 0,
                            y: mood == .disappointment ? -imageSide * 0.005 : 0)
                    .frame(width: diameter, height: diameter)
                    .clipShape(Circle())
                    .shadow(color: mood.accent.opacity(glow * 0.3), radius: side * 0.055)

                if mood == .disappointment {
                    Image("MoodArtwork-disappointment")
                        .resizable()
                        .interpolation(.high)
                        .frame(width: imageSide, height: imageSide)
                        .mask(DisappointmentFragments())
                        .offset(y: -imageSide * 0.005)
                        .frame(width: diameter, height: diameter)
                        .shadow(color: mood.accent.opacity(glow * 0.25), radius: 4)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }
}

/// Selects the two painted fragments without the exported image's surrounding haze.
private struct DisappointmentFragments: Shape {
    nonisolated func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 808, y: 176))
        path.addCurve(to: CGPoint(x: 910, y: 191), control1: CGPoint(x: 840, y: 158), control2: CGPoint(x: 880, y: 177))
        path.addCurve(to: CGPoint(x: 1050, y: 334), control1: CGPoint(x: 976, y: 224), control2: CGPoint(x: 1034, y: 290))
        path.addCurve(to: CGPoint(x: 1034, y: 378), control1: CGPoint(x: 1060, y: 360), control2: CGPoint(x: 1050, y: 378))
        path.addCurve(to: CGPoint(x: 997, y: 352), control1: CGPoint(x: 1020, y: 378), control2: CGPoint(x: 1008, y: 366))
        path.addCurve(to: CGPoint(x: 820, y: 226), control1: CGPoint(x: 943, y: 287), control2: CGPoint(x: 881, y: 244))
        path.addCurve(to: CGPoint(x: 808, y: 176), control1: CGPoint(x: 794, y: 217), control2: CGPoint(x: 782, y: 192))
        path.closeSubpath()
        path.move(to: CGPoint(x: 187, y: 832))
        path.addCurve(to: CGPoint(x: 234, y: 868), control1: CGPoint(x: 209, y: 820), control2: CGPoint(x: 226, y: 845))
        path.addCurve(to: CGPoint(x: 376, y: 1015), control1: CGPoint(x: 269, y: 940), control2: CGPoint(x: 320, y: 981))
        path.addCurve(to: CGPoint(x: 390, y: 1059), control1: CGPoint(x: 399, y: 1029), control2: CGPoint(x: 405, y: 1049))
        path.addCurve(to: CGPoint(x: 341, y: 1057), control1: CGPoint(x: 377, y: 1070), control2: CGPoint(x: 356, y: 1062))
        path.addCurve(to: CGPoint(x: 177, y: 895), control1: CGPoint(x: 265, y: 1027), control2: CGPoint(x: 199, y: 955))
        path.addCurve(to: CGPoint(x: 187, y: 832), control1: CGPoint(x: 165, y: 861), control2: CGPoint(x: 168, y: 842))
        path.closeSubpath()
        return path.applying(CGAffineTransform(scaleX: rect.width / 1254, y: rect.height / 1254))
    }
}
