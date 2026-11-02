import Testing
@testable import Retune

@MainActor struct RhythmPacingEngineTests {
    @Test func orbPacingFollowsEveryTrackAndPlateaus() {
        for track in MusicTrack.all {
            let clock = TestTime()
            var configuration = track.mood.configuration
            configuration.transitionDuration = track.duration
            let engine = RhythmPacingEngine(configuration: configuration, timeSource: clock)
            engine.start()
            let accelerates = track.mood == .sadness
            #expect(abs(engine.snapshot.orbRevealDelay - (accelerates ? 0.8 : 0.08)) < 0.000001)
            var previous = engine.snapshot.orbRevealDelay
            for _ in 0..<100 {
                clock.advance(track.duration / 100)
                let delay = engine.snapshot.orbRevealDelay
                #expect(accelerates ? delay <= previous : delay >= previous)
                previous = delay
            }
            #expect(abs(engine.snapshot.orbRevealDelay - (accelerates ? 0.08 : 0.8)) < 0.000001)
            #expect(abs(engine.snapshot.progress - 1) < 0.000001)
            clock.advance(10_000)
            #expect(abs(engine.snapshot.orbRevealDelay - previous) < 0.000001)
        }
    }
    @Test func progressesWithoutTapsAndRemainsEndless() {
        let clock = TestTime()
        let engine = RhythmPacingEngine(configuration: Mood.anger.configuration, timeSource: clock)
        engine.start()
        clock.advance(240)
        #expect(engine.snapshot.bpm == 100)
        clock.advance(10_000_000)
        #expect(engine.snapshot.bpm == 60)
        #expect(engine.isRunning)
        #expect(engine.snapshot.beatPhase >= 0 && engine.snapshot.beatPhase < 1)
    }
    @Test func pauseFreezesTimeAndPhase() {
        let clock = TestTime()
        let engine = RhythmPacingEngine(configuration: Mood.sadness.configuration, timeSource: clock)
        engine.start()
        clock.advance(31)
        engine.pause()
        let before = engine.snapshot
        clock.advance(9_000)
        engine.pause()
        #expect(engine.snapshot.activeTime == before.activeTime)
        #expect(engine.snapshot.beats == before.beats)
        engine.resume()
        engine.resume()
        clock.advance(2)
        #expect(engine.snapshot.activeTime == 33)
    }
    @Test func stopAndRestartClearElapsedTime() {
        let clock = TestTime()
        let engine = RhythmPacingEngine(configuration: Mood.anxiety.configuration, timeSource: clock)
        engine.start(); clock.advance(500); engine.stop()
        #expect(!engine.isRunning)
        #expect(engine.snapshot.activeTime == 0)
        clock.advance(500); engine.start()
        #expect(engine.snapshot.bpm == 140)
        #expect(engine.snapshot.activeTime == 0)
    }
}
