import Foundation
import JavaScriptKit

public class WebRenderer {
    private let _document: JSValue
    private let _container: JSValue

    private var _frameTime: FrameTime? = nil
    private var _clientRect: Rect? = nil
    private var _renderObjects: [RenderObjectId: WebRenderObject] = [:]
    private var _objectsToRemove: [RenderObjectId] = []

    private var _renderSize: Vector2?
    private var _renderScale: Double = 1.0
    private var _renderOffset: Vector2 = .zero

    private var _leadingBlackBar: RenderObject?
    private var _trailingBlackBar: RenderObject?

    public var backingSize: Vector2 { _clientRect!.size }
    public var renderSize: Vector2 { 
        get { _renderSize ?? backingSize }
        set { _renderSize = newValue }
    }

    init(document: JSValue, container: JSValue) {
        _document = document
        _container = container
    }

    func renderPositionOfViewportCoordinate(_ viewportCoordinate: Vector2) -> Vector2? {
        if let clientRect = _clientRect {
            return (viewportCoordinate - clientRect.position - _renderOffset) / _renderScale
        }
        return nil
    }

    func startFrame(_ frameTime: FrameTime) {
        _frameTime = frameTime

        let domRect = _container.getBoundingClientRect()
        let clientRect = Rect(
            position: Vector2(domRect.left.number!, domRect.top.number!), 
            size: Vector2(domRect.width.number!, domRect.height.number!)
        )
        _clientRect = clientRect
        if let renderSize = _renderSize {
            let clientAspect = clientRect.size.x / clientRect.size.y
            let renderAspect = renderSize.x / renderSize.y
            if abs(clientAspect - renderAspect) < 0.00001 {
                _renderOffset = .zero
                _renderScale = clientRect.size.y / renderSize.y
                _leadingBlackBar = nil
                _trailingBlackBar = nil
            }
            else if clientAspect >= renderAspect {
                _renderOffset = Vector2((clientRect.size.x - clientRect.size.y * renderAspect) * 0.5, 0.0)
                _renderScale = clientRect.size.y / renderSize.y
                let blackBarSize = Vector2(_renderOffset.x / _renderScale, renderSize.y)
                _leadingBlackBar = RenderObject.rectangle(Rect(position: Vector2(-blackBarSize.x, 0.0), size: blackBarSize), color: .black)
                _trailingBlackBar = RenderObject.rectangle(Rect(position: Vector2(renderSize.x, 0.0), size: blackBarSize), color: .black)
            }
            else {
                _renderOffset = Vector2(0.0, (clientRect.size.y - clientRect.size.x / renderAspect) * 0.5)
                _renderScale = clientRect.size.x / renderSize.x
                let blackBarSize = Vector2(renderSize.x, _renderOffset.y / _renderScale)
                _leadingBlackBar = RenderObject.rectangle(Rect(position: Vector2(0.0, -blackBarSize.y), size: blackBarSize), color: .black)
                _trailingBlackBar = RenderObject.rectangle(Rect(position: Vector2(0.0, renderSize.y), size: blackBarSize), color: .black)
            }
        }
    }

    public func renderObject(_ renderObject: RenderObject) {
        if let existing = _renderObjects[renderObject.id] {
            if existing.update(frameTime: _frameTime!, renderObject: renderObject, renderScale: _renderScale, renderOffset: _renderOffset) {
                return
            }
            existing.destroy()
        }

        let new = WebRenderObject(document: _document, container: _container, frameTime: _frameTime!, 
            renderObject: renderObject, renderScale: _renderScale, renderOffset: _renderOffset)
        _renderObjects[renderObject.id] = new
    }

    func endFrame() {
        if let _leadingBlackBar {
            renderObject(_leadingBlackBar)
        }
        if let _trailingBlackBar {
            renderObject(_trailingBlackBar)
        }

        _objectsToRemove.removeAll(keepingCapacity: true)
        for (id, object) in _renderObjects {
            if object.frameTime != _frameTime! {
                _objectsToRemove.append(id)
            }
        }
        for id in _objectsToRemove {
            let object = _renderObjects[id]!
            object.destroy()
            _renderObjects.removeValue(forKey: id)
        }
    }
}
