import Foundation
import Engine

class Projectile {
    private var _timeToDestroy: Double? = nil
    private var _position: Vector2
    private var _velocity: Vector2
    private var _damage: Double

    private let _object: RenderObject

    var isDestroyed: Bool { _timeToDestroy != nil && _timeToDestroy! <= 0.0 }
    var position: Vector2 { _position }
    var velocity: Vector2 { _velocity }
    var damage: Double { _damage }

    init(position: Vector2, velocity: Vector2, damage: Double) {
        _position = position
        _velocity = velocity
        _damage = damage
        _object = RenderObject(
            transform: .identity,
            color: Color("#FF3333")!,
            data: .text(text: "|", fontSize: 24.0)
        )
    }

    func destroyAfter(_ seconds: Double) {
        if _timeToDestroy == nil || seconds < _timeToDestroy! {
            _timeToDestroy = seconds
        }
    }

    func isOutsideOfBounds(_ bounds: Rect) -> Bool {
        return !bounds.contains(_position)
    }

    func update(_ context: UpdateContext) {
        _position += _velocity * context.frameTime.deltaSeconds
        _object.transform.translation = _position
        _object.transform.rotation = _velocity.angle() + .degrees(90.0)
        if _timeToDestroy != nil {
            _timeToDestroy! -= context.frameTime.deltaSeconds
        }
    }

    func render(_ context: RenderContext) {
        context.renderer.renderObject(_object)
    }
}
