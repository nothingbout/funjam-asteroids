import Foundation

public struct MouseEventPayload: Sendable {
    public let eventType: EventType
    public let position: Vector2
    public let rendererIndex: Int // needed if there are ever multiple renderers

    public enum EventType: Hashable, Sendable {
        case buttonDown(Button)
        case buttonUp(Button)
        case move
    }

    public enum Button: Hashable, Sendable {
        case primary
        case auxiliary
        case secondary
        case additional(Int)
    }
}
