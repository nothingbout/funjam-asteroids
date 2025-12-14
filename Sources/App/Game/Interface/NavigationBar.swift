import Foundation
import Engine

class NavigationBar {
    var mainMenuButton: Button
    var stationButton: Button
    var renderPosition: Vector2 = .zero

    private var _buttons: [Button] = []
    private let _buttonSpacing = 10.0

    var onMainMenu: Event<() -> Void> = Event()
    var onStation: Event<() -> Void> = Event()

    var renderSize: Vector2 { Vector2(
        Double(_buttons.count) * (_buttons[0].renderSize.x + _buttonSpacing) - _buttonSpacing,
        _buttons[0].renderSize.y
    )}

    init() {
        mainMenuButton = Button(label: "Main Menu")
        _buttons.append(mainMenuButton)
        stationButton = Button(label: "Station")
        _buttons.append(stationButton)

        mainMenuButton.onClick.addListener { [weak self] in
            self?.onMainMenu.invoke { $0() }
        }
        stationButton.onClick.addListener { [weak self] in
            self?.onStation.invoke { $0() }
        }
    }

    func update(_ context: UpdateContext) {
        var currentRenderPosition = renderPosition
        for button in _buttons {
            button.renderPosition = currentRenderPosition
            currentRenderPosition.x += button.renderSize.x + _buttonSpacing
            button.update(context)
        }
    }

    func render(_ context: RenderContext) {
        for button in _buttons {
            button.render(context)
        }
    }
}
