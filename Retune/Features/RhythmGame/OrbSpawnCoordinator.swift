import Foundation
import CoreGraphics

struct OrbSpawnCoordinator {
    var randomUnit: () -> Double = { Double.random(in: 0...1) }

    func isValid(_ point: CGPoint, in bounds: CGRect, radius: CGFloat, protected: [CGRect] = []) -> Bool {
        guard let safe = centerBounds(in: bounds, radius: radius),
              point.x.isFinite, point.y.isFinite,
              point.x >= safe.minX, point.x <= safe.maxX,
              point.y >= safe.minY, point.y <= safe.maxY else { return false }
        return !protected.contains { $0.insetBy(dx: -radius, dy: -radius).contains(point) }
    }

    private func centerBounds(in bounds: CGRect, radius: CGFloat) -> CGRect? {
        guard !bounds.isNull, !bounds.isInfinite, radius.isFinite, radius >= 0,
              bounds.width >= radius * 2, bounds.height >= radius * 2 else { return nil }
        return CGRect(x: bounds.minX + radius, y: bounds.minY + radius,
                      width: bounds.width - radius * 2, height: bounds.height - radius * 2)
    }

    func position(in bounds: CGRect, radius: CGFloat, avoiding previous: CGPoint?,
                  protected: [CGRect] = []) -> CGPoint? {
        guard let safe = centerBounds(in: bounds, radius: radius) else { return nil }
        let preferredDistance = min(radius * 2.6, max(safe.width, safe.height) * 0.45)
        var fallback: CGPoint?
        var farthestDistance: CGFloat = -1
        func consider(_ candidate: CGPoint) -> Bool {
            guard isValid(candidate, in: bounds, radius: radius, protected: protected) else { return false }
            let distance = previous.map { hypot(candidate.x - $0.x, candidate.y - $0.y) } ?? .greatestFiniteMagnitude
            if distance > farthestDistance {
                fallback = candidate
                farthestDistance = distance
            }
            return distance >= preferredDistance
        }
        for _ in 0..<48 {
            let candidate = CGPoint(x: safe.minX + min(max(randomUnit(), 0), 1) * safe.width,
                                    y: safe.minY + min(max(randomUnit(), 0), 1) * safe.height)
            if consider(candidate) { return candidate }
        }
        // A bounded fallback also handles deterministic/repeating random sources.
        for row in 0...16 {
            for column in 0...16 {
                let candidate = CGPoint(x: safe.minX + CGFloat(column) / 16 * safe.width,
                                        y: safe.minY + CGFloat(row) / 16 * safe.height)
                if consider(candidate) { return candidate }
            }
        }
        return fallback
    }
}
