import Foundation
import Engine

struct UpdateContext {
    let frameTime: FrameTime
    let viewSize: Vector2
    let inputState: InputState
    let soundPlayer: WebSoundPlayer
    let storage: WebStorage
}

struct RenderContext {
    let renderer: WebRenderer
}

struct Event<Signature> {
    private var _listeners: [Signature] = []

    mutating func addListener(_ listener: Signature) {
        _listeners.append(listener)
    }

    func invoke(_ caller: (Signature) -> Void) {
        for listener in _listeners {
            caller(listener)
        }
    }
}
