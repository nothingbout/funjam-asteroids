import Foundation
import JavaScriptKit

private extension RenderData {
    func canBeUpdatedTo(_ other: RenderData) -> Bool {
        switch (self, other) {
        case (.text, .text):
            return true
        case (.rectangle(_, _, cornerRadius: let cornerRadius1, strokeWidth: let strokeWidth1), 
              .rectangle(_, _, cornerRadius: let cornerRadius2, strokeWidth: let strokeWidth2)):
            if (cornerRadius1 != nil) != (cornerRadius2 != nil) {
                return false
            }
            if (strokeWidth1 != nil) != (strokeWidth2 != nil) {
                return false
            }
            return true
        default:
            return false
        }
    }
}

class WebRenderObject {
    private let _element: JSValue
    private var _frameTime: FrameTime
    private var _transform: Transform2D
    private var _relativePivot: Vector2
    private var _color: Color
    private var _data: RenderData
    private var _renderScale: Double
    private var _renderOffset: Vector2

    public var frameTime: FrameTime { _frameTime }

    init(document: JSValue, container: JSValue, frameTime: FrameTime, renderObject: RenderObject, renderScale: Double, renderOffset: Vector2) {
        _element = document.createElement("div")
        _element.style.position = "absolute"
        _element.style.boxSizing = "border-box"
        _frameTime = frameTime
        _transform = renderObject.transform
        _relativePivot = renderObject.relativePivot
        _color = renderObject.color
        _data = renderObject.data
        _renderScale = renderScale
        _renderOffset = renderOffset
        updateTransform(renderObject.transform, relativePivot: renderObject.relativePivot)
        updateColor(renderObject.color)
        updateData(renderObject.data)
        _ = container.appendChild(_element)
    }

    func destroy() {
        _ = _element.remove()
    }

    func update(frameTime: FrameTime, renderObject: RenderObject, renderScale: Double, renderOffset: Vector2) -> Bool {
        if _data != renderObject.data {
            if !_data.canBeUpdatedTo(renderObject.data) {
                return false
            }
            updateData(renderObject.data)
        }
        var renderScaleOffsetChanged = false
        if renderScale != _renderScale || renderOffset != _renderOffset {
            _renderScale = renderScale
            _renderOffset = renderOffset
            renderScaleOffsetChanged = true
        }
        if _transform != renderObject.transform || _relativePivot != renderObject.relativePivot || renderScaleOffsetChanged {
            updateTransform(renderObject.transform, relativePivot: renderObject.relativePivot)
        }
        if _color != renderObject.color {
            updateColor(renderObject.color)
        }
        _frameTime = frameTime
        return true
    }

    func updateTransform(_ transform: Transform2D, relativePivot: Vector2) {
        _transform = transform
        let trans = transform.translation * _renderScale + _renderOffset
        let angle = transform.rotation
        let scale = transform.scale * _renderScale
        let pivotPercent = relativePivot * 100.0
        var transformString = "translate(-\(pivotPercent.x)%, -\(pivotPercent.y)%) translate3d(\(trans.x)px, \(trans.y)px, \(-transform.depth)px)"
        if angle != .zero {
            transformString += " rotate(\(angle.degrees)deg)"
        }
        if scale != .one {
            transformString += " scale(\(scale.x), \(scale.y))"
        }
        _element.style.transform = transformString.jsValue
        _element.style.transformOrigin = "\(pivotPercent.x)% \(pivotPercent.y)%".jsValue
    }

    func updateColor(_ color: Color) {
        _color = color
        switch _data {
        case .text:
            _element.style.color = color.toHexString().jsValue
        case .rectangle(_, _, _, strokeWidth: let strokeWidth):
            if strokeWidth != nil {
                _element.style.borderStyle = "solid".jsValue
                _element.style.borderColor = color.toHexString().jsValue
            }
            else {
                _element.style.backgroundColor = color.toHexString().jsValue
            }
        }
    }
    
    func updateData(_ data: RenderData) {
        _data = data
        switch data {
        case .text(let text, let fontSize):
            _element.textContent = text.jsValue
            _element.style.fontSize = "\(fontSize)px".jsValue
        case .rectangle(let width, let height, let cornerRadius, let strokeWidth):
            _element.style.width = "\(width)px".jsValue
            _element.style.height = "\(height)px".jsValue
            if let cornerRadius = cornerRadius {
                _element.style.borderRadius = "\(cornerRadius)px".jsValue
            }
            if let strokeWidth = strokeWidth {
                _element.style.borderWidth = "\(strokeWidth)px".jsValue
            }
        }
    }
}
