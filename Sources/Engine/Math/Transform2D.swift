import Foundation

public struct Transform2D: Equatable, Hashable, Sendable {
    public var translation: Vector2
    public var rotation: Angle
    public var scale: Vector2
    public var depth: Double

    @inlinable public init(translation: Vector2 = .zero, rotation: Angle = .zero, scale: Vector2 = .one, depth: Double = 0.0) {
        self.translation = translation
        self.rotation = rotation
        self.scale = scale
        self.depth = depth
    }

    @inlinable public static var identity: Transform2D { .init() }

    public static func * (parent: Self, child: Self) -> Self {
        return Self(
            translation: parent.translation + child.translation.rotatedBy(parent.rotation) * parent.scale,
            rotation: parent.rotation + child.rotation,
            scale: parent.scale * child.scale, // FIXME: doesn't support non-uniform child scale if parent has rotation
            depth: parent.depth + child.depth
        )
    }

    public func transformPosition(_ position: Vector2) -> Vector2 {
        return translation + position.rotatedBy(rotation) * scale
    }

    public func transformVector(_ vector: Vector2) -> Vector2 {
        return vector.rotatedBy(rotation) * scale
    }

    public func transformDirection(_ direction: Vector2) -> Vector2 {
        return direction.rotatedBy(rotation)
    }
}
