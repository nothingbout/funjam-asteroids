import Foundation
import Synchronization

public enum RenderData: Equatable, Sendable {
    case text(text: String, fontSize: Double)
    case rectangle(width: Double, height: Double, cornerRadius: Double? = nil, strokeWidth: Double? = nil)
}

public struct RenderObjectId: Equatable, Hashable, Sendable {
    private static let _nextValue = Atomic<UInt64>(1)

    private let _value: UInt64

    public init() {
        (_value, _) = Self._nextValue.wrappingAdd(1, ordering: .relaxed)
    }
}

public class RenderObject {
    public private(set) var id: RenderObjectId
    public var transform: Transform2D
    public var relativePivot: Vector2
    public var color: Color
    public var data: RenderData

    public required init(transform: Transform2D, relativePivot: Vector2 = Vector2(0.5, 0.5), color: Color, data: RenderData) {
        id = RenderObjectId()
        self.transform = transform
        self.relativePivot = relativePivot
        self.color = color
        self.data = data
    }

    public static func line(from: Vector2, to: Vector2, width lineWidth: Double, color: Color, depth: Double) -> Self {
        let (direction, length) = (to - from).directionAndMagnitude()
        return Self(
            transform: Transform2D(
                translation: Vector2.lerp(from, to, by: 0.5),
                rotation: direction.angle(),
                scale: Vector2(1.0, 1.0),
                depth: depth
            ),
            color: color,
            data: .rectangle(width: length, height: lineWidth)
        )
    }

    public static func rectangle(_ rect: Rect, color: Color, cornerRadius: Double? = nil, strokeWidth: Double? = nil) -> Self {
        Self(
            transform: Transform2D(translation: rect.center, rotation: .zero, scale: .one), 
            color: color, 
            data: .rectangle(width: rect.size.x, height: rect.size.y, cornerRadius: cornerRadius, strokeWidth: strokeWidth)
        )
    }
}
