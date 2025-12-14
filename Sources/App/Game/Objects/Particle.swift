import Foundation
import Engine

class Particle {
    private var _rotation: Angle
    private var _rotationSpeed: Angle
    private var _position: Vector2
    private var _velocity: Vector2
    private var _timeToDestroy: Double

    private let _object: RenderObject

    var isDestroyed: Bool { _timeToDestroy <= 0.0 }

    init(color: Color, particleSize: Double, position: Vector2, velocity: Vector2, timeToDestroy: Double) {
        _rotation = velocity.angle() + .degrees(90.0)
        _rotationSpeed = .degrees(Double.random(in: -10.0...10.0))
        _position = position
        _velocity = velocity
        _timeToDestroy = timeToDestroy
        _object = RenderObject(
            transform: .identity,
            color: color,
            data: .text(text: "#", fontSize: particleSize)
        )
    }

    func update(_ context: UpdateContext) {
        _position += _velocity * context.frameTime.deltaSeconds
        _object.transform.translation = _position
        _object.transform.rotation = _rotation
        _rotation += _rotationSpeed * context.frameTime.deltaSeconds
        _timeToDestroy -= context.frameTime.deltaSeconds
    }

    func render(_ context: RenderContext) {
        context.renderer.renderObject(_object)
    }

    static func explosion(position: Vector2, velocity: Vector2, 
        color: Color, particleSize: Double, particleCount: Int, minDuration: Double, maxDuration: Double,
        velocityAngleRange: (Angle, Angle) = (.degrees(0.0), .degrees(360.0))) -> [Particle] {
        var particles: [Particle] = []
        for _ in 0..<particleCount {
            let direction = Vector2(angle: .degrees(Double.random(in: velocityAngleRange.0.degrees...velocityAngleRange.1.degrees)))
            let speed = Double.random(in: 100.0...200.0)
            let particle = Particle(color: color, particleSize: particleSize, position: position, velocity: velocity + direction * speed, timeToDestroy: Double.random(in: minDuration...maxDuration))
            particles.append(particle)
        }
        return particles
    }
}