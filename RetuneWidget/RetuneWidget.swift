import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Color Hex Helper
extension Color {
    init(hexValue: UInt32) {
        self.init(
            .sRGB,
            red: Double((hexValue >> 16) & 255) / 255,
            green: Double((hexValue >> 8) & 255) / 255,
            blue: Double(hexValue & 255) / 255,
            opacity: 1
        )
    }
}

// MARK: - Widget Mood Model (Fully Localized to System Language)
enum WidgetMood: String, CaseIterable, Identifiable {
    case anxiety, anger, sadness, disappointment
    var id: String { rawValue }

    var title: String {
        switch self {
        case .anxiety: String(localized: "Anxiety")
        case .anger: String(localized: "Anger")
        case .sadness: String(localized: "Sadness")
        case .disappointment: String(localized: "Disappointment")
        }
    }

    var keyword: String {
        switch self {
        case .anxiety: String(localized: "Breathe")
        case .anger: String(localized: "Soothe")
        case .sadness: String(localized: "Light")
        case .disappointment: String(localized: "Restore")
        }
    }

    var invitation: String {
        switch self {
        case .anxiety: String(localized: "A little room to breathe.")
        case .anger: String(localized: "Let the edges soften.")
        case .sadness: String(localized: "Make space for a little light.")
        case .disappointment: String(localized: "Gently, piece by piece.")
        }
    }

    var symbol: String {
        switch self {
        case .anxiety: "wind"
        case .anger: "flame"
        case .sadness: "cloud.rain"
        case .disappointment: "sparkle"
        }
    }

    var accent: Color {
        switch self {
        case .anxiety: Color(hexValue: 0xC6F432)        // Radiant Lime
        case .anger: Color(hexValue: 0xFF5A36)          // Soft Flame Coral
        case .sadness: Color(hexValue: 0x4A6CF7)        // Luminous Sky Blue
        case .disappointment: Color(hexValue: 0xA78BDB) // Cosmic Lavender
        }
    }
}

// MARK: - Original Artwork Sphere View (Exact Same Artwork as Main Menu)
struct MoodArtworkView: View {
    let mood: WidgetMood
    var size: CGFloat = 40
    var glow: Double = 0.85

    private var sphereFraction: CGFloat {
        switch mood {
        case .anxiety: 0.538
        case .anger: 0.58
        case .sadness: 0.55
        case .disappointment: 0.65
        }
    }

    var body: some View {
        let diameter = size * 0.74
        let imageSide = diameter / sphereFraction

        ZStack {
            if mood == .anxiety {
                ForEach([1.18, 1.38], id: \.self) { scale in
                    Circle()
                        .stroke(mood.accent.opacity(0.24 + glow * 0.25), lineWidth: 0.65)
                        .frame(width: diameter * scale, height: diameter * scale)
                }
            }

            Image("MoodArtwork-\(mood.rawValue)")
                .resizable()
                .interpolation(.high)
                .frame(width: imageSide, height: imageSide)
                .offset(
                    x: mood == .anxiety || mood == .anger ? imageSide * 0.008 : 0,
                    y: mood == .disappointment ? -imageSide * 0.005 : 0
                )
                .frame(width: diameter, height: diameter)
                .clipShape(Circle())
                .shadow(color: mood.accent.opacity(glow * 0.38), radius: size * 0.08)

            if mood == .disappointment {
                Image("MoodArtwork-disappointment")
                    .resizable()
                    .interpolation(.high)
                    .frame(width: imageSide, height: imageSide)
                    .mask(DisappointmentFragments())
                    .offset(y: -imageSide * 0.005)
                    .frame(width: diameter, height: diameter)
                    .shadow(color: mood.accent.opacity(glow * 0.25), radius: 3)
            }
        }
        .frame(width: size, height: size)
    }
}

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

// MARK: - Interactive App Intent (In-Widget Mood Selection)
struct SelectMoodIntent: AppIntent {
    static var title: LocalizedStringResource = "Select Mood"
    static var description = IntentDescription("Selects a mood in the ReTune widget.")

    @Parameter(title: "Mood")
    var mood: String

    init() {
        self.mood = WidgetMood.anxiety.rawValue
    }

    init(mood: String) {
        self.mood = mood
    }

    func perform() async throws -> some IntentResult {
        UserDefaults.standard.set(mood, forKey: "widget.selectedMood")
        WidgetCenter.shared.reloadTimelines(ofKind: "RetuneWidget")
        return .result()
    }
}

// MARK: - Timeline & Provider
struct MoodTimelineEntry: TimelineEntry {
    let date: Date
    let mood: WidgetMood
}

struct ReTuneWidgetTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> MoodTimelineEntry {
        MoodTimelineEntry(date: Date(), mood: .anxiety)
    }

    func getSnapshot(in context: Context, completion: @escaping (MoodTimelineEntry) -> Void) {
        completion(MoodTimelineEntry(date: Date(), mood: currentMood()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MoodTimelineEntry>) -> Void) {
        let mood = currentMood()
        let now = Date()
        let entry = MoodTimelineEntry(date: now, mood: mood)
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 2, to: now) ?? now.addingTimeInterval(7200)
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func currentMood() -> WidgetMood {
        if let saved = UserDefaults.standard.string(forKey: "widget.selectedMood"),
           let mood = WidgetMood(rawValue: saved) {
            return mood
        }
        return .anxiety
    }
}

// MARK: - Main Widget View
struct RetuneWidgetEntryView: View {
    var entry: MoodTimelineEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallView
        case .systemMedium:
            mediumView
        case .systemLarge:
            largeView
        case .accessoryCircular:
            circularAccessoryView
        case .accessoryRectangular:
            rectangularAccessoryView
        case .accessoryInline:
            inlineAccessoryView
        default:
            smallView
        }
    }

    // MARK: - Small Widget (Focus & Direct Game Launch)
    private var smallView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header bar
            HStack(alignment: .center) {
                HStack(spacing: 4) {
                    Text("✦")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(entry.mood.accent)
                    Text("RETUNE")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.75))
                        .tracking(1.2)
                }
                Spacer()
                Text(entry.mood.keyword.uppercased())
                    .font(.system(size: 8, weight: .heavy, design: .rounded))
                    .foregroundStyle(entry.mood.accent)
                    .lineLimit(1)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(entry.mood.accent.opacity(0.18), in: Capsule())
            }

            Spacer(minLength: 4)

            // Center: Original artwork orb & Emotion details
            HStack(spacing: 10) {
                MoodArtworkView(mood: entry.mood, size: 54)

                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.mood.title)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    Text(entry.mood.invitation)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.75))
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 4)

            // Action button pill (Opens music selection for this mood)
            HStack {
                Image(systemName: "music.note")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(entry.mood.accent)
                Text(String(localized: "Choose your music"))
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(entry.mood.accent)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.18), .white.opacity(0.04)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.6
                    )
            )
        }
        .padding(14)
        .widgetURL(URL(string: "retune://choose/\(entry.mood.rawValue)"))
    }

    // MARK: - Medium Widget (Interactive 4-Mood Mind Hub)
    private var mediumView: some View {
        VStack(spacing: 10) {
            // Header bar
            HStack {
                HStack(spacing: 5) {
                    Text("✦")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color(hexValue: 0xC6F432))
                    Text("RETUNE")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                        .tracking(1.4)
                }

                Spacer()

                Text(String(localized: "Choose your music"))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(1)
            }
            .padding(.horizontal, 2)

            // 4 Interactive Mood Cards with Original Artwork Orbs
            HStack(spacing: 8) {
                ForEach(WidgetMood.allCases) { mood in
                    Link(destination: URL(string: "retune://choose/\(mood.rawValue)")!) {
                        VStack(spacing: 6) {
                            MoodArtworkView(mood: mood, size: 38)

                            Text(mood.title)
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)

                            Text(mood.keyword)
                                .font(.system(size: 9, weight: .medium, design: .rounded))
                                .foregroundStyle(mood.accent)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 4)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(hexValue: 0x202638).opacity(0.7),
                                    Color(hexValue: 0x141927).opacity(0.9)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            mood.accent.opacity(0.4),
                                            .white.opacity(0.08),
                                            .clear
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 0.8
                                )
                        )
                    }
                }
            }
        }
        .padding(14)
    }

    // MARK: - Large Widget (Complete Mindful Space)
    private var largeView: some View {
        VStack(spacing: 12) {
            // Header bar
            HStack {
                HStack(spacing: 5) {
                    Text("✦")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(entry.mood.accent)
                    Text("RETUNE")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .tracking(1.4)
                }
                Spacer()
                Text(String(localized: "Daily Harmony"))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(1)
            }

            // Hero section with large original artwork orb & direct "Start session" button
            Link(destination: URL(string: "retune://play/\(entry.mood.rawValue)")!) {
                HStack(spacing: 14) {
                    MoodArtworkView(mood: entry.mood, size: 76, glow: 1.0)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.mood.title)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)

                        Text(entry.mood.invitation)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.75))
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                            .fixedSize(horizontal: false, vertical: true)

                        HStack(spacing: 6) {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 14, weight: .semibold))
                            Text(String(localized: "Start session"))
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .lineLimit(1)
                        }
                        .foregroundStyle(entry.mood.accent)
                        .padding(.top, 4)
                    }
                    Spacer(minLength: 0)
                }
                .padding(12)
                .background(
                    LinearGradient(
                        colors: [
                            Color(hexValue: 0x202638).opacity(0.8),
                            Color(hexValue: 0x141927).opacity(0.95)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 20, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [entry.mood.accent.opacity(0.4), .white.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.8
                        )
                )
            }

            // Interactive 2x2 Grid: Tap to select mood on the widget
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                ForEach(WidgetMood.allCases) { mood in
                    let isSelected = (mood == entry.mood)
                    Button(intent: SelectMoodIntent(mood: mood.rawValue)) {
                        HStack(spacing: 8) {
                            MoodArtworkView(mood: mood, size: 36, glow: isSelected ? 1.0 : 0.35)

                            VStack(alignment: .leading, spacing: 1) {
                                Text(mood.title)
                                    .font(.system(size: 12, weight: isSelected ? .heavy : .bold, design: .rounded))
                                    .foregroundStyle(isSelected ? .white : .white.opacity(0.85))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.65)
                                Text(mood.keyword)
                                    .font(.system(size: 10, weight: isSelected ? .bold : .medium, design: .rounded))
                                    .foregroundStyle(mood.accent)
                                    .lineLimit(1)
                            }
                            Spacer(minLength: 0)

                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(mood.accent)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(
                            isSelected
                                ? Color(hexValue: 0x22293D).opacity(0.95)
                                : Color.white.opacity(0.06),
                            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(
                                    isSelected ? mood.accent.opacity(0.9) : Color.white.opacity(0.08),
                                    lineWidth: isSelected ? 1.5 : 0.6
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
    }

    // MARK: - Lock Screen Widgets
    private var circularAccessoryView: some View {
        ZStack {
            AccessoryWidgetBackground()
            Circle()
                .stroke(lineWidth: 2)
                .foregroundStyle(.secondary)
                .padding(2)
            Image(systemName: entry.mood.symbol)
                .font(.system(size: 18, weight: .semibold))
        }
        .widgetURL(URL(string: "retune://choose/\(entry.mood.rawValue)"))
    }

    private var rectangularAccessoryView: some View {
        HStack(spacing: 8) {
            Image(systemName: entry.mood.symbol)
                .font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text("ReTune")
                        .font(.headline)
                        .widgetAccentable()
                    Text("• \(entry.mood.title)")
                        .font(.caption2.weight(.medium))
                }
                Text(entry.mood.invitation)
                    .font(.caption2)
                    .lineLimit(1)
            }
        }
        .widgetURL(URL(string: "retune://choose/\(entry.mood.rawValue)"))
    }

    private var inlineAccessoryView: some View {
        HStack(spacing: 4) {
            Text("✦ ReTune • \(entry.mood.title) (\(entry.mood.keyword))")
        }
        .widgetURL(URL(string: "retune://choose/\(entry.mood.rawValue)"))
    }
}

// MARK: - Widget Declaration
struct RetuneWidget: Widget {
    let kind: String = "RetuneWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ReTuneWidgetTimelineProvider()) { entry in
            RetuneWidgetEntryView(entry: entry)
                .containerBackground(
                    RadialGradient(
                        colors: [
                            entry.mood.accent.opacity(0.18),
                            Color(hexValue: 0x0D111F),
                            Color(hexValue: 0x060810)
                        ],
                        center: .topTrailing,
                        startRadius: 20,
                        endRadius: 240
                    ),
                    for: .widget
                )
        }
        .configurationDisplayName("ReTune Moods")
        .description("Quick access to breathe and retune your mind.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}
