import Foundation
import Engine

class Asteroid {
    private let _shape: AsteroidShape
    private let _difficulty: Double
    private var _rotation: Angle = .zero
    private var _rotationSpeed: Angle = .zero
    private var _position: Vector2 = .zero
    private var _velocity: Vector2 = .zero
    private var _timeSinceHit: Double = 1000.0
    private var _health: Double
    private let _baseColor: Color
    private let _object: RenderObject

    var shape: AsteroidShape { _shape }
    var difficulty: Double { _difficulty }
    var position: Vector2 { get { _position } set { _position = newValue } }
    var velocity: Vector2 { get { _velocity } set { _velocity = newValue } }
    var baseColor: Color { _baseColor }
    var transform: Transform2D { _object.transform }

    init(shape: AsteroidShape, difficulty: Double) {
        _shape = shape
        _difficulty = difficulty
        _baseColor = Color.lerp(Color("#777777")!, Color("#7777FF")!, by: difficulty)
        _health = Math.lerp(10.0, 100.0, by: difficulty)
        _object = RenderObject(
            transform: .identity,
            color: _baseColor,
            data: _shape.renderData()
        )
    }

    func initPosition(_ position: Vector2, rotation: Angle, rotationSpeed: Angle, velocity: Vector2) {
        _position = position
        _rotation = rotation
        _rotationSpeed = rotationSpeed
        _velocity = velocity
    }

    func update(_ context: UpdateContext) {
        let deltaTime = context.frameTime.deltaSeconds
        _rotation += _rotationSpeed * deltaTime
        _position += _velocity * deltaTime
        _object.transform.translation = _position
        _object.transform.rotation = _rotation
        _timeSinceHit += deltaTime

        _object.color = Color.lerp(Color("#FF7777")!, _baseColor, by: _timeSinceHit / 0.1)
    }

    func wrapAround(_ bounds: Rect) {
        let containingRadius = _shape.containingRadius * transform.scale.x
        let outsetBounds = bounds.outset(by: containingRadius)
        if _position.x < outsetBounds.xMin {
            _position.x = outsetBounds.xMax
        }
        else if _position.x > outsetBounds.xMax {
            _position.x = outsetBounds.xMin
        }
        if _position.y < outsetBounds.yMin {
            _position.y = outsetBounds.yMax
        }
        else if _position.y > outsetBounds.yMax {
            _position.y = outsetBounds.yMin
        }
    }

    func handleProjectileCollision(_ projectile: Projectile) -> (impactPoint: Vector2, normal: Vector2)? {
        let lineSegment = (projectile.position, projectile.position + projectile.velocity * 0.03)
        let intersection = _shape.lineSegmentIntersection(lineSegment, asteroidTransform: transform)
        if let enter = intersection {
            let impactPoint = Vector2.lerp(lineSegment.0, lineSegment.1, by: enter)
            let deltaFromCenter = impactPoint - _position
            let projectileDirection = projectile.velocity.direction()
            // _velocity += projectileDirection * 2.0
            _rotationSpeed += .radians(Vector2.cross(deltaFromCenter, projectileDirection) * 0.001)
            _velocity += projectileDirection * 2.0
            _timeSinceHit = 0.0
            _health -= 1.0
            return (impactPoint: impactPoint, normal: deltaFromCenter.direction())
        }
        return nil
    }

    func isDestroyed() -> Bool {
        return _health <= 0.0001
    }

    func render(_ context: RenderContext) {
        context.renderer.renderObject(_object)

        // let boundsObject = RenderObject(
        //     transform: Transform2D(translation: _position, rotation: _rotation, scale: .one),
        //     color: Color("#FF7777")!,
        //     data: .rectangle(width: _shape.shapeBounds.size.x, height: _shape.shapeBounds.size.y, cornerRadius: nil, strokeWidth: 1.0)
        // )
        // context.renderer.renderObject(boundsObject)
    }
}
