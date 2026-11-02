import Testing
import Foundation
import CoreGraphics
@testable import Retune

@MainActor struct OrbSpawnCoordinatorTests {
    @Test func positionsRespectBoundsAndProtectedAreas() throws {
        let random = SeededRandom()
        let spawner = OrbSpawnCoordinator(randomUnit: random.unit)
        let bounds = CGRect(x: 0, y: 0, width: 320, height: 580)
        let protected = [CGRect(x: 90, y: 0, width: 140, height: 100), CGRect(x: 0, y: 470, width: 320, height: 110)]
        var previous: CGPoint?
        for _ in 0..<1_000 {
            let point = try #require(spawner.position(in: bounds, radius: 54, avoiding: previous, protected: protected))
            #expect(spawner.isValid(point, in: bounds, radius: 54, protected: protected))
            #expect(point != previous)
            previous = point
        }
    }
    @Test func repeatedRandomValueStillFindsNewPosition() throws {
        let spawner = OrbSpawnCoordinator(randomUnit: { 0.5 })
        let bounds = CGRect(x: 0, y: 0, width: 300, height: 500)
        let first = try #require(spawner.position(in: bounds, radius: 58, avoiding: nil))
        let next = try #require(spawner.position(in: bounds, radius: 58, avoiding: first))
        #expect(next != first)
    }
    @Test func impossibleLayoutReturnsNoUnsafePosition() {
        let spawner = OrbSpawnCoordinator()
        #expect(spawner.position(in: CGRect(x: 0, y: 0, width: 40, height: 40), radius: 58, avoiding: nil) == nil)
        let full = CGRect(x: 0, y: 0, width: 300, height: 500)
        #expect(spawner.position(in: full, radius: 58, avoiding: nil, protected: [full]) == nil)
    }
}
