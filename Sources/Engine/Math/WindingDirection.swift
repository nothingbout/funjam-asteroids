import Foundation

public enum WindingDirection: Hashable, Sendable {
    case positiveAngle
    case negativeAngle

    public func opposite() -> Self {
        return self == .positiveAngle ? .negativeAngle : .positiveAngle
    }
}
