import Foundation
import Engine

class RocketShip {
    private var _shipSize = 36.0
    private var _rotation: Angle = .zero
    private var _rotationSpeed: Angle = .zero
    private var _position: Vector2 = .zero
    private var _velocity: Vector2 = .zero
    private var _isThrusting: Bool = false
    private var _rotateThrustAmount: Double = 0.0
    private var _timeSinceHit: Double = Double.infinity
    private var _health: Double = 10.0

    private var _energy: Double = 100.0
    private var _energyRechargeRate: Double = 10.0
    private let _energyPerShot: Double = 0.0
    private var _timeBetweenShots: Double = 0.1

    private var _fuel: Double = 100.0
    private var _thrustFuelConsumptionRate: Double = 10.0
    private var _rotateFuelConsumptionRate: Double = 2.0

    private var _timeSinceFiredProjectile: Double = Double.infinity

    private let _bodyObject: RenderObject
    private var _thrustObjects: [RenderObject] = []

    var shipSize: Double { _shipSize }
    var health: Double { _health }
    var energy: Double { _energy }
    var fuel: Double { _fuel }
    var isDestroyed: Bool { _health <= 0.0001 }
    var timeSinceHit: Double { _timeSinceHit }
    var position: Vector2 { _position }
    var velocity: Vector2 { _velocity }

    init() {
        _bodyObject = RenderObject(
            transform: .identity,
            color: Color("#777777")!,
            data: .text(text: "A", fontSize: _shipSize)
        )
        _thrustObjects.append(RenderObject(
            transform: .identity,
            color: Color("#FFFF00")!,
            data: .text(text: "V", fontSize: _shipSize * 0.3)
        ))
        _thrustObjects.append(RenderObject(
            transform: .identity,
            color: Color("#FFFF00")!,
            data: .text(text: "V", fontSize: _shipSize * 0.5)
        ))
        _thrustObjects.append(RenderObject(
            transform: .identity,
            color: Color("#FF7700")!,
            data: .text(text: "V", fontSize: _shipSize * 0.7)
        ))
        _health *= Double(PlayerData.shared.upgradeLevel(type: .hullStrength))
        _fuel *= Double(PlayerData.shared.upgradeLevel(type: .fuelCapacity))
    }

    func initPosition(_ position: Vector2, rotation: Angle) {
        _position = position
        _rotation = .degrees(-90.0)
        _velocity = .zero
    }

    var forwardsDirection: Vector2 { Vector2(angle: _rotation) }

    func update(_ context: UpdateContext, arenaBounds: Rect) {
        let deltaTime = context.frameTime.deltaSeconds
        var inputRotateDirection = 0.0
        if context.inputState.keyboardKeyPressedState(.arrowLeft).isPressed {
            inputRotateDirection = -1.0
        }
        else if context.inputState.keyboardKeyPressedState(.arrowRight).isPressed {
            inputRotateDirection = 1.0
        }

        var inputThrustAmount = 0.0
        if context.inputState.keyboardKeyPressedState(.arrowUp).isPressed {
            inputThrustAmount = 1.0
        }
        
        if _fuel <= 0.0 {
            inputRotateDirection = 0.0
            inputThrustAmount = 0.0
        }

        _rotateThrustAmount = inputRotateDirection
        let targetRotationSpeed = Double(inputRotateDirection) * .degrees(180.0)
        let rotationSpeedChangeSpeed: Angle = .degrees(2000.0)
        _rotationSpeed = _rotationSpeed.moveTowardsAbsolute(targetRotationSpeed, maxDelta: rotationSpeedChangeSpeed * deltaTime)
        _rotation += _rotationSpeed * deltaTime

        _isThrusting = inputThrustAmount > 0.0
        let thrustAmount = inputThrustAmount * 200.0
        let acceleration = forwardsDirection * thrustAmount

        _velocity += acceleration * deltaTime
        if _fuel > 0.0 {
            _velocity *= max(0, (1.0 - deltaTime * 0.2))
        }

        _position += _velocity * deltaTime

        _timeSinceFiredProjectile += deltaTime
        _timeSinceHit += deltaTime

        _energy = Math.clamp(_energy + _energyRechargeRate * deltaTime, min: 0.0, max: 100.0)
        let fuelConsumptionRate = _thrustFuelConsumptionRate * inputThrustAmount + _rotateFuelConsumptionRate * abs(_rotateThrustAmount)
        _fuel = max(_fuel - fuelConsumptionRate * deltaTime, 0.0)

        _bodyObject.color = Color.lerp(Color("#FF7777")!, Color("#777777")!, by: _timeSinceHit / 0.1)

        _bodyObject.transform.translation = _position
        _bodyObject.transform.rotation = _rotation + .degrees(90.0)

        if _isThrusting {
            for (index, thrustObject) in _thrustObjects.enumerated() {
                let offset = 0.5 + Double(index) * 0.075
                thrustObject.transform.translation = _position - forwardsDirection * (_shipSize * offset)
                thrustObject.transform.rotation = _bodyObject.transform.rotation
            }
        }
    }

    func tryFireProjectile() -> Projectile? {
        if _timeSinceFiredProjectile < _timeBetweenShots {
            return nil
        }
        if _energy < _energyPerShot {
            return nil
        }
        _energy -= _energyPerShot
        _timeSinceFiredProjectile = 0.0
        let projectileVelocity = forwardsDirection * 1000.0
        let damage = 1.0 * Double(PlayerData.shared.upgradeLevel(type: .laserDamage))
        return Projectile(position: _position, velocity: projectileVelocity, damage: damage)
    }

    func handleBoundsCollision(_ bounds: Rect) -> Bool {
        let insetBounds = bounds.outset(by: -_shipSize * 0.5)
        if _position.x < insetBounds.xMin {
            applyHit(direction: Vector2(1.0, 0.0))
            return true
        }
        else if _position.x > insetBounds.xMax {
            applyHit(direction: Vector2(-1.0, 0.0))
            return true
        }
        else if _position.y < insetBounds.yMin {
            applyHit(direction: Vector2(0.0, 1.0))
            return true
        }
        else if _position.y > insetBounds.yMax {
            applyHit(direction: Vector2(0.0, -1.0))
            return true
        }
        return false
    }

    func handleAsteroidCollision(_ asteroid: Asteroid) -> Bool {
        if asteroid.type == .background {
            return false
        }
        let intersection = asteroid.shape.circleIntersection(center: _position, radius: _shipSize * 0.5, asteroidTransform: asteroid.transform)
        if let (_, normal) = intersection {
            if asteroid.type != .resource {
                applyHit(direction: normal)
            }
            return true
        }
        return false
    }

    func applyHit(direction: Vector2) {
        _health -= 10.0
        if !isDestroyed {
            _velocity += direction * (200.0 - Vector2.dot(direction, _velocity))
        }
        _timeSinceHit = 0.0
    }

    func render(_ context: RenderContext) {
        context.renderer.renderObject(_bodyObject)
        if _isThrusting {
            for thrustObject in _thrustObjects {
                context.renderer.renderObject(thrustObject)
            }
        }

        // if _rotateThrustAmount != 0.0 {
        //     let rightDirection = forwardsDirection.turned90(towards: .positiveAngle)
        //     let direction = _rotateThrustAmount < 0.0 ? -1.0 : 1.0

        //     let obj1 = RenderObject(
        //         transform: .identity,
        //         color: Color("#FFAA00")!,
        //         data: .text(text: "v", fontSize: _shipSize * 0.3)
        //     )

        //     obj1.transform.translation = _position - rightDirection * (_shipSize * 0.2 * direction) + forwardsDirection * (_shipSize * 0.2)
        //     obj1.transform.rotation = _rotation + .degrees(90.0) + .degrees(90.0) * direction
        //     context.renderer.renderObject(obj1)

        //     let obj2 = RenderObject(
        //         transform: .identity,
        //         color: Color("#FFAA00")!,
        //         data: .text(text: "v", fontSize: _shipSize * 0.3)
        //     )

        //     obj2.transform.translation = _position + rightDirection * (_shipSize * 0.3 * direction) - forwardsDirection * (_shipSize * 0.2)
        //     obj2.transform.rotation = _rotation + .degrees(90.0) - .degrees(90.0) * direction
        //     context.renderer.renderObject(obj2)
        // }
    }
}
