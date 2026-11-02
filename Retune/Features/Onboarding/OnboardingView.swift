import SwiftUI

struct OnboardingGate {
    let store: UserDefaults
    func consumeFirstLaunch() -> Bool {
        guard !store.bool(forKey: "onboarding.hasPresented") else { return false }
        // Record presentation, not completion, so an interrupted introduction never repeats.
        store.set(true, forKey: "onboarding.hasPresented")
        return true
    }
}

struct LaunchExperienceView: View {
    @State private var checkedLaunch = false
    @State private var showingOnboarding = false
    @State private var showingLaunch = true
    @State private var launchStartedAt = Date()
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    private var preferences = UserPreferences()

    private var reduceMotion: Bool { systemReduceMotion || preferences.reduceMotion }

    var body: some View {
        ZStack {
            Group {
                if showingOnboarding {
                    OnboardingView { showingOnboarding = false }
                } else {
                    ContentView()
                }
            }
            .allowsHitTesting(!showingLaunch)
            .accessibilityHidden(showingLaunch)

            if showingLaunch {
                LaunchAnimationView(startedAt: launchStartedAt, reduceMotion: reduceMotion,
                                    onFinish: finishLaunch)
                    .transition(.identity)
                    .zIndex(1)
            }
        }
        .background(ReTuneTheme.midnight.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .task {
            guard !checkedLaunch else { return }
            checkedLaunch = true
            showingOnboarding = OnboardingGate(store: .standard).consumeFirstLaunch()
            launchStartedAt = Date()
            let duration = reduceMotion ? LaunchAnimationView.reducedDuration : LaunchAnimationView.duration
            do { try await Task.sleep(for: .seconds(duration)) }
            catch { return }
            finishLaunch()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background { finishLaunch() }
        }
        .onChange(of: reduceMotion) { _, reduced in
            if reduced { finishLaunch() }
        }
    }

    private func finishLaunch() { showingLaunch = false }
}

struct OnboardingView: View {
    var isReview = false
    let onFinish: () -> Void
    @State private var step = 0
    private let pages: [(title: String, detail: String, symbol: String, mood: Mood)] = [
        ("Choose your mood", "Start with how you feel: Anxiety, Anger, Sadness, or Disappointment.", "sparkles", .anxiety),
        ("Find your sound", "Preview three tracks for your mood. Choose your favorite and tap Start.", "music.note", .disappointment),
        ("Tap the light", "Each tap reveals the next light. Anxiety, Anger, and Disappointment slow down. Sadness gently speeds up.", "hand.tap", .sadness),
        ("Make it yours", "Pause to adjust volume. Choose “I feel better” whenever you want to finish.", "pause.fill", .anger)
    ]
    var body: some View {
        let page = pages[step]
        VStack(spacing: 0) {
            HStack {
                Text("ReTune").font(.system(.headline, design: .rounded))
                Spacer()
                Button(isReview ? "Close" : "Skip", action: onFinish)
                    .frame(minWidth: 44, minHeight: 44)
                    .accessibilityIdentifier("onboarding.skip")
            }
            .padding(.horizontal, 24).padding(.top, 12)
            ScrollView {
                VStack(spacing: 28) {
                    ZStack {
                        Circle().fill(page.mood.accent.opacity(0.12))
                        Circle().stroke(page.mood.accent.opacity(0.3), lineWidth: 1)
                        Image(systemName: page.symbol)
                            .font(.system(size: 56, weight: .light))
                            .foregroundStyle(page.mood == .sadness ? Color(hex: 0x91A5FF) : page.mood.accent)
                    }
                    .frame(width: 152, height: 152).accessibilityHidden(true)
                    Text(page.title)
                        .font(.system(.largeTitle, design: .rounded, weight: .semibold))
                        .accessibilityAddTraits(.isHeader).accessibilityIdentifier("onboarding.title")
                    Text(page.detail).font(.body).foregroundStyle(ReTuneTheme.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28).padding(.vertical, 32)
                .frame(maxWidth: 480).frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)
            VStack(spacing: 24) {
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Capsule().fill(index == step ? .white : .white.opacity(0.2))
                            .frame(width: index == step ? 24 : 8, height: 8)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Step \(step + 1) of \(pages.count)")
                Button {
                    if step == pages.count - 1 { onFinish() } else { step += 1 }
                } label: {
                    Text(step == pages.count - 1 ? (isReview ? "Done" : "Get started") : "Next")
                        .font(.system(.headline, design: .rounded))
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .foregroundStyle(ReTuneTheme.midnight).background(.white, in: Capsule())
                }
                .accessibilityIdentifier("onboarding.next")
            }
            .padding(24).frame(maxWidth: 480)
        }
        .background(ReTuneTheme.midnight)
        .foregroundStyle(.white).tint(.white)
        .buttonStyle(QuietButtonStyle()).preferredColorScheme(.dark)
    }
}
