# ReTune

A SwiftUI iOS relaxation app with four moods: Anxiety, Anger, Sadness, and Disappointment.

## Run the app

1. Open `Retune.xcodeproj` in Xcode 27 or later.
2. Select the **Retune** scheme and an iPhone simulator running iOS 27 or later.
3. Build and run. For a physical device, select your own signing team in **Signing & Capabilities**.

The project uses Swift 6 and includes its artwork and twelve music tracks locally. No package installation or backend setup is required.

## Experience

- A short logo animation opens the app.
- Onboarding appears automatically on the first launch. The **Guide** button reopens it anytime.
- The fixed home screen has four gently animated moods, plus **Explore** and **Guide**.
- Preview three tracks for a mood and choose one before starting. The selected track stays fixed during the game.
- Each tap reveals the next orb. Anxiety, Anger, and Disappointment gradually slow down over the track; Sadness gradually speeds up.
- Pause to adjust volume, resume, or finish with **I feel better**.
- Settings uses icon buttons and sliders, with VoiceOver labels. System and app Reduce Motion preferences are respected.

## Checks

The project includes unit tests in `RetuneTests` and UI tests in `RetuneUITests`. Run them through Xcode's Test navigator or **Product → Test**. Shared verification schemes are included for focused checks.
