import Foundation
import Engine

class Asteroid {
    enum AsteroidType {
        case normal
        case resource
        case background
    }

    private let _type: AsteroidType
    private let _shape: AsteroidShape
    private let _difficulty: Double
    private var _rotation: Angle = .zero
    private var _baseRotationSpeed: Angle = .zero
    private var _rotationSpeed: Angle = .zero
    private var _position: Vector2 = .zero
    private var _velocity: Vector2 = .zero
    private var _timeSinceHit: Double = 1000.0
    private var _hitAxis: Vector2? = nil
    private var _health: Double
    private let _baseColor: Color
    private let _object: RenderObject

    var type: AsteroidType { _type }
    var shape: AsteroidShape { _shape }
    var difficulty: Double { _difficulty }
    var rotation: Angle { _rotation }
    var rotationSpeed: Angle { _rotationSpeed }
    var position: Vector2 { _position }
    var velocity: Vector2 { _velocity }
    var baseColor: Color { _baseColor }
    var transform: Transform2D { _object.transform }
    var hitAxis: Vector2? { _hitAxis }

    init(type: AsteroidType, shape: AsteroidShape, difficulty: Double) {
        _type = type
        _shape = shape
        _difficulty = difficulty
        _baseColor = _type == .background ? Color("#101010")! : Color.lerp(Color("#777777")!, Color("#7777FF")!, by: difficulty)
        _health = 50.0
        if difficulty > 0.3 {
            _health *= 5
        }
        if difficulty > 0.8 {
            _health *= 5
        }
        _object = RenderObject(
            transform: .identity,
            color: _baseColor,
            data: _shape.renderData()
        )
        if _type == .background {
            _object.transform.scale = .one * 1.5
        }
    }

    func initPosition(_ position: Vector2, rotation: Angle, baseRotationSpeed: Angle, startRotationSpeed: Angle, velocity: Vector2) {
        _position = position
        _rotation = rotation
        _baseRotationSpeed = baseRotationSpeed
        _rotationSpeed = startRotationSpeed
        _velocity = velocity
    }

    func update(_ context: UpdateContext) {
        let deltaTime = context.frameTime.deltaSeconds
        _rotationSpeed = _rotationSpeed.loopingMoveTowards(_baseRotationSpeed, maxDelta: _rotationSpeed.loopingDelta(from: _baseRotationSpeed).abs() * 0.2 * deltaTime)
        _rotation += _rotationSpeed * deltaTime
        _position += _velocity * deltaTime
        _object.transform.translation = _position
        _object.transform.rotation = _rotation
        _timeSinceHit += deltaTime

        if _type == .resource {
            _velocity *= max(0, (1.0 - deltaTime * 0.5))
            _rotationSpeed *= max(0, (1.0 - deltaTime * 0.5))
        }

        _object.color = Color.lerp(Color("#FF7777")!, _baseColor, by: _timeSinceHit / 0.1)
    }
    
    func updateAttraction(_ context: UpdateContext, targetPosition: Vector2, targetVelocity: Vector2, targetRadius: Double, 
        attractionDistance: Double, positionAttractionForce: Double, velocityAttractionForce: Double) {
        if _type != .resource {
            return
        }
        let offset = targetPosition - _position
        let (direction, distance) = offset.directionAndMagnitude() ?? (.zero, 0.0)
        if distance > targetRadius + attractionDistance {
            return
        }

        if distance > targetRadius {
            let forceAmount = Math.map(distance, from: targetRadius, targetRadius + attractionDistance, to: 1.0, 0.0)
            _velocity += direction * (forceAmount * positionAttractionForce * context.frameTime.deltaSeconds)
        }

        if velocityAttractionForce > 0.0 {
            let targetVelocityDirection = targetVelocity.direction() ?? .zero
            let velocityDelta = targetVelocity - _velocity
            let velocityForceAmount = max(0.0, Vector2.dot(velocityDelta, direction))
            _velocity += targetVelocityDirection * (velocityForceAmount * velocityAttractionForce * context.frameTime.deltaSeconds)
        }
    }

    func wrapAround(_ bounds: Rect) -> Bool {
        let containingRadius = _shape.containingRadius * transform.scale.x
        let outsetBounds = bounds.outset(by: containingRadius)
        var wrapped = false
        if _position.x < outsetBounds.xMin {
            _position.x = outsetBounds.xMax
            wrapped = true
        }
        else if _position.x > outsetBounds.xMax {
            _position.x = outsetBounds.xMin
            wrapped = true
        }
        if _position.y < outsetBounds.yMin {
            _position.y = outsetBounds.yMax
            wrapped = true
        }
        else if _position.y > outsetBounds.yMax {
            _position.y = outsetBounds.yMin
            wrapped = true
        }
        return wrapped
    }

    func rotationVelocityAtPosition(_ position: Vector2) -> Vector2 {
        let offset = position - _position
        let offsetNormal = (offset.direction() ?? .zero).turned90(towards: WindingDirection.positiveAngle)
        return offsetNormal * (rotationSpeed.radians * offset.magnitude())
    }

    func circleIntersection(center: Vector2, radius: Double) -> (position: Vector2, normal: Vector2)? {
        let shapeIntersection = _shape.circleIntersection(center: center, radius: radius, asteroidTransform: transform)
        if let (shapePos, shapeNormal) = shapeIntersection {
            return (position: transform.transformPosition(shapePos), normal: transform.transformDirection(shapeNormal))
        }
        return nil
    }

    func handleProjectileCollision(_ projectile: Projectile) -> (impactPoint: Vector2, normal: Vector2)? {
        if _type == .resource || _type == .background {
            return nil
        }

        let lineSegment = (projectile.position, projectile.position + projectile.velocity * 0.03)
        let intersection = _shape.lineSegmentIntersection(lineSegment, asteroidTransform: transform)
        if let enter = intersection {
            let impactPoint = Vector2.lerp(lineSegment.0, lineSegment.1, by: enter)
            let deltaFromCenter = impactPoint - _position
            let projectileDirection = projectile.velocity.direction() ?? .zero
            _rotationSpeed += .radians(Vector2.cross(deltaFromCenter, projectileDirection) * 0.001)
            _velocity += projectileDirection * 0.5
            _timeSinceHit = 0.0
            _health -= projectile.damage
            _hitAxis = projectile.velocity.direction()
            return (impactPoint: impactPoint, normal: deltaFromCenter.direction() ?? .zero)
        }
        return nil
    }

    func destroy() {
        _health = 0.0
    }

    func isDestroyed() -> Bool {
        return _health <= 0.0001
    }

    func splitAlongHitAxis() -> ([Asteroid], [Particle]) {
        var newAsteroids: [Asteroid] = []
        var newParticles: [Particle] = []

        let particleCount = _shape.gridRows
        newParticles.append(contentsOf: Particle.explosion(position: _position, velocity: _velocity, 
            color: _baseColor, particleSize: 24.0, particleCount: particleCount, minDuration: 0.2, maxDuration: 0.4))

        // let splitAxis = _velocity.direction() ?? Vector2(angle: .degrees(Double.random(in: 0.0...360.0)))
        let splitAxis = _hitAxis ?? Vector2(angle: .degrees(Double.random(in: 0.0...360.0)))
        let splitSpeed = max(Double.random(in: 15.0...25.0), _velocity.magnitude() * Double.random(in: 0.5...1.0))
        let splitRotationSpeed = Double.random(in: 15.0...25.0)

        let newShapes = _shape.splitAlong(axisOrigin: .zero, axisDirection: splitAxis.rotatedBy(-_rotation))
        for i in 0..<2 {
            var (shape, shapeOffset) = newShapes[i]

            var resourceOffsets: [Vector2] = []

            let detachedCells = shape.purgeDetachedCells()
            if detachedCells.count > 0 {
                let (compacted, compactedOffset) = shape.compactedShape()
                shape = compacted
                shapeOffset += compactedOffset
                for (cellType, offset) in detachedCells {
                    if cellType == .resource {
                        resourceOffsets.append(offset)
                    }
                }
            }

            let looseResourceOffsets = shape.takeLooseResources()
            if looseResourceOffsets.count > 0 {
                let (compacted, compactedOffset) = shape.compactedShape()
                shape = compacted
                shapeOffset += compactedOffset
                resourceOffsets.append(contentsOf: looseResourceOffsets)
            }

            var shatterShape = false
            if shape.gridRows < 3 || shape.gridCols < 3 {
                shatterShape = true
                resourceOffsets.append(contentsOf: shape.takeCellsOfType(type: .resource))
            }

            if resourceOffsets.count > 0 {
                let resourceShape = AsteroidShape(rows: 1, cols: 1)
                resourceShape.setCellType(row: 0, col: 0, type: .resource)
                for resourceOffset in resourceOffsets {
                    let count = Double.random(in: 0.0...1.0) < Double(PlayerData.shared.upgradeLevel(type: .sometimesMoreOreDrops)) * 0.1 ? 4 : 1
                    for _ in 0..<count {
                        let resourcePosition = _position + (shapeOffset + resourceOffset).rotatedBy(_rotation)
                        let newAsteroid = Asteroid(type: .resource, shape: resourceShape, difficulty: _difficulty)
                        var velocity = _velocity + rotationVelocityAtPosition(resourcePosition)
                        velocity = velocity * 0.5 + Vector2(angle: .degrees(Double.random(in: 0.0...360.0))) * Double.random(in: 15.0...25.0)
                        newAsteroid.initPosition(resourcePosition, rotation: _rotation, baseRotationSpeed: .zero, startRotationSpeed: _rotationSpeed, velocity: velocity)
                        newAsteroids.append(newAsteroid)
                        // _particles.append(contentsOf: Particle.explosion(
                        //     position: resourcePosition, velocity: .zero, minVelocityAngle: .degrees(0.0), maxVelocityAngle: .degrees(360.0),
                        //     color: Color("#FFFF00")!, particleSize: 12.0, particleCount: 1, minDuration: 0.2, maxDuration: 0.3))
                    }
                }
            }

            if shatterShape {
                continue
            }

            let offset = shapeOffset.rotatedBy(_rotation)

            let rotationSpeed = _rotationSpeed * 0.5 + (i == 0 ? 1.0 : -1.0) * .degrees(splitRotationSpeed)

            let velocity = 
                _velocity * 0.5 +
                rotationVelocityAtPosition(_position + offset)
                + splitAxis.rotatedBy(.degrees(i == 0 ? -90.0 : 90.0)) * splitSpeed
            
            let newAsteroid = Asteroid(type: .normal, shape: shape, difficulty: _difficulty)
            newAsteroid.initPosition(_position + offset, rotation: _rotation, baseRotationSpeed: .degrees(Double.random(in: -10.0...10.0)), startRotationSpeed: rotationSpeed, velocity: velocity)
            newAsteroids.append(newAsteroid)
        }
        return (newAsteroids, newParticles)
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
