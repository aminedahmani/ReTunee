import Foundation
@testable import Retune

@MainActor final class TestTime: SessionTimeSource {
    var value: TimeInterval = 0
    func now() -> TimeInterval { value }
    func advance(_ seconds: TimeInterval) { value += seconds }
}
@MainActor final class SeededRandom {
    private var state: UInt64 = 19
    func unit() -> Double {
        state = state &* 6364136223846793005 &+ 1
        return Double(state >> 11) / Double(UInt64.max >> 11)
    }
}
