import SwiftUI

enum UniverseTheme: String, CaseIterable, Identifiable {
    case midnight = "Midnight Universe", nebula = "Soft Nebula", ocean = "Deep Ocean", aurora = "Aurora"
    var id: String { rawValue }
    var title: String {
        switch self {
        case .midnight: String(localized: "Midnight Universe")
        case .nebula: String(localized: "Soft Nebula")
        case .ocean: String(localized: "Deep Ocean")
        case .aurora: String(localized: "Aurora")
        }
    }
    var tint: Color {
        switch self {
        case .midnight: Color(hex: 0x44467C)
        case .nebula: Color(hex: 0x9057A6)
        case .ocean: Color(hex: 0x237D93)
        case .aurora: Color(hex: 0x5CA88C)
        }
    }
}
enum OrbStyle: String, CaseIterable, Identifiable {
    case glass = "Glass", glow = "Soft Glow", pearl = "Pearl", nebula = "Nebula"
    var id: String { rawValue }
    var title: String {
        switch self {
        case .glass: String(localized: "Glass")
        case .glow: String(localized: "Soft Glow")
        case .pearl: String(localized: "Pearl")
        case .nebula: String(localized: "Nebula")
        }
    }
}
enum VisualEffect: String, CaseIterable, Identifiable {
    case sparkles = "Gentle Sparkles", ripple = "Soft Ripple", dust = "Floating Dust", minimal = "Minimal"
    var id: String { rawValue }
    var title: String {
        switch self {
        case .sparkles: String(localized: "Gentle Sparkles")
        case .ripple: String(localized: "Soft Ripple")
        case .dust: String(localized: "Floating Dust")
        case .minimal: String(localized: "Minimal")
        }
    }
    var symbol: String {
        switch self {
        case .sparkles: "sparkles"
        case .ripple: "circle.dotted"
        case .dust: "sun.dust"
        case .minimal: "circle"
        }
    }
}

// Native storage wrappers keep every view in sync without a preferences singleton.
struct UserPreferences: DynamicProperty {
    @AppStorage var theme: UniverseTheme
    @AppStorage var orbStyle: OrbStyle
    @AppStorage var effect: VisualEffect
    @AppStorage var musicEnabled: Bool
    @AppStorage var musicVolume: Double
    @AppStorage var haptics: Bool
    @AppStorage var reduceMotion: Bool
    @AppStorage var backgroundAnimation: Bool
    @AppStorage var stationaryControl: Bool
    @AppStorage var intensity: Double
    @AppStorage var glow: Double

    init(store: UserDefaults? = nil) {
        _theme = AppStorage(wrappedValue: .midnight, "appearance.theme", store: store)
        _orbStyle = AppStorage(wrappedValue: .glass, "appearance.orb", store: store)
        _effect = AppStorage(wrappedValue: .ripple, "appearance.effect", store: store)
        _musicEnabled = AppStorage(wrappedValue: true, "music.enabled", store: store)
        _musicVolume = AppStorage(wrappedValue: 1, "music.volume", store: store)
        _haptics = AppStorage(wrappedValue: true, "settings.haptics", store: store)
        _reduceMotion = AppStorage(wrappedValue: false, "settings.reduceMotion", store: store)
        _backgroundAnimation = AppStorage(wrappedValue: true, "settings.backgroundAnimation", store: store)
        _stationaryControl = AppStorage(wrappedValue: false, "settings.stationaryControl", store: store)
        _intensity = AppStorage(wrappedValue: 0.65, "settings.intensity", store: store)
        _glow = AppStorage(wrappedValue: 0.7, "settings.glow", store: store)
    }
}
