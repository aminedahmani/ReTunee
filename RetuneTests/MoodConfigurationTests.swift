import Testing
import Foundation
@testable import Retune

@MainActor struct MoodConfigurationTests {
    @Test(arguments: Mood.allCases)
    func correctEndpoints(mood: Mood) {
        let config = mood.configuration
        let expectedStart: Double = mood == .sadness ? 60 : 140
        let expectedEnd: Double = mood == .sadness ? 100 : 60
        #expect(config.bpm(at: 0) == expectedStart)
        #expect(config.bpm(at: 480) == expectedEnd)
        #expect(config.bpm(at: 10_000_000) == expectedEnd)
    }
    @Test(arguments: Mood.allCases)
    func smoothMonotonicCurve(mood: Mood) {
        let config = mood.configuration
        var previous = config.bpm(at: 0)
        for second in 1...600 {
            let bpm = config.bpm(at: Double(second))
            #expect(abs(bpm - previous) < 0.26)
            if config.targetBPM < config.startBPM { #expect(bpm <= previous) }
            else { #expect(bpm >= previous) }
            previous = bpm
        }
    }
    @Test func continuousPhaseAndCorrectDerivative() {
        let config = Mood.anxiety.configuration
        for t in [0.0, 120, 240, 479.99, 480, 481, 10_000] {
            let delta = 0.001
            let numericalBPM = (config.beats(at: t + delta) - config.beats(at: t)) / delta * 60
            #expect(abs(numericalBPM - config.bpm(at: t)) < 0.001)
        }
    }
    @Test func configurableDuration() {
        let config = MoodConfiguration(startBPM: 140, targetBPM: 60, transitionDuration: 20)
        #expect(config.bpm(at: 10) == 100)
        #expect(config.bpm(at: 20) == 60)
        #expect(config.bpm(at: -10) == 140)
        let immediate = MoodConfiguration(startBPM: 140, targetBPM: 60, transitionDuration: 0)
        #expect(immediate.bpm(at: 0) == 60)
        #expect(immediate.beats(at: 100) == 100)
    }
}
