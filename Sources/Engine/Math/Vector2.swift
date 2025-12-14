import Foundation

public struct Vector2: Equatable, Hashable, Sendable {
    public var x: Double
    public var y: Double

    @inlinable public init(_ x: Double, _ y: Double) { self.x = x; self.y = y }
    public static let zero = Self(0.0, 0.0)
    public static let one = Self(1.0, 1.0)

    public func withX(_ newX: Double) -> Self { .init(newX, y) }
    public func withY(_ newY: Double) -> Self { .init(x, newY) }

    @inlinable public static prefix func - (lhs: Self) -> Self { .init(-lhs.x, -lhs.y) }
    @inlinable public static func + (lhs: Self, rhs: Self) -> Self { .init(lhs.x + rhs.x, lhs.y + rhs.y) }
    @inlinable public static func - (lhs: Self, rhs: Self) -> Self { .init(lhs.x - rhs.x, lhs.y - rhs.y) }
    @inlinable public static func * (lhs: Self, rhs: Self) -> Self { .init(lhs.x * rhs.x, lhs.y * rhs.y) }
    @inlinable public static func / (lhs: Self, rhs: Self) -> Self { .init(lhs.x / rhs.x, lhs.y / rhs.y) }
    @inlinable public static func * (lhs: Self, rhs: Double) -> Self { .init(lhs.x * rhs, lhs.y * rhs) }
    @inlinable public static func / (lhs: Self, rhs: Double) -> Self { .init(lhs.x / rhs, lhs.y / rhs) }

    @inlinable public static func += (lhs: inout Self, rhs: Self) { lhs = lhs + rhs }
    @inlinable public static func -= (lhs: inout Self, rhs: Self) { lhs = lhs - rhs }
    @inlinable public static func *= (lhs: inout Self, rhs: Self) { lhs = lhs * rhs }
    @inlinable public static func /= (lhs: inout Self, rhs: Self) { lhs = lhs / rhs }
    @inlinable public static func *= (lhs: inout Self, rhs: Double) { lhs = lhs * rhs }
    @inlinable public static func /= (lhs: inout Self, rhs: Double) { lhs = lhs / rhs }

    @inlinable public func map(_ f: (Double) -> Double) -> Self { .init(f(x), f(y)) }
    @inlinable public func minValue() -> Double { min(x, y) }
    @inlinable public func maxValue() -> Double { max(x, y) }

    @inlinable public func approximately(other: Self, epsilon: Double = 1e-6) -> Bool {
        abs(x - other.x) < epsilon && abs(y - other.y) < epsilon
    }

    @inlinable public func sqrMagnitude() -> Double { x * x + y * y }
    @inlinable public func magnitude() -> Double { sqrt(sqrMagnitude()) }

    @inlinable public func direction(epsilon: Double = 1e-6) -> Self? { directionAndMagnitude(epsilon: epsilon)?.0 ?? nil }
    @inlinable public func directionAndMagnitude(epsilon: Double = 1e-6) -> (Self, Double)? {
        let mag = magnitude()
        if mag <= epsilon { return nil }
        return (self / mag, mag)
    }

    @inlinable public static func dot(_ a: Self, _ b: Self) -> Double { a.x * b.x + a.y * b.y }
    @inlinable public static func cross(_ a: Self, _ b: Self) -> Double { a.x * b.y - a.y * b.x }

    @inlinable public func angle() -> Angle { return .radians(atan2(y, x)) }
    @inlinable public init(angle: Angle, magnitude: Double = 1.0) {
        self.x = magnitude * angle.cosine()
        self.y = magnitude * angle.sine()
    }

    @inlinable public func rotatedBy(_ angle: Angle) -> Self {
        let cos = angle.cosine();
        let sin = angle.sine();
        return .init(x * cos - y * sin, x * sin + y * cos)
    }

    @inlinable public func turned90(towards direction: WindingDirection) -> Self {
        switch direction {
        case .positiveAngle:
            return .init(-y, x)
        case .negativeAngle:
            return .init(y, -x)
        }
    }

    @inlinable public static func lerpUnclamped(_ a: Self, _ b: Self, by t: Double) -> Self {
        .init(Math.lerpUnclamped(a.x, b.x, by: t), Math.lerpUnclamped(a.y, b.y, by: t))
    }
    @inlinable public static func lerp(_ a: Self, _ b: Self, by t: Double) -> Self {
        lerpUnclamped(a, b, by: Math.clamp01(t))
    }

    @inlinable public static func moveTowards(_ current: Self, target: Self, maxDelta: Double) -> Self {
        let (direction, distance) = (target - current).directionAndMagnitude() ?? (.zero, 0.0)
        if distance <= maxDelta {
            return target
        }
        return current + direction * maxDelta
    }

    public static func twoLineSegmentsIntersection(_ a: (Vector2, Vector2), _ b: (Vector2, Vector2), 
        extendingToInfinity: Bool = false, epsilon: Double = 1e-5) -> (posA: Double, posB: Double)?
    {
        let (a1, a2) = a
        let (b1, b2) = b

        let c = (b2.y - b1.y) * (a2.x - a1.x) - (b2.x - b1.x) * (a2.y - a1.y)
        if abs(c) < epsilon { return nil } // parallel lines

        let posA = ((b2.x - b1.x) * (a1.y - b1.y) - (b2.y - b1.y) * (a1.x - b1.x)) / c;
        if !extendingToInfinity && (posA < 0.0 || posA > 1.0) { return nil }

        let posB = ((a2.x - a1.x) * (a1.y - b1.y) - (a2.y - a1.y) * (a1.x - b1.x)) / c;
        if !extendingToInfinity && (posB < 0.0 || posB > 1.0) { return nil }

        return (posA: posA, posB: posB)
    }

    public static func lineSegmentCircleIntersection(_ lineSegment: (Vector2, Vector2), 
        center: Vector2, radius: Double, extendingToInfinity: Bool = false, epsilon: Double = 1e-5) -> (enter: Double, exit: Double)?
    {
        let (start, end) = lineSegment
        let delta = end - start
        let sqrLength = delta.sqrMagnitude()
        if sqrLength < epsilon * epsilon {
            if (start - center).sqrMagnitude() <= radius * radius {
                return (0.0, 1.0)
            }
            return nil
        }
        
        let f = start - center
        let b = 2.0 * Vector2.dot(f, delta)
        let c = f.sqrMagnitude() - radius * radius
        
        let D = b * b - 4 * sqrLength * c
        if D < 0 { return nil }
        
        let sqrtD = sqrt(D)
        let t1 = (-b - sqrtD) / (2 * sqrLength)
        let t2 = (-b + sqrtD) / (2 * sqrLength)

        var (enter, exit) = t1 < t2 ? (t1, t2) : (t2, t1)
        if !extendingToInfinity {
            if enter > 1.0 || exit < 0.0 { return nil }
            if enter < 0.0 { enter = 0.0 }
            if exit > 1.0 { exit = 1.0 }
        }
        return (enter, exit)
    }
}
