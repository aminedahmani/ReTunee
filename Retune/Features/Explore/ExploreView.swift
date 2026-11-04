import SwiftUI

struct ExploreView: View {
    private var preferences = UserPreferences()
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    Text("Make this space yours.")
                        .font(.system(.title2, design: .serif))
                    Text("Every look is here for you. Choose what feels good.")
                        .font(.subheadline).foregroundStyle(ReTuneTheme.secondary)
                    Text("Your universe").font(.headline).accessibilityAddTraits(.isHeader)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(UniverseTheme.allCases) { theme in
                            Button { preferences.theme = theme } label: {
                                VStack(alignment: .leading, spacing: 8) {
                                    StarfieldView(theme: theme, intensity: 1)
                                        .frame(height: 84).clipShape(RoundedRectangle(cornerRadius: 17))
                                    selectionLabel(theme.title, selected: preferences.theme == theme)
                                }
                                .padding(12).calmSurface(radius: 23)
                            }
                            .accessibilityLabel(theme.title)
                            .accessibilityAddTraits(preferences.theme == theme ? .isSelected : [])
                            .accessibilityIdentifier("theme.\(theme.id)")
                        }
                    }
                    Text("Your light").font(.headline).accessibilityAddTraits(.isHeader)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(OrbStyle.allCases) { style in
                            Button { preferences.orbStyle = style } label: {
                                VStack(alignment: .leading, spacing: 0) {
                                    GlassOrbStyle(color: Mood.disappointment.accent, style: style, glow: preferences.glow)
                                        .frame(height: 106)
                                    selectionLabel(style.title, selected: preferences.orbStyle == style)
                                }
                                .padding(12).calmSurface(radius: 23)
                            }
                            .accessibilityLabel(style.title)
                            .accessibilityAddTraits(preferences.orbStyle == style ? .isSelected : [])
                            .accessibilityIdentifier("orbStyle.\(style.id)")
                        }
                    }
                    Text("A gentle touch").font(.headline).accessibilityAddTraits(.isHeader)
                    VStack(spacing: 10) {
                        ForEach(VisualEffect.allCases) { effect in
                            Button { preferences.effect = effect } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: effect.symbol).frame(width: 24)
                                    selectionLabel(effect.title, selected: preferences.effect == effect)
                                }
                                .padding(18).calmSurface(radius: 22)
                            }
                            .accessibilityLabel(effect.title)
                            .accessibilityAddTraits(preferences.effect == effect ? .isSelected : [])
                            .accessibilityIdentifier("effect.\(effect.id)")
                        }
                    }
                }
                .padding(24)
            }
            .background { StarfieldView(theme: preferences.theme, intensity: preferences.intensity) }
            .navigationTitle("Explore")
            .navigationBarTitleDisplayMode(.large)
        }
        .buttonStyle(QuietButtonStyle())
        .tint(.white)
        .preferredColorScheme(.dark)
        .presentationDragIndicator(.visible)
        .presentationDetents([.large])
    }
    private func selectionLabel(_ title: String, selected: Bool) -> some View {
        HStack(alignment: .center) {
            Text(title).font(.subheadline).multilineTextAlignment(.leading)
            Spacer(minLength: 4)
            Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(selected ? .white : .white.opacity(0.35))
                .accessibilityHidden(true)
        }
        .frame(minHeight: 32)
        .foregroundStyle(.white)
    }
}
