import Foundation
import Engine

struct UpdateContext {
    let frameTime: FrameTime
    let viewSize: Vector2
    let inputState: InputState
    let soundPlayer: WebSoundPlayer
}

struct RenderContext {
    let renderer: WebRenderer
}
