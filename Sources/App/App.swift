import Foundation
import Engine

enum AppEvent {
}

@main
struct App {
    static func main() {
// #if os(WASI)
        let platform = WebPlatform()
        platform.renderer.renderSize = Vector2(1920.0, 1080.0)
        platform.soundPlayer.volume = 0.5
        var inputState = InputState()

        let fpsCounter = FPSCounter()
        let sceneManager = SceneManager()

        platform.startAnimationUpdates { frameTime in
            inputState.startFrame(frameTime)
            let events = platform.takeEvents()
            for event in events {
                inputState.update(with: event)
                switch event {
                case .resize:
                    // print("resizeEvent: \(platform.renderer.dimensions)")
                    break
                case .keyboard(_):
                    // print("keyboardEvent \(payload)")
                    break
                case .mouse(_):
                    // print("mouseEvent \(payload), positionInRenderer: \(platform.renderer.position(of: payload))")
                    break
                }
            }
 
            let updateContext = UpdateContext(
                frameTime: frameTime, 
                viewSize: platform.renderer.renderSize, 
                inputState: inputState, 
                soundPlayer: platform.soundPlayer,
                storage: platform.storage
            )
            sceneManager.update(updateContext)
            fpsCounter.update(updateContext)

            let renderContext = RenderContext(
                renderer: platform.renderer
            )
            sceneManager.render(renderContext)
            // fpsCounter.render(renderContext)
        }
// #else
// #endif
    }
}
