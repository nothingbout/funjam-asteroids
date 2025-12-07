import Foundation

public struct Color: Equatable, Hashable, Sendable {
    public var r: Double
    public var g: Double
    public var b: Double
    public var a: Double

    public init(r: Double, g: Double, b: Double, a: Double) {
        self.r = r
        self.g = g
        self.b = b
        self.a = a
    }

    public static var black: Self { .init(r: 0, g: 0, b: 0, a: 1) }
    public static var white: Self { .init(r: 1, g: 1, b: 1, a: 1) }

    public init?(_ str: String) {
        if str.hasPrefix("#") {
            var remaining = str.dropFirst()
            switch remaining.count {
                case 6, 8:
                    func hexToDouble(_ hex: Substring) -> Double? {
                        if let int = Int(hex, radix: 16) {
                            return Double(int) / 255.0
                        }
                        return nil
                    }

                    guard let r = hexToDouble(remaining.prefix(2)) else { return nil }
                    remaining = remaining.dropFirst(2)
                    guard let g = hexToDouble(remaining.prefix(2)) else { return nil }
                    remaining = remaining.dropFirst(2)
                    guard let b = hexToDouble(remaining.prefix(2)) else { return nil }
                    remaining = remaining.dropFirst(2)

                    if !remaining.isEmpty {
                        guard let a = hexToDouble(remaining.prefix(2)) else { return nil }
                        self.init(r: r, g: g, b: b, a: a)
                    }
                    else {
                        self.init(r: r, g: g, b: b, a: 1.0)
                    }
                default:
                    return nil
            }
        }
        else {
            return nil
        }
    }

    public func toHexString() -> String {
        func toInt(_ double: Double) -> Int {
            return Int(round(Math.clamp01(double) * 255.0))
        }
        func toString(_ double: Double) -> String {
            let int = Int(round(double * 255.0))
            let str = String(int, radix: 16)
            return str.count == 1 ? "0\(str)" : str
        }
        if a == 1.0 {
            return "#\(toString(r))\(toString(g))\(toString(b))"
        }
        else {
            return "#\(toString(r))\(toString(g))\(toString(b))\(toString(a))"
        }
    }

    public static func lerp(_ a: Color, _ b: Color, by t: Double) -> Color {
        return Color(
            r: Math.lerp(a.r, b.r, by: t),
            g: Math.lerp(a.g, b.g, by: t),
            b: Math.lerp(a.b, b.b, by: t),
            a: Math.lerp(a.a, b.a, by: t)
        )
    }
}
