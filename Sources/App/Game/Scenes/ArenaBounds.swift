import Foundation
import Engine

class ArenaBounds {
    private let _topMargin: Double
    private let _otherMargins: Double
    private var _bounds: Rect? = nil

    var bounds: Rect { _bounds! }

    init(topMargin: Double, otherMargins: Double) {
        _topMargin = topMargin
        _otherMargins = otherMargins
    }

    func update(_ context: UpdateContext) {
        var bounds = Rect(position: .zero, size: context.viewSize)
        bounds.xMin += _otherMargins
        bounds.yMin += _topMargin
        bounds.xMax -= _otherMargins
        bounds.yMax -= _otherMargins
        _bounds = bounds
    }

    private func renderMargin(_ context: RenderContext, rect: Rect) {
        context.renderer.renderObject(RenderObject.rectangle(rect, color: Color("#000000")!))
    }

    func render(_ context: RenderContext) {
        renderMargin(context, rect: Rect(position: .zero, size: Vector2(context.renderer.renderSize.x, _topMargin)))
        renderMargin(context, rect: Rect(position: Vector2(0.0, bounds.yMax), size: Vector2(context.renderer.renderSize.x, _topMargin)))
        renderMargin(context, rect: Rect(position: .zero, size: Vector2(_otherMargins, context.renderer.renderSize.y)))
        renderMargin(context, rect: Rect(position: Vector2(bounds.xMax, 0.0), size: Vector2(_otherMargins, context.renderer.renderSize.y)))

        let outline = RenderObject(transform: .identity, color: Color("#777777")!, data: .rectangle(width: 0.0, height: 0.0, strokeWidth: 1.0))
        outline.transform.translation = bounds.center
        outline.data = .rectangle(width: bounds.size.x, height: bounds.size.y, strokeWidth: 1.0)
        context.renderer.renderObject(outline)
    }
}
