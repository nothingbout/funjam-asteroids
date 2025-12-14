import Foundation

public struct Math {
    @inlinable public static func sign(_ value: Double) -> Double {
        return value < 0.0 ? -1.0 : 1.0
    }

    @inlinable public static func clamp<T>(_ value: T, min minValue: T, max maxValue: T) -> T where T : Comparable {
        return max(minValue, min(value, maxValue))
    }

    @inlinable public static func clamp01(_ value: Double) -> Double {
        return clamp(value, min: 0.0, max: 1.0)
    }

    @inlinable public static func lerpUnclamped(_ a: Double, _ b: Double, by t: Double) -> Double {
        return a + (b - a) * t
    }

    @inlinable public static func lerp(_ a: Double, _ b: Double, by t: Double) -> Double {
        return lerpUnclamped(a, b, by: clamp01(t))
    }

    @inlinable public static func inverseLerpUnclamped(_ a: Double, _ b: Double, from value: Double) -> Double {
        assert(a != b)
        return (value - a) / (b - a)
    }

    @inlinable public static func inverseLerp(_ a: Double, _ b: Double, from value: Double) -> Double {
        return clamp01(inverseLerpUnclamped(a, b, from: value))
    }

    @inlinable public static func mapUnclamped(_ value: Double, from fromMin: Double, _ fromMax: Double, to toMin: Double, _ toMax: Double) -> Double {
        let t = inverseLerpUnclamped(fromMin, fromMax, from: value)
        return lerpUnclamped(toMin, toMax, by: t)
    }

    @inlinable public static func map(_ value: Double, from fromMin: Double, _ fromMax: Double, to toMin: Double, _ toMax: Double) -> Double {
        let clampedValue = fromMin < fromMax ? clamp(value, min: fromMin, max: fromMax) : clamp(value, min: fromMax, max: fromMin)
        return mapUnclamped(clampedValue, from: fromMin, fromMax, to: toMin, toMax)
    }

    @inlinable public static func moveTowards(_ current: Double, target: Double, maxDelta: Double) -> Double {
        let delta = target - current
        if abs(delta) <= maxDelta { return target }
        return current + sign(delta) * maxDelta
    }

    @inlinable public static func positiveRemainder(_ value: Double, dividingBy divisor: Double) -> Double {
        let remainder = value.truncatingRemainder(dividingBy: divisor)
        return remainder < 0.0 ? remainder + divisor : remainder
    }
}
