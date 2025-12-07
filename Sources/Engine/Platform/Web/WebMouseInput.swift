import Foundation
import JavaScriptKit

struct WebMouseInput {
    static func payload(of jsEvent: JSValue) -> MouseEventPayload {
        let eventType: MouseEventPayload.EventType = switch jsEvent.type.string! {
            case "mousedown": .buttonDown(_button(of: jsEvent))
            case "mouseup": .buttonUp(_button(of: jsEvent))
            case "mousemove": .move
            default: fatalError("Unknown event type: \(jsEvent.type.string!)")
        }

        let position = Vector2(jsEvent.clientX.number!, jsEvent.clientY.number!)
        return MouseEventPayload(eventType: eventType, position: position, rendererIndex: 0)
    }

    private static func _button(of jsEvent: JSValue) -> MouseEventPayload.Button {
        let jsButton = jsEvent.button.number!
        if jsButton == 0 { return .primary }
        if jsButton == 1 { return .auxiliary }
        if jsButton == 2 { return .secondary }
        return .additional(Int(jsButton))
    }
}
