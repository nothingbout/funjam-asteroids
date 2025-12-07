import Foundation
import Engine

class FPSCounter {
    private var _frameCount: Int64 = 0
    private var _secondsAccumulated: Double = 0.0
    private var _fps: Double? = nil
    private let _labelObject: RenderObject

    init() {
        _labelObject = RenderObject(
            transform: Transform2D(
                translation: Vector2(80.0, 30.0),
                rotation: .degrees(0.0),
                scale: Vector2(1.0, 1.0),
                depth: 0.0,
            ),
            relativePivot: Vector2(1.0, 0.5),
            color: Color("#777777")!,
            data: .text(text: "FPS: ??", fontSize: 12.0)
        )
    }

    func update(_ context: UpdateContext) {
        _secondsAccumulated += context.frameTime.deltaSeconds
        _frameCount += 1
        if _secondsAccumulated >= 0.2 {
            let fps = Double(_frameCount) / _secondsAccumulated
            _secondsAccumulated = 0.0
            _frameCount = 0
            _labelObject.data = .text(text: "FPS: \(Int(round(fps)))", fontSize: 12.0)
        }
        _labelObject.transform.translation = Vector2(context.viewSize.x - 20.0, 30.0)
    }

    func render(_ context: RenderContext) {
        context.renderer.renderObject(_labelObject)
    }
}