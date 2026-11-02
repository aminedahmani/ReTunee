import Testing
import Foundation
import CoreGraphics
@testable import Retune

@MainActor struct RhythmGameViewModelTests {
    private func game(_ mood: Mood = .anxiety, clock: TestTime = TestTime()) -> RhythmGameViewModel {
        let random = SeededRandom()
        let model = RhythmGameViewModel(mood: mood, timeSource: clock, spawner: .init(randomUnit: random.unit))
        model.updateLayout(size: CGSize(width: 340, height: 490))
        return model
    }
    @Test func startsWithOneOrbAndRevealsOneReplacementAfterTap() throws {
        let clock = TestTime()
        let model = game(clock: clock)
        let first = try #require(model.activeOrb)
        #expect(model.tap(orbID: first.id))
        #expect(model.activeOrb == nil)
        clock.advance(0.079)
        model.advance()
        #expect(model.activeOrb == nil)
        clock.advance(0.002)
        model.advance()
        let next = try #require(model.activeOrb)
        #expect(next.id != first.id)
        #expect(next.position != first.position)
        #expect(model.echoes.count == 1)
    }
    @Test func staleTapIsConsumedExactlyOnce() throws {
        let clock = TestTime()
        let model = game(clock: clock)
        let first = try #require(model.activeOrb)
        #expect(model.tap(orbID: first.id))
        for _ in 0..<100 { #expect(!model.tap(orbID: first.id)) }
        #expect(model.activeOrb == nil)
        clock.advance(0.081)
        model.advance()
        let replacement = try #require(model.activeOrb)
        for _ in 0..<100 { #expect(!model.tap(orbID: first.id)) }
        #expect(model.activeOrb?.id == replacement.id)
        #expect(model.echoes.count == 1)
    }
    @Test func rapidValidTapsRemainBounded() throws {
        let clock = TestTime()
        let model = game(clock: clock)
        var identities = Set<UUID>()
        for _ in 0..<1_000 {
            let orb = try #require(model.activeOrb)
            #expect(identities.insert(orb.id).inserted)
            #expect(model.tap(orbID: orb.id))
            #expect(model.echoes.count <= 4)
            #expect(model.activeOrb == nil)
            clock.advance(1)
            model.advance()
        }
        #expect(model.activeOrb != nil)
    }
    @Test func idleAndMissedBeatsNeverExpireOrb() throws {
        let clock = TestTime()
        let model = game(clock: clock)
        let first = try #require(model.activeOrb)
        clock.advance(10_000_000)
        model.advance()
        #expect(model.pacing.snapshot.bpm == 60)
        #expect(model.activeOrb?.id == first.id)
        #expect(model.echoes.isEmpty)
        #expect(!model.hasExited)
        #expect(model.tap(orbID: first.id))
    }
    @Test func tapsDoNotAlterTempoOrSessionTime() throws {
        let clock = TestTime()
        let model = game(clock: clock)
        clock.advance(123)
        for _ in 0..<50 {
            let snapshot = model.pacing.snapshot
            model.tap(orbID: try #require(model.activeOrb).id)
            #expect(model.pacing.snapshot.bpm == snapshot.bpm)
            #expect(model.pacing.snapshot.activeTime == snapshot.activeTime)
            clock.advance(1)
            model.advance()
        }
    }
    @Test func backgroundAndManualPauseComposeCorrectly() throws {
        let clock = TestTime()
        let model = game(clock: clock)
        clock.advance(10)
        model.setAppActive(false)
        clock.advance(100)
        #expect(model.pacing.snapshot.activeTime == 10)
        #expect(!model.tap(orbID: try #require(model.activeOrb).id))
        model.setAppActive(true)
        clock.advance(1)
        #expect(model.pacing.snapshot.activeTime == 11)
        model.togglePause()
        model.setAppActive(false); model.setAppActive(true)
        #expect(!model.pacing.isRunning)
        model.togglePause()
        #expect(model.pacing.isRunning)
    }
    @Test func startWhileInactiveDoesNotAccumulateTime() {
        let clock = TestTime()
        let model = RhythmGameViewModel(mood: .sadness, timeSource: clock)
        model.setAppActive(false)
        model.updateLayout(size: CGSize(width: 320, height: 400))
        clock.advance(5_000)
        #expect(model.pacing.snapshot.activeTime == 0)
        model.setAppActive(true)
        clock.advance(1)
        #expect(model.pacing.snapshot.activeTime == 1)
    }
    @Test func exitCleansUpAndCannotBeResumed() throws {
        let clock = TestTime()
        let model = game(clock: clock)
        model.tap(orbID: try #require(model.activeOrb).id)
        model.exit()
        model.setAppActive(true)
        model.updateLayout(size: CGSize(width: 400, height: 600))
        clock.advance(100)
        model.advance()
        #expect(model.activeOrb == nil)
        #expect(model.echoes.isEmpty)
        #expect(!model.pacing.isRunning)
        #expect(model.hasExited)
    }
    @Test func reenteringCreatesFreshSession() throws {
        let first = game()
        let identity = try #require(first.activeOrb).id
        first.exit()
        let next = game()
        #expect(next.activeOrb?.id != identity)
        #expect(next.pacing.snapshot.activeTime == 0)
        #expect(next.reconstruction == 0)
        #expect(!next.hasExited)
    }
    @Test func resizingKeepsOrbSafeAndRecoversFromZeroSize() throws {
        let model = game()
        model.updateLayout(size: .zero)
        #expect(model.activeOrb == nil)
        model.updateLayout(size: CGSize(width: 200, height: 180))
        let orb = try #require(model.activeOrb)
        #expect(OrbSpawnCoordinator().isValid(orb.position, in: CGRect(x: 0, y: 0, width: 200, height: 180), radius: 58))
    }
    @Test func calmingMoodsSoftenHaptics() {
        let clock = TestTime()
        let model = game(.anger, clock: clock)
        let initial = model.hapticIntensity
        clock.advance(480)
        #expect(model.hapticIntensity < initial)
        #expect(model.hapticIntensity > 0)
    }
    @Test func restorationNeverEndsDisappointment() throws {
        let clock = TestTime()
        let model = game(.disappointment, clock: clock)
        for _ in 0..<50 {
            model.tap(orbID: try #require(model.activeOrb).id)
            clock.advance(1)
            model.advance()
        }
        #expect(model.reconstruction == 1)
        #expect(model.activeOrb != nil)
        #expect(model.pacing.isRunning)
        #expect(!model.hasExited)
    }

    @Test func lateSessionWaitsLongerAndDoesNotAutospawnAgain() throws {
        let clock = TestTime()
        let model = game(clock: clock)
        clock.advance(480)
        let first = try #require(model.activeOrb)
        model.tap(orbID: first.id)
        clock.advance(0.79)
        model.advance()
        #expect(model.activeOrb == nil)
        clock.advance(0.02)
        model.advance()
        let second = try #require(model.activeOrb)
        clock.advance(10_000)
        model.advance()
        #expect(model.activeOrb?.id == second.id)
    }

    @Test func pendingRevealFreezesDuringPauseAndBackground() throws {
        let clock = TestTime()
        let model = game(clock: clock)
        clock.advance(480)
        model.tap(orbID: try #require(model.activeOrb).id)
        clock.advance(0.2)
        model.togglePause()
        clock.advance(100)
        model.advance()
        #expect(model.activeOrb == nil)
        model.togglePause()
        clock.advance(0.2)
        model.setAppActive(false)
        clock.advance(100)
        model.advance()
        #expect(model.activeOrb == nil)
        model.setAppActive(true)
        clock.advance(0.39)
        model.advance()
        #expect(model.activeOrb == nil)
        clock.advance(0.02)
        model.advance()
        #expect(model.activeOrb != nil)
    }

    @Test func resizingDuringWaitNeverRevealsEarlyOrOutsideNewBounds() throws {
        let clock = TestTime()
        let model = game(clock: clock)
        model.tap(orbID: try #require(model.activeOrb).id)
        model.updateLayout(size: CGSize(width: 220, height: 180))
        #expect(model.activeOrb == nil)
        model.updateLayout(size: .zero)
        clock.advance(1)
        model.advance()
        #expect(model.activeOrb == nil)
        model.updateLayout(size: CGSize(width: 220, height: 180))
        model.advance()
        let next = try #require(model.activeOrb)
        #expect(OrbSpawnCoordinator().isValid(next.position, in: CGRect(x: 0, y: 0, width: 220, height: 180), radius: 58))
    }
    @Test(arguments: Mood.allCases)
    func trackDurationControlsTapPacingWithoutAutomaticSpawns(mood: Mood) throws {
        let clock = TestTime()
        let model = RhythmGameViewModel(mood: mood, trackDuration: 30, timeSource: clock)
        model.updateLayout(size: CGSize(width: 340, height: 490))
        let initial = try #require(model.activeOrb)
        if mood == .sadness {
            model.tap(orbID: initial.id)
            clock.advance(0.79)
            model.advance()
            #expect(model.activeOrb == nil)
            clock.advance(0.02)
            model.advance()
            #expect(model.activeOrb != nil)
        }
        let heldOrb = try #require(model.activeOrb)
        clock.advance(30)
        model.advance()
        #expect(model.activeOrb?.id == heldOrb.id)
        #expect(model.pacing.snapshot.progress == 1)
        model.tap(orbID: heldOrb.id)
        clock.advance(mood == .sadness ? 0.079 : 0.79)
        model.advance()
        #expect(model.activeOrb == nil)
        clock.advance(0.02)
        model.advance()
        #expect(model.activeOrb != nil)
    }

    @Test(arguments: Mood.allCases)
    func switchingTracksRestartsPacingAndClearsPendingRevealWhilePaused(mood: Mood) throws {
        let clock = TestTime()
        let model = RhythmGameViewModel(mood: mood, trackDuration: 30, timeSource: clock)
        model.updateLayout(size: CGSize(width: 340, height: 490))
        clock.advance(29)
        model.tap(orbID: try #require(model.activeOrb).id)
        model.togglePause()
        model.restart(trackDuration: 60)
        #expect(model.pacing.configuration.transitionDuration == 60)
        #expect(model.pacing.snapshot.activeTime == 0)
        #expect(model.pacing.snapshot.progress == 0)
        #expect(model.isPaused)
        #expect(!model.pacing.isRunning)
        #expect(model.echoes.isEmpty)
        let held = try #require(model.activeOrb).id
        clock.advance(200)
        model.advance()
        #expect(model.activeOrb?.id == held)
        #expect(model.pacing.snapshot.activeTime == 0)
        model.togglePause()
        clock.advance(30)
        #expect(model.pacing.snapshot.progress == 0.5)
    }

}
