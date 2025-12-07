import Foundation

public struct Rect: Equatable, Hashable, Sendable {
    public var position: Vector2
    public var size: Vector2

    @inlinable public init(position: Vector2, size: Vector2) {
        self.position = position
        self.size = size
    }

    @inlinable public static var zero: Rect { .init(position: .zero, size: .zero) }

    @inlinable public var center: Vector2 {
        get { position + size * 0.5 }
        set { position = newValue - size * 0.5 }
    }

    @inlinable public var min: Vector2 {
        get { Vector2(xMin, yMin) }
        set { xMin = newValue.x; yMin = newValue.y }
    }

    @inlinable public var max: Vector2 {
        get { Vector2(xMax, yMax) }
        set { xMax = newValue.x; yMax = newValue.y }
    }

    @inlinable public var xMin: Double {
        get { position.x }
        set { size.x -= newValue - position.x; position.x = newValue }
    }

    @inlinable public var yMin: Double {
        get { position.y }
        set { size.y -= newValue - position.y; position.y = newValue }
    }

    @inlinable public var xMax: Double {
        get { position.x + size.x }
        set { size.x = newValue - position.x }
    }

    @inlinable public var yMax: Double {
        get { position.y + size.y }
        set { size.y = newValue - position.y }
    }
}
