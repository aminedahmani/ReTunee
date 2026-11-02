import Testing
import Foundation
@testable import Retune

@MainActor struct OnboardingTests {
    @Test func shownOnceEvenWhenFirstLaunchIsInterrupted() throws {
        let name = "OnboardingTests-\(UUID())"
        let store = try #require(UserDefaults(suiteName: name))
        defer { store.removePersistentDomain(forName: name) }
        #expect(OnboardingGate(store: store).consumeFirstLaunch())
        // No completion call: the user may have quit in the middle of the walkthrough.
        let reopened = try #require(UserDefaults(suiteName: name))
        #expect(!OnboardingGate(store: reopened).consumeFirstLaunch())
        #expect(!OnboardingGate(store: reopened).consumeFirstLaunch())
    }
}
