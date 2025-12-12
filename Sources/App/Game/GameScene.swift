import Foundation
import Engine

class GameScene {
    class GameState {
        var gameStarted: Bool = false
        var spaceReleasedAfterStart: Bool = false
        var gameOver: Bool = false
        var timeSinceGameStarted: Double = 0.0
        var timeSinceGameOver: Double = 0.0
        var rocketShip: RocketShip = RocketShip()
        var projectiles: [Projectile] = []
        var asteroids: [Asteroid] = []
        var particles: [Particle] = []
        var timeToAsteroidSpawn: Double = 0.0
        var spawnedAsteroidCount: Int = 0
    }

    private let _arenaBounds: ArenaBounds
    private var _gameState: GameState = GameState()
    private var _score: Int = 0
    private var _sourceCodeLinkObject: RenderObject? = nil

    init() {
        _arenaBounds = ArenaBounds(topMargin: 50.0, otherMargins: 20.0)
        randomizeTimeToAsteroidSpawn()
    }
    
    func update(_ context: UpdateContext) {
        _arenaBounds.update(context)

        if !_gameState.gameStarted {
            if !context.inputState.keyboardKeyPressedState(.enter).isPressed {
                return
            }

            _gameState.gameStarted = true
            _score = 0
            _gameState.rocketShip.initPosition(_arenaBounds.bounds.center, rotation: .zero)

            for _ in 0..<5 {
                _ = spawnAsteroid(gridRows: Int.random(in: 5...8), difficulty: randomAsteroidDifficulty())
            }
        }

        _gameState.timeSinceGameStarted += context.frameTime.deltaSeconds

        if _gameState.gameOver {
            _gameState.timeSinceGameOver += context.frameTime.deltaSeconds
            if _gameState.timeSinceGameOver >= 1.0 {
                _gameState = GameState()
                return
            }
        }
        else {
            _gameState.rocketShip.update(context)
            if _gameState.rocketShip.handleBoundsCollision(_arenaBounds.bounds) && !_gameState.rocketShip.isDestroyed {
                context.soundPlayer.playSound("hit4", volume: 0.5)
            }

            for asteroid in _gameState.asteroids {
                if _gameState.rocketShip.handleAsteroidCollision(asteroid) && !_gameState.rocketShip.isDestroyed {
                    context.soundPlayer.playSound("hit4", volume: 0.5)
                }
            }

            if context.inputState.keyboardKeyPressedState(.space).isPressed {
                if _gameState.spaceReleasedAfterStart {
                    if let projectile = _gameState.rocketShip.tryFireProjectile() {
                        context.soundPlayer.playSound("shoot2")
                        _gameState.projectiles.append(projectile)
                    }
                }
            }
            else {
                _gameState.spaceReleasedAfterStart = true
            }
        }

        for projectile in _gameState.projectiles {
            projectile.update(context)
        }

        _gameState.timeToAsteroidSpawn -= context.frameTime.deltaSeconds
        if _gameState.timeToAsteroidSpawn <= 0.0 {
            randomizeTimeToAsteroidSpawn()
            _ = spawnAsteroid(gridRows: Int.random(in: 5...8), difficulty: randomAsteroidDifficulty())
        }

        for asteroid in _gameState.asteroids {
            for projectile in _gameState.projectiles {
                if let (impactPoint, impactNormal) = asteroid.handleProjectileCollision(projectile) {
                    projectile.destroyAfter(0.03)
                    let minAngle = impactNormal.angle() - .degrees(45.0)
                    let maxAngle = impactNormal.angle() + .degrees(45.0)
                    _gameState.particles.append(contentsOf: Particle.explosion(
                        position: impactPoint, velocity: .zero, minVelocityAngle: minAngle, maxVelocityAngle: maxAngle,
                        color: Color.lerp(Color("#FF3333")!, asteroid.baseColor, by: 0.5), particleSize: 12.0, particleCount: 3, minDuration: 0.2, maxDuration: 0.3))
                    break
                }
            }
            if asteroid.isDestroyed() {
                context.soundPlayer.playSound("hit106")
                _score += Int(ceil(Math.lerp(1.0, 10.0, by: asteroid.difficulty))) * asteroid.shape.gridRows

                let particleCount = asteroid.shape.gridRows
                _gameState.particles.append(contentsOf: Particle.explosion(
                    position: asteroid.position, velocity: asteroid.velocity, minVelocityAngle: .degrees(0.0), maxVelocityAngle: .degrees(360.0),
                    color: asteroid.baseColor, particleSize: 24.0, particleCount: particleCount, minDuration: 0.2, maxDuration: 0.4))

                let newGridRows = asteroid.shape.gridRows - Int.random(in: 1...2)
                if newGridRows >= 3 {
                    for i in 0..<2 {
                        let newAsteroid = spawnAsteroid(gridRows: newGridRows, difficulty: asteroid.difficulty)
                        newAsteroid.velocity = asteroid.velocity + asteroid.velocity.rotatedBy(.degrees(i == 0 ? -90.0 : 90.0))
                        newAsteroid.position = asteroid.position + newAsteroid.velocity * 0.1
                    }
                }
            }
            asteroid.wrapAround(_arenaBounds.bounds)
            asteroid.update(context)
        }

        for particle in _gameState.particles {
            particle.update(context)
        }
        _gameState.projectiles.removeAll { $0.isOutsideOfBounds(_arenaBounds.bounds) || $0.isDestroyed }
        _gameState.asteroids.removeAll { $0.isDestroyed() }
        _gameState.particles.removeAll { $0.isDestroyed }

        if !_gameState.gameOver && _gameState.rocketShip.isDestroyed {
            context.soundPlayer.playSound("death", volume: 0.5)
            _gameState.particles.append(contentsOf: Particle.explosion(
                position: _gameState.rocketShip.position, velocity: _gameState.rocketShip.velocity, 
                minVelocityAngle: .degrees(0.0), maxVelocityAngle: .degrees(360.0),
                color: Color("#FF7777")!, particleSize: 24.0, particleCount: 10, minDuration: 0.2, maxDuration: 0.4))
            _gameState.gameOver = true
        }
    }

    func spawnAsteroid(gridRows: Int, difficulty: Double) -> Asteroid {
        let shape = AsteroidShape(gridCols: gridRows * 3 / 2, gridRows: gridRows)
        shape.generateRandomShape()

        let rotation: Angle = .degrees(Double.random(in: 0.0...360.0))
        let rotationSpeed: Angle = .degrees(Double.random(in: -10.0...10.0))

        let position = Vector2(Double.random(in: 0.0..._arenaBounds.bounds.size.x), -shape.containingRadius)

        var direction = Vector2(angle: .degrees(Double.random(in: 45.0...135.0)))
        if _gameState.spawnedAsteroidCount % 2 == 0 {
            direction.y *= -1.0
        }
        let velocity = direction * Double.random(in: 20.0...50.0) * Math.lerp(1.0, 5.0, by: _gameState.timeSinceGameStarted / 120.0)
        
        let asteroid = Asteroid(shape: shape, difficulty: difficulty)
        asteroid.initPosition(position, rotation: rotation, rotationSpeed: rotationSpeed, velocity: velocity)
        _gameState.asteroids.append(asteroid)
        _gameState.spawnedAsteroidCount += 1
        return asteroid
    }   

    func randomizeTimeToAsteroidSpawn() {
        _gameState.timeToAsteroidSpawn = Double.random(in: 3.0...10.0)
    }

    func randomAsteroidDifficulty() -> Double {
        let minDifficulty = Math.lerp(0.0, 0.5, by: _gameState.timeSinceGameStarted / 120.0)
        let maxDifficulty = Math.lerp(0.0, 1.0, by: _gameState.timeSinceGameStarted / 60.0)
        var difficulty = Double.random(in: minDifficulty...maxDifficulty)
        difficulty = round(difficulty * 10.0) / 10.0
        return difficulty
    }

    func render(_ context: RenderContext) {
        if _gameState.gameStarted && !_gameState.gameOver {
            _gameState.rocketShip.render(context)
        }
        for projectile in _gameState.projectiles {
            projectile.render(context)
        }
        for asteroid in _gameState.asteroids {
            asteroid.render(context)
        }
        for particle in _gameState.particles {
            particle.render(context)
        }
        _arenaBounds.render(context)

        if _gameState.gameStarted && !_gameState.gameOver {
            let healthCount = max(0, ceil(_gameState.rocketShip.health / 10.0))
            let healthBarText = String(repeating: "#", count: Int(healthCount))
            let healthBar = RenderObject(
                transform: Transform2D(translation: Vector2(_arenaBounds.bounds.xMin, 20.0), rotation: .zero, scale: .one), 
                relativePivot: Vector2(0.0, 0.5),
                color: Color.lerp(Color("#FF7777")!, Color("#777777")!, by: _gameState.rocketShip.timeSinceHit / 0.2), 
                data: .text(text: "Health: \(healthBarText)", fontSize: 24.0)
            )
            context.renderer.renderObject(healthBar)
        }

        let scoreText = RenderObject(
            transform: Transform2D(translation: Vector2(_arenaBounds.bounds.xMax, 20.0), rotation: .zero, scale: .one), 
            relativePivot: Vector2(1.0, 0.5),
            color: Color("#777777")!, 
            data: .text(text: "Score: \(_score)", fontSize: 24.0)
        )
        context.renderer.renderObject(scoreText)

        if !_gameState.gameStarted {
            let gameTitlePosition = _arenaBounds.bounds.center + Vector2(0.0, -120.0)
            let gameTitleObject = RenderObject(
                transform: Transform2D(translation: gameTitlePosition, rotation: .zero, scale: .one), 
                relativePivot: Vector2(0.5, 1.0),
                color: Color("#777777")!, 
                data: .text(text: """
                █████╗ ███████╗████████╗███████╗██████╗  ██████╗  ██████╗ ██████╗ ██╗██████╗ ███████╗
                ██╔══██╗██╔════╝╚══██╔══╝██╔════╝██╔══██╗██╔═══██╗██╔════╝██╔═══██╗██║██╔══██╗██╔════╝
                ███████║█████╗     ██║   █████╗  ██████╔╝██║   ██║██║     ██║   ██║██║██║  ██║█████╗  
                ██╔══██║██╔══╝     ██║   ██╔══╝  ██╔══██╗██║   ██║██║     ██║   ██║██║██║  ██║██╔══╝  
                ██║  ██║███████╗   ██║   ███████╗██║  ██║╚██████╔╝╚██████╗╚██████╔╝██║██████╔╝███████╗
                ╚═╝  ╚═╝╚══════╝   ╚═╝   ╚══════╝╚═╝  ╚═╝ ╚═════╝  ╚═════╝ ╚═════╝ ╚═╝╚═════╝ ╚══════╝
                """, fontSize: 24.0)
            )
            context.renderer.renderObject(gameTitleObject)

            let gameTitleDisclaimerObject = RenderObject(
                transform: Transform2D(translation: gameTitlePosition + Vector2(0.0, 12.0), rotation: .zero, scale: .one), 
                relativePivot: Vector2(0.5, 0.0),
                color: Color("#555555")!, 
                data: .text(text: "Disclaimer: AI was used in the creation of this title art.", fontSize: 8.0)
            )
            context.renderer.renderObject(gameTitleDisclaimerObject)

            let versionTextObject = RenderObject(
                transform: Transform2D(translation: gameTitlePosition + Vector2(604, 0.0), rotation: .zero, scale: .one), 
                relativePivot: Vector2(1.0, 0.0),
                color: Color("#777777")!, 
                data: .text(text: "v0.1", fontSize: 18.0)
            )
            context.renderer.renderObject(versionTextObject)

            let startTextObject = RenderObject(
                transform: Transform2D(translation: _arenaBounds.bounds.center + Vector2(0.0, 120.0), rotation: .zero, scale: .one), 
                color: Color("#777777")!, 
                data: .text(text: "Move with [Arrow Keys], fire with [Space], press [Enter] to start.", fontSize: 24.0)
            )
            context.renderer.renderObject(startTextObject)

            let sourceAvailablePos = _arenaBounds.bounds.center + Vector2(0.0, 400.0)
            let sourceAvailableTextObject = RenderObject(
                transform: Transform2D(translation: sourceAvailablePos + Vector2(0.0, -16.0), rotation: .zero, scale: .one), 
                color: Color("#777777")!, 
                data: .text(text: "Source available at:", fontSize: 18.0)
            )
            context.renderer.renderObject(sourceAvailableTextObject)

            if _sourceCodeLinkObject == nil {
                let url = "https://github.com/nothingbout/funjam-asteroids"
                _sourceCodeLinkObject = RenderObject(
                    transform: Transform2D(translation: sourceAvailablePos + Vector2(0.0, 16.0), rotation: .zero, scale: .one), 
                    color: Color("#7777BB")!, 
                    data: .link(text: url, url: url, fontSize: 18.0)
                )
            }
            context.renderer.renderObject(_sourceCodeLinkObject!)
        }
    }
}
