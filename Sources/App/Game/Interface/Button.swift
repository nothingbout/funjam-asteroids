import Foundation
import Engine

class Button {
    var label: String = ""
    var disabled: Bool = false
    var isHovered: Bool = false
    var isPressed: Bool = false
    var isSelected: Bool = false
    var renderPosition: Vector2 = .zero
    var renderSize = Vector2(160.0, 40.0)
    var primaryColor = Color("#777777")!

    var renderRect: Rect { Rect(position: renderPosition, size: renderSize) }

    var onClick: Event<() -> Void> = Event()

    init(label: String) {
        self.label = label
    }

    func update(_ context: UpdateContext) {
        if let mousePosition = context.inputState.mousePosition {
            isHovered = renderRect.contains(mousePosition)
        }
        else {
            isHovered = false
        }

        isPressed = isHovered && context.inputState.mouseButtonPressedState(.primary).isPressed

        if isHovered && context.inputState.mouseButtonPressedState(.primary).wasPressedThisFrame {
            onClick.invoke { $0() }
        }
    }

    func render(_ context: RenderContext) {
        let rect = renderRect
        let backgroundObject = RenderObject(
            transform: Transform2D(translation: rect.center, rotation: .zero, scale: .one), 
            relativePivot: Vector2(0.5, 0.5),
            color: Color("#000000")!.withAlpha(0.7),
            data: .rectangle(width: rect.size.x, height: rect.size.y)
        )
        context.renderer.renderObject(backgroundObject)

        var color = primaryColor
        if disabled {
            color = Color("#552222")!
        }
        else if isSelected {
            color = Color("#7777FF")!
        }
        else if isPressed {
            color = Color("#BBBBBB")!
        }
        else if isHovered {
        }
        else {
            color = color.withAlpha(0.5)
        }

        let outlineObject = RenderObject(
            transform: Transform2D(translation: rect.center, rotation: .zero, scale: .one), 
            relativePivot: Vector2(0.5, 0.5),
            color: color, 
            data: .rectangle(width: rect.size.x, height: rect.size.y, strokeWidth: 1.0)
        )
        context.renderer.renderObject(outlineObject)

        let labelObject = RenderObject(
            transform: Transform2D(translation: rect.center, rotation: .zero, scale: .one), 
            relativePivot: Vector2(0.5, 0.5),
            color: color,
            data: .text(text: label, fontSize: 24.0)
        )
        context.renderer.renderObject(labelObject)
    }
}
