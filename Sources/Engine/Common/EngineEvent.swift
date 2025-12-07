import Foundation

public enum EngineEvent {
    case resize
    case keyboard(KeyboardEventPayload)
    case mouse(MouseEventPayload)
}
