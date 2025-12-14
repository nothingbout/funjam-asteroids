import Foundation
import JavaScriptKit

public class WebPlatform {
    private let _window: JSValue
    private let _document: JSValue
    private let _renderer: WebRenderer
    private let _soundPlayer: WebSoundPlayer
    private let _storage: WebStorage

    private var _events: [EngineEvent] = []
    private var _animationFrameListener: AnimationFrameListener? = nil

    public var renderer: WebRenderer { _renderer }
    public var soundPlayer: WebSoundPlayer { _soundPlayer }
    public var storage: WebStorage { _storage }

    public init() {
        _window = JSObject.global.window
        _document = JSObject.global.document
        let renderContainer = _document.getElementById("render-container")
        _renderer = WebRenderer(document: _document, container: renderContainer)
        _soundPlayer = WebSoundPlayer()
        _storage = WebStorage()
        let progressBarContainer = _document.getElementById("progress-bar-container")
        if !progressBarContainer.isNull && !progressBarContainer.isUndefined {
            _ = progressBarContainer.setAttribute("hidden", "")
        }
        _addEventListeners()
    }

    public func takeEvents() -> [EngineEvent] {
        let events = _events
        _events = []
        return events
    }

    public func startAnimationUpdates(callback: @escaping (FrameTime) -> Void) {
        assert(_animationFrameListener == nil)
        _animationFrameListener = AnimationFrameListener(window: _window) { frameTime in
            self._renderer.startFrame(frameTime)
            callback(frameTime)
            self._renderer.endFrame()
        }
    }

    private class AnimationFrameListener {
        private let _window: JSValue
        private let _callback: (FrameTime) -> Void

        private var _frameNumber: Int64 = -1
        private var _startTimestamp: Double = 0
        private var _prevTimestamp: Double = 0

        private var _animationFrameRequestId: JSValue = JSValue.null
        private var _stopped: Bool = false

        init(window: JSValue, callback: @escaping (FrameTime) -> Void) {
            _window = window
            _callback = callback
            _requestAnimationFrame()
        }

        func stop() {
            _stopped = true
            _ = _window.cancelAnimationFrame(_animationFrameRequestId)
        }

        private func _requestAnimationFrame() {
            _animationFrameRequestId = _window.requestAnimationFrame(JSClosure { (args: [JSValue]) in
                let timestamp: Double = args[0].number!
                self._handleAnimationFrame(timestamp: timestamp)
                return .undefined
            })
        }

        private func _handleAnimationFrame(timestamp: Double) {
            if _stopped { return }
            if _frameNumber == -1 {
                _frameNumber = 0
                _startTimestamp = timestamp
                _prevTimestamp = timestamp
            }
            else {
                let frameTime = FrameTime(
                    frameNumber: _frameNumber,
                    timeSinceStartup: Duration.milliseconds(timestamp - _startTimestamp),
                    deltaTime: Duration.milliseconds(timestamp - _prevTimestamp)
                )
                _callback(frameTime)
                _prevTimestamp = timestamp
                _frameNumber += 1
            }
            _requestAnimationFrame()
        }
    }

    private func _addEventListeners() {
        func handleResizeEvent() {
            // let width = _window.innerWidth.number!
            // let height = _window.innerHeight.number!
            // let pixelsPerUnit = _window.devicePixelRatio.number ?? 1.0
            // let event = ResizeEventPayload(dimensions: Vector2(width, height), pixelsPerUnit: pixelsPerUnit)
            // _events.append(.resize(event))
            _events.append(.resize)
        }

        func handleKeyEvent(_ jsEvent: JSValue) {
            let event = WebKeyboardInput.payload(of: jsEvent)
            _events.append(.keyboard(event))
        }

        func handleMouseEvent(_ jsEvent: JSValue) {
            let viewportEvent = WebMouseInput.payload(of: jsEvent)
            guard let position = _renderer.renderPositionOfViewportCoordinate(viewportEvent.position) else {
                return
            }
            let event = MouseEventPayload(
                eventType: viewportEvent.eventType, 
                position: position,
                rendererIndex: 0
            )
            _events.append(.mouse(event))
        }

        // TODO: Consider adding beforeunload listener
        // window.addEventListener("beforeunload", () => cancelAnimationFrame(animationFrameId));

        _ = _window.addEventListener("resize", JSClosure { (args: [JSValue]) in
            handleResizeEvent()
            return .undefined
        }, ["passive": true ])

        _ = _document.addEventListener("keydown", JSClosure { (args: [JSValue]) in
            handleKeyEvent(args[0])
            return .undefined
        })

        _ = _document.addEventListener("keyup", JSClosure { (args: [JSValue]) in
            handleKeyEvent(args[0])
            return .undefined
        })

        _ = _document.addEventListener("mousedown", JSClosure { (args: [JSValue]) in
            handleMouseEvent(args[0])
            return .undefined
        })

        _ = _document.addEventListener("mouseup", JSClosure { (args: [JSValue]) in
            handleMouseEvent(args[0])
            return .undefined
        })

        _ = _document.addEventListener("mousemove", JSClosure { (args: [JSValue]) in
            handleMouseEvent(args[0])
            return .undefined
        })
    }
}
