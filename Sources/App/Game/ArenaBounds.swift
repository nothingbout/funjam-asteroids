import Foundation
import Engine

class ArenaBounds {
    private let _topMargin: Double
    private let _otherMargins: Double
    private var _bounds: Rect? = nil
    private let _boundsObject = RenderObject(
        transform: .identity,
        color: Color("#777777")!,
        data: .rectangle(width: 0.0, height: 0.0, cornerRadius: nil, strokeWidth: nil)
    )

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

        _boundsObject.transform.translation = bounds.center
        _boundsObject.data = .rectangle(width: bounds.size.x, height: bounds.size.y, cornerRadius: nil, strokeWidth: 1.0)
    }

    func render(_ context: RenderContext) {
        context.renderer.renderObject(_boundsObject)
    }
}
