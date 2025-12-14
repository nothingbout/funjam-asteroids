import Foundation
import Engine

class GameScene {
    private let _arenaBounds: ArenaBounds
    private var _gameStarted: Bool = false
    private var _timeSinceGameStarted: Double = 0.0
    private var _shipDestroyed: Bool = false
    private var _timeSinceShipDestroyed: Double = 0.0
    private var _rocketShip: RocketShip = RocketShip()
    private var _projectiles: [Projectile] = []
    private var _asteroids: [Asteroid] = []
    private var _particles: [Particle] = []
    private var _timeToAsteroidSpawn: Double = 0.0
    private var _spawnedAsteroidCount: Int = 0

    private var _plusResourceAsteroidsCount: Int = 0
    private var _timeSincePlusResources: Double = 0.0

    var onGameOver: Event<() -> Void> = Event()

    init() {
        _arenaBounds = ArenaBounds(topMargin: 20.0, otherMargins: 20.0)
    }
    
    func update(_ context: UpdateContext) {
        _arenaBounds.update(context)

        if !_gameStarted {
            _gameStarted = true

            _rocketShip.initPosition(_arenaBounds.bounds.center, rotation: .zero)

            for rows in 3...12 {
                _ = spawnAsteroid(gridRows: rows, difficulty: randomAsteroidDifficulty(), type: .background, outsideOfBounds: false)
            }

            for _ in 0..<10 {
                _ = spawnAsteroid(gridRows: Int.random(in: 5...8), difficulty: randomAsteroidDifficulty(), type: .normal, outsideOfBounds: false)
            }
            randomizeTimeToAsteroidSpawn()
        }

        _timeSinceGameStarted += context.frameTime.deltaSeconds

        if context.inputState.keyboardKeyPressedState(.escape).isPressed {
            onGameOver.invoke { $0() }
            return
        }

        if _shipDestroyed {
            _timeSinceShipDestroyed += context.frameTime.deltaSeconds
            if _timeSinceShipDestroyed >= 1.0 {
                onGameOver.invoke { $0() }
                return
            }
        }
        else {
            _rocketShip.update(context, arenaBounds: _arenaBounds.bounds)
            if _rocketShip.handleBoundsCollision(_arenaBounds.bounds) && !_rocketShip.isDestroyed {
                context.soundPlayer.playSound("hit4", volume: 0.5)
            }

            for asteroid in _asteroids {
                asteroid.updateAttraction(context, targetPosition: _rocketShip.position, targetVelocity: _rocketShip.velocity, targetRadius: _rocketShip.shipSize * 0.5, 
                    attractionDistance: 100.0, positionAttractionForce: 100.0, velocityAttractionForce: 0.0)

                if _rocketShip.handleAsteroidCollision(asteroid) && !_rocketShip.isDestroyed {
                    if asteroid.type == .resource {
                        var plusResourcesCount = 1
                        if asteroid.difficulty > 0.3 {
                            plusResourcesCount *= 10
                        }
                        if asteroid.difficulty > 0.8 {
                            plusResourcesCount *= 10
                        }
                        PlayerData.shared.ore += plusResourcesCount
                        context.soundPlayer.playSound("pop402323", volume: 0.5, pitch: 1.0 + Double(_plusResourceAsteroidsCount) / 20.0, pitchVariance: 0.0)

                        _plusResourceAsteroidsCount += 1
                        _timeSincePlusResources = 0.0

                        let effectPosition = Vector2.lerp(_rocketShip.position, asteroid.position, by: 0.5)
                        _particles.append(contentsOf: Particle.explosion(position: effectPosition, velocity: _rocketShip.velocity * 0.5,
                            color: asteroid.baseColor, particleSize: 16.0, particleCount: 6, minDuration: 0.1, maxDuration: 0.2))
                        asteroid.destroy()
                    }
                    else {
                        context.soundPlayer.playSound("hit4", volume: 0.5)
                    }
                }
            }

            if context.inputState.keyboardKeyPressedState(.space).isPressed {
                if let projectile = _rocketShip.tryFireProjectile() {
                    context.soundPlayer.playSound("shoot2")
                    _projectiles.append(projectile)
                }
            }
        }

        if _plusResourceAsteroidsCount > 0 {
            _timeSincePlusResources += context.frameTime.deltaSeconds
            if _timeSincePlusResources >= 1.5 {
                _plusResourceAsteroidsCount = 0
                _timeSincePlusResources = 0.0
            }
        }

        for projectile in _projectiles {
            projectile.update(context)
        }

        _timeToAsteroidSpawn -= context.frameTime.deltaSeconds
        if _timeToAsteroidSpawn <= 0.0 {
            randomizeTimeToAsteroidSpawn()
            _ = spawnAsteroid(gridRows: Int.random(in: 5...8), difficulty: randomAsteroidDifficulty(), type: .normal, outsideOfBounds: true)
        }

        for asteroid in _asteroids {
            if asteroid.type != .resource && asteroid.type != .background {
                for otherAsteroid in _asteroids {
                    otherAsteroid.updateAttraction(context, targetPosition: asteroid.position, targetVelocity: asteroid.velocity, targetRadius: asteroid.shape.containingRadius * asteroid.transform.scale.x, 
                        attractionDistance: 10.0, positionAttractionForce: 50.0, velocityAttractionForce: 2.0)
                }
            }

            for projectile in _projectiles {
                if let (impactPoint, impactNormal) = asteroid.handleProjectileCollision(projectile) {
                    projectile.destroyAfter(0.03)
                    let minAngle = impactNormal.angle() - .degrees(45.0)
                    let maxAngle = impactNormal.angle() + .degrees(45.0)
                    _particles.append(contentsOf: Particle.explosion(position: impactPoint, velocity: .zero, 
                        color: Color.lerp(Color("#FF3333")!, asteroid.baseColor, by: 0.5), particleSize: 12.0, particleCount: 3, 
                        minDuration: 0.2, maxDuration: 0.3, velocityAngleRange: (minAngle, maxAngle)))
                    break
                }
            }
            if asteroid.isDestroyed() {
                if asteroid.type == .resource {
                }
                else {
                    context.soundPlayer.playSound("hit106")
                    // _score += Int(ceil(Math.lerp(1.0, 10.0, by: asteroid.difficulty))) * asteroid.shape.gridRows
                    let (newAsteroids, newParticles) = asteroid.splitAlongHitAxis()
                    _asteroids.append(contentsOf: newAsteroids)
                    _particles.append(contentsOf: newParticles)
                }
            }
            if asteroid.wrapAround(_arenaBounds.bounds) {
                if asteroid.type == .resource {
                    asteroid.destroy()
                }
            }
            asteroid.update(context)
        }

        for particle in _particles {
            particle.update(context)
        }
        _projectiles.removeAll { $0.isOutsideOfBounds(_arenaBounds.bounds) || $0.isDestroyed }
        _asteroids.removeAll { $0.isDestroyed() }
        _particles.removeAll { $0.isDestroyed }

        if !_shipDestroyed && _rocketShip.isDestroyed {
            context.soundPlayer.playSound("death", volume: 0.5)
            _particles.append(contentsOf: Particle.explosion(position: _rocketShip.position, velocity: _rocketShip.velocity, 
                color: Color("#FF7777")!, particleSize: 24.0, particleCount: 10, minDuration: 0.2, maxDuration: 0.4))
            _shipDestroyed = true
        }
    }

    func spawnAsteroid(gridRows: Int, difficulty: Double, type: Asteroid.AsteroidType, outsideOfBounds: Bool) -> Asteroid {
        let resourceChance = type == .background ? 0.0 : 0.2 + 0.2 * Double(PlayerData.shared.upgradeLevel(type: .moreOreOnAsteroids))
        let shape = AsteroidShape.randomShape(rows: gridRows * 3 / 2, cols: gridRows, resourceChance: resourceChance)

        let rotation: Angle = .degrees(Double.random(in: 0.0...360.0))
        var rotationSpeed: Angle = .degrees(Double.random(in: -10.0...10.0))

        var position: Vector2 = .zero
        if outsideOfBounds {
            position = Vector2(Double.random(in: 0.0..._arenaBounds.bounds.size.x), -shape.containingRadius)
        }
        else {
            while true {
                position = Vector2(
                    Double.random(in: _arenaBounds.bounds.xMin..._arenaBounds.bounds.xMax), 
                    Double.random(in: _arenaBounds.bounds.yMin..._arenaBounds.bounds.yMax)
                )
                if type == .background {
                    break
                }
                if (position - _rocketShip.position).magnitude() > shape.containingRadius + 100 {
                    break
                }
            }
        }

        var direction = Vector2(angle: .degrees(Double.random(in: 45.0...135.0)))
        if _spawnedAsteroidCount % 2 == 0 {
            direction.y *= -1.0
        }
        var velocity = direction * Double.random(in: 40.0...90.0)
        velocity *= 1.0 + Double.random(in: 0.0...Double(PlayerData.shared.upgradeLevel(type: .dangerLevel) - 1) * 0.5)
        
        if type == .background {
            velocity *= 0.25
            rotationSpeed *= 0.5
        }
        
        let asteroid = Asteroid(type: type, shape: shape, difficulty: difficulty)
        asteroid.initPosition(position, rotation: rotation, baseRotationSpeed: rotationSpeed, startRotationSpeed: rotationSpeed, velocity: velocity)
        _asteroids.append(asteroid)
        _spawnedAsteroidCount += 1
        return asteroid
    }   

    func randomizeTimeToAsteroidSpawn() {
        _timeToAsteroidSpawn = 10.0 / Double(PlayerData.shared.upgradeLevel(type: .dangerLevel))
    }

    func randomAsteroidDifficulty() -> Double {
        // let minDifficulty = Math.lerp(0.0, 0.5, by: _timeSinceGameStarted / 120.0)
        // let maxDifficulty = Math.lerp(0.0, 1.0, by: _timeSinceGameStarted / 60.0)
        // var difficulty = Double.random(in: minDifficulty...maxDifficulty)
        // difficulty = round(difficulty * 10.0) / 10.0
        // return difficulty

        let level = PlayerData.shared.upgradeLevel(type: .moreValuableAsteroids)
        if level == 1 {
            return 0.0
        }
        if level >= 3 &&  Double.random(in: 0.0...1.0) < 0.03 * Double(level) {
            return 1.0
        }
        if Double.random(in: 0.0...1.0) < 0.1 * Double(level) {
            return 0.5
        }
        return 0.0
    }

    func renderStat(_ context: RenderContext, label: String, value: String, valueColor: Color? = nil, renderPosition: inout Vector2) {
        let statBox = GameStatBox()
        statBox.label = label
        statBox.value = value
        statBox.renderPosition = renderPosition
        if let valueColor {
            statBox.valueColor = valueColor
        }
        statBox.render(context)
        renderPosition.y += statBox.renderSize.y + 10.0
    }

    func render(_ context: RenderContext) {
        for asteroid in _asteroids {
            asteroid.render(context)
        }
        if !_shipDestroyed {
            _rocketShip.render(context)
        }
        for projectile in _projectiles {
            projectile.render(context)
        }
        for particle in _particles {
            particle.render(context)
        }
        _arenaBounds.render(context)

        var statsRenderPosition = _arenaBounds.bounds.min + Vector2(20.0, 20.0)
        renderStat(context, label: "HULL", value: "\(Int(ceil(_rocketShip.health)))", renderPosition: &statsRenderPosition)
        let fuelColor = Color.lerp(Color("#777777")!, Color("#FF7777")!, by: Math.inverseLerp(50.0, 0.0, from: _rocketShip.fuel))
        renderStat(context, label: "FUEL", value: "\(Int(floor(_rocketShip.fuel)))", valueColor: fuelColor, renderPosition: &statsRenderPosition)
        // renderStat(context, label: "POWER", value: "\(Int(floor(_rocketShip.energy)))", renderPosition: &statsRenderPosition)
        renderStat(context, label: "ORE", value: "\(PlayerData.shared.ore)", renderPosition: &statsRenderPosition)

        if _rocketShip.fuel <= 0.0 {
            let fuelTextObject = RenderObject(
                transform: Transform2D(translation: _arenaBounds.bounds.center + Vector2(0.0, 200.0), rotation: .zero, scale: .one), 
                color: Color("#777777")!, 
                data: .text(text: "You are out of fuel. Press [Escape] to return to the station.", fontSize: 24.0)
            )
            context.renderer.renderObject(fuelTextObject)
        }
    }
}
