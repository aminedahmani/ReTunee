import SwiftUI

struct ContentView: View {
    @State private var showingSettings = false
    @State private var showingExplore = false
    @State private var showingGuide = false
    @State private var path: [MusicTrack] = []
    @State private var choosingMood: Mood?
    @State private var pendingTrack: MusicTrack?
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @ScaledMetric(relativeTo: .body) private var moodLabelHeight: CGFloat = 40
    @ScaledMetric(relativeTo: .caption2) private var menuItemWidth: CGFloat = 90
    private var preferences = UserPreferences()

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                if path.isEmpty { AmbientBackground() }
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .top, spacing: 16) {
                        Text("How do you feel?")
                            .font(.system(.title, design: .rounded, weight: .semibold))
                            .lineLimit(2).minimumScaleFactor(0.65)
                            .dynamicTypeSize(...(verticalSizeClass == .compact ? DynamicTypeSize.xxxLarge : .accessibility5))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 7)
                            .accessibilityAddTraits(.isHeader)
                        Button { showingSettings = true } label: {
                            Image(systemName: "gearshape").font(.system(size: 19, weight: .regular))
                                .frame(width: 56, height: 56).calmSurface(radius: 28)
                        }
                        .buttonStyle(QuietButtonStyle())
                        .accessibilityLabel("Settings").accessibilityIdentifier("home.settings")
                    }
                    GeometryReader { grid in
                        let wide = grid.size.width > grid.size.height * 2
                        let columns = dynamicTypeSize.isAccessibilitySize ? (wide ? 2 : 1) : (wide ? 4 : 2)
                        let rows = 4 / columns
                        let spacing: CGFloat = 16
                        let cellWidth = max(0, (grid.size.width - spacing * CGFloat(columns - 1)) / CGFloat(columns))
                        let cellHeight = max(0, (grid.size.height - spacing * CGFloat(rows - 1)) / CGFloat(rows))
                        let artworkSide = dynamicTypeSize.isAccessibilitySize
                            ? max(0, min(44, cellHeight - 4))
                            : max(0, min(cellWidth, cellHeight - moodLabelHeight - 4))
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: spacing), count: columns), spacing: spacing) {
                            ForEach(Mood.allCases) { mood in
                                MoodCardView(mood: mood,
                                             still: systemReduceMotion || preferences.reduceMotion || scenePhase != .active || !path.isEmpty || showingSettings || showingExplore || showingGuide || choosingMood != nil,
                                             artworkSide: artworkSide, compactRow: dynamicTypeSize.isAccessibilitySize) {
                                    choosingMood = mood
                                }
                                .frame(height: cellHeight)
                            }
                        }
                    }
                }
                .padding(.horizontal, 24).padding(.top, 18).padding(.bottom, 12)
                .frame(maxWidth: 550)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                homeMenu.padding(.horizontal, 24).padding(.top, 12).padding(.bottom, 8)
                    .dynamicTypeSize(...(verticalSizeClass == .compact ? DynamicTypeSize.xxxLarge : .accessibility5))
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: MusicTrack.self) { track in
                RhythmGameView(track: track)
            }
            .sheet(isPresented: $showingSettings) { SettingsView() }
            .sheet(isPresented: $showingExplore) { ExploreView() }
            .fullScreenCover(isPresented: $showingGuide) {
                OnboardingView(isReview: true) { showingGuide = false }
            }
            .sheet(item: $choosingMood, onDismiss: beginChosenTrack) { mood in
                MusicSelectionView(mood: mood) { track in
                    pendingTrack = track
                    choosingMood = nil
                }
            }
        }
        .tint(.white)
        .preferredColorScheme(.dark)
    }

    private func beginChosenTrack() {
        if let track = pendingTrack {
            pendingTrack = nil
            path.append(track)
        }
    }

    private var homeMenu: some View {
        HStack(spacing: 2) {
            Button { showingExplore = true } label: {
                menuLabel("Explore", symbol: "sparkles")
            }
            .accessibilityIdentifier("home.explore")

            Button { showingGuide = true } label: {
                menuLabel("Guide", symbol: "questionmark.circle")
            }
            .accessibilityHint("Review how to use ReTune.")
            .accessibilityIdentifier("home.guide")
        }
        .padding(5)
        .calmSurface(radius: 50)
        .buttonStyle(QuietButtonStyle())
    }

    private func menuLabel(_ title: String, symbol: String) -> some View {
        VStack(spacing: 3) {
            Image(systemName: symbol)
                .font(.system(size: 21, weight: .medium))
                .accessibilityHidden(true)
            Text(title).font(.system(.caption2, design: .rounded, weight: .semibold))
                .lineLimit(1).minimumScaleFactor(0.7)
        }
        .foregroundStyle(.white)
        .frame(minWidth: 44, maxWidth: min(menuItemWidth, 140))
        .frame(minHeight: 44)
        .padding(.vertical, 4)
        .contentShape(Capsule())
    }
}

#Preview { ContentView() }
