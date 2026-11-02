import Testing
import Foundation
@testable import Retune

@MainActor struct CustomizationTests {
    @Test func everyAppearanceIsSelectableAndPersists() throws {
        let name = "ReTuneTests.\(UUID().uuidString)"
        let store = try #require(UserDefaults(suiteName: name))
        defer { store.removePersistentDomain(forName: name) }
        let preferences = UserPreferences(store: store)
        for theme in UniverseTheme.allCases {
            preferences.theme = theme
            #expect(UserPreferences(store: store).theme == theme)
        }
        for style in OrbStyle.allCases {
            preferences.orbStyle = style
            #expect(UserPreferences(store: store).orbStyle == style)
        }
        for effect in VisualEffect.allCases {
            preferences.effect = effect
            #expect(UserPreferences(store: store).effect == effect)
        }
        #expect(UniverseTheme.allCases.count == 4)
        #expect(OrbStyle.allCases.count == 4)
        #expect(VisualEffect.allCases.count == 4)
        // Selection needs only local preferences: no account, balance, or unlock state.
    }
    @Test func comfortSettingsPersist() throws {
        let name = "ReTuneTests.\(UUID().uuidString)"
        let store = try #require(UserDefaults(suiteName: name))
        defer { store.removePersistentDomain(forName: name) }
        let preferences = UserPreferences(store: store)
        preferences.haptics = false
        preferences.reduceMotion = true
        preferences.backgroundAnimation = false
        preferences.stationaryControl = true
        preferences.intensity = 0.4
        preferences.glow = 0.2
        let restored = UserPreferences(store: store)
        #expect(!restored.haptics && restored.reduceMotion && !restored.backgroundAnimation)
        #expect(restored.stationaryControl)
        #expect(restored.intensity == 0.4 && restored.glow == 0.2)
    }
}
