import Foundation

public struct Angle: Equatable, Hashable, Sendable {
    public let radians: Double
    @inlinable public var degrees: Double { return radians * (180.0 / .pi) }

    @inlinable public init(radians: Double) { self.radians = radians }
    @inlinable public init(degrees: Double) { self.radians = degrees * (.pi / 180.0) }

    @inlinable public static var zero: Angle { .init(radians: 0.0) }

    @inlinable public static func radians(_ value: Double) -> Self { return .init(radians: value) }
    @inlinable public static func degrees(_ value: Double) -> Self { return .init(degrees: value) }

    @inlinable public static prefix func - (lhs: Self) -> Self { return .radians(-lhs.radians) }
    @inlinable public static func + (lhs: Self, rhs: Self) -> Self { return .radians(lhs.radians + rhs.radians) }
    @inlinable public static func - (lhs: Self, rhs: Self) -> Self {return .radians(lhs.radians - rhs.radians) }
    @inlinable public static func * (lhs: Self, rhs: Double) -> Self { return .radians(lhs.radians * rhs) }
    @inlinable public static func * (lhs: Double, rhs: Self) -> Self { return .radians(lhs * rhs.radians) }
    @inlinable public static func / (lhs: Self, rhs: Double) -> Self { return .radians(lhs.radians / rhs) }
        
    @inlinable public static func += (lhs: inout Self, rhs: Self) { lhs = lhs + rhs }
    @inlinable public static func -= (lhs: inout Self, rhs: Self) { lhs = lhs - rhs }
    @inlinable public static func *= (lhs: inout Self, rhs: Double) { lhs = lhs * rhs }
    @inlinable public static func /= (lhs: inout Self, rhs: Double) { lhs = lhs / rhs }

    @inlinable public static func < (lhs: Self, rhs: Self) -> Bool { return lhs.radians < rhs.radians }
    @inlinable public static func <= (lhs: Self, rhs: Self) -> Bool { return lhs.radians <= rhs.radians }
    @inlinable public static func > (lhs: Self, rhs: Self) -> Bool { return lhs.radians > rhs.radians }
    @inlinable public static func >= (lhs: Self, rhs: Self) -> Bool { return lhs.radians >= rhs.radians }

    @inlinable public func abs() -> Self { return radians < 0.0 ? -self : self }
    @inlinable public func sign() -> Double { return Math.sign(radians) }

    @inlinable public func cosine() -> Double { return cos(radians) }
    @inlinable public func sine() -> Double { return sin(radians) }
    @inlinable public func tangent() -> Double { return tan(radians) }

    @inlinable public func loopingDelta(from: Self, direction: WindingDirection? = nil) -> Self { 
        var deltaRads = (radians - from.radians).truncatingRemainder(dividingBy: 2.0 * .pi)
        switch direction {
        case .none:
            if deltaRads > .pi { deltaRads -= 2.0 * .pi }
            else if deltaRads < -.pi { deltaRads += 2.0 * .pi }
        case .positiveAngle:
            if deltaRads < 0.0 { deltaRads += 2.0 * .pi }
        case .negativeAngle:
            if deltaRads > 0.0 { deltaRads -= 2.0 * .pi }
        }
        return .radians(deltaRads)
    }

    @inlinable public func loopingMoveTowards(_ target: Self, maxDelta: Self, direction: WindingDirection? = nil) -> Self {
        assert(maxDelta >= .zero)
        let delta = target.loopingDelta(from: self, direction: direction)
        if delta.abs() <= maxDelta { return target }
        return self + delta.sign() * maxDelta
    }

    @inlinable public func moveTowardsAbsolute(_ target: Self, maxDelta: Self) -> Self {
        return .radians(Math.moveTowards(radians, target: target.radians, maxDelta: maxDelta.radians))
    }
}
