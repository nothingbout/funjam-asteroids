import Foundation

fileprivate extension Duration {
    static let infinite = Duration(secondsComponent: Int64.max, attosecondsComponent: Int64.max)
}

public struct InputState {
    public enum PressedState {
        case pressedThisFrame
        case held
        case notPressed

        public var isPressed: Bool {
            return self == .pressedThisFrame || self == .held
        }

        public var wasPressedThisFrame: Bool {
            return self == .pressedThisFrame
        }
    }

    private struct KeyboardKeyState {
        var down: Bool
        var changeFrameNumber: Int64
    }

    private struct MouseButtonState {
        var down: Bool
        var changeFrameNumber: Int64
    }

    private var _keyboardKeyState: [KeyboardEventPayload.PhysicalKey: KeyboardKeyState] = [:]
    private var _mouseButtonState: [MouseEventPayload.Button: MouseButtonState] = [:]
    private var _mousePosition: Vector2? = nil
    private var _currentFrameNumber: Int64 = -1

    public var mousePosition: Vector2? { _mousePosition }

    public init() {
    }

    public mutating func startFrame(_ frameTime: FrameTime) {
        _currentFrameNumber = frameTime.frameNumber
    }

    public mutating func update(with event: EngineEvent) {
        switch event {
        case .keyboard(let payload):
            if let key = payload.key {
                switch payload.eventType {
                case .keyDown:
                    if !keyboardKeyPressedState(key).isPressed {
                        _keyboardKeyState[key] = KeyboardKeyState(down: true, changeFrameNumber: _currentFrameNumber)
                    }
                case .keyRepeat:
                    break
                case .keyUp:
                    if keyboardKeyPressedState(key).isPressed {
                        _keyboardKeyState[key] = KeyboardKeyState(down: false, changeFrameNumber: _currentFrameNumber)
                    }
                }
            }
        case .mouse(let payload):
            _mousePosition = payload.position
            switch payload.eventType {
            case .buttonDown(let button):
                if !mouseButtonPressedState(button).isPressed {
                    _mouseButtonState[button] = MouseButtonState(down: true, changeFrameNumber: _currentFrameNumber)
                }
            case .buttonUp(let button):
                if mouseButtonPressedState(button).isPressed {
                    _mouseButtonState[button] = MouseButtonState(down: false, changeFrameNumber: _currentFrameNumber)
                }
            case .move:
                break
            }
        default:
            break
        }
    }

    public func keyboardKeyPressedState(_ key: KeyboardEventPayload.PhysicalKey) -> PressedState {
        if let keyState = _keyboardKeyState[key], keyState.down {
            return keyState.changeFrameNumber == _currentFrameNumber ? .pressedThisFrame : .held
        }
        return .notPressed
    }

    public func mouseButtonPressedState(_ button: MouseEventPayload.Button) -> PressedState {
        let buttonState = _mouseButtonState[button]
        if let buttonState = buttonState, buttonState.down {
            return buttonState.changeFrameNumber == _currentFrameNumber ? .pressedThisFrame : .held
        }
        return .notPressed
    }
}
