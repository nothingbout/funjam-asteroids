import Foundation
import Engine

class GameStatBox {
    var label: String = ""
    var value: String = ""
    var renderPosition: Vector2 = .zero
    var renderSize = Vector2(160.0, 40.0)
    var valueColor = Color("#777777")!

    init() {
    }

    func render(_ context: RenderContext) {
        let rect = Rect(position: renderPosition, size: renderSize)

        let backgroundObject = RenderObject(
            transform: Transform2D(translation: rect.center, rotation: .zero, scale: .one), 
            relativePivot: Vector2(0.5, 0.5),
            color: Color("#000000")!.withAlpha(0.7),
            data: .rectangle(width: rect.size.x, height: rect.size.y)
        )
        context.renderer.renderObject(backgroundObject)

        let outlineObject = RenderObject(
            transform: Transform2D(translation: rect.center, rotation: .zero, scale: .one), 
            relativePivot: Vector2(0.5, 0.5),
            color: Color("#777777")!.withAlpha(0.5), 
            data: .rectangle(width: rect.size.x, height: rect.size.y, strokeWidth: 1.0)
        )
        context.renderer.renderObject(outlineObject)

        let labelObject = RenderObject(
            transform: Transform2D(translation: Vector2(rect.xMin + 10.0, rect.center.y), rotation: .zero, scale: .one), 
            relativePivot: Vector2(0.0, 0.5),
            color: Color("#777777")!.withAlpha(0.5),
            data: .text(text: label, fontSize: 24.0)
        )
        context.renderer.renderObject(labelObject)

        let valueObject = RenderObject(
            transform: Transform2D(translation: Vector2(rect.xMax - 10.0, rect.center.y), rotation: .zero, scale: .one), 
            relativePivot: Vector2(1.0, 0.5),
            color: valueColor, 
            data: .text(text: value, fontSize: 24.0)
        )
        context.renderer.renderObject(valueObject)
    }
}
