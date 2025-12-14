import Foundation
import Engine

class StationScene {
    private let _arenaBounds: ArenaBounds
    private var _navigationBar: NavigationBar = NavigationBar()

    private var _upgradeBoxes: [UpgradeBox] = []

    var onMainMenu: Event<() -> Void> = Event()
    var onStartGame: Event<() -> Void> = Event()

    init() {
        _arenaBounds = ArenaBounds(topMargin: 20.0, otherMargins: 20.0)
        _navigationBar.stationButton.isSelected = true
        _navigationBar.onMainMenu.addListener { [weak self] in
            self?.onMainMenu.invoke { $0() }
        }

        for upgradeType in UpgradeType.allCases {
            _upgradeBoxes.append(UpgradeBox(type: upgradeType))
        }
    }
    
    func update(_ context: UpdateContext) {
        _arenaBounds.update(context)

        _navigationBar.renderPosition = _arenaBounds.bounds.min + Vector2(20.0, 20.0)
        _navigationBar.update(context)

        if context.inputState.keyboardKeyPressedState(.enter).wasPressedThisFrame {
            onStartGame.invoke { $0() }
        }

        var upgradeBoxesPos = Vector2(_arenaBounds.bounds.center.x - _upgradeBoxes[0].renderSize.x * 0.5, 240.0)
        for upgradeBox in _upgradeBoxes {
            upgradeBox.renderPosition = upgradeBoxesPos
            upgradeBoxesPos.y += upgradeBox.renderSize.y + 20.0
            upgradeBox.update(context)
        }
    }

    func render(_ context: RenderContext) {
        _arenaBounds.render(context)
        _navigationBar.render(context)

        do {
            let statBox = GameStatBox()
            statBox.label = "UPGRADES"
            statBox.value = ""
            statBox.renderSize.x = _upgradeBoxes[0].renderSize.x - 160.0 - 10.0;
            statBox.renderPosition = Vector2(
                _upgradeBoxes[0].renderPosition.x, 
                _upgradeBoxes[0].renderPosition.y - statBox.renderSize.y - 20.0
            )
            statBox.render(context)
        }

        do {
            let statBox = GameStatBox()
            statBox.label = "ORE"
            statBox.value = "\(PlayerData.shared.ore)"
            // statBox.renderSize.x = 240.0
            statBox.renderPosition = Vector2(
                _upgradeBoxes[0].renderPosition.x + _upgradeBoxes[0].renderSize.x - statBox.renderSize.x, 
                _upgradeBoxes[0].renderPosition.y - statBox.renderSize.y - 20.0
            )
            statBox.render(context)
        }

        for upgradeBox in _upgradeBoxes {
            upgradeBox.render(context)
        }

        let startTextObject = RenderObject(
            transform: Transform2D(translation: _arenaBounds.bounds.center + Vector2(0.0, 360.0), rotation: .zero, scale: .one), 
            color: Color("#777777")!, 
            data: .text(text: "Press [Enter] to go fly.", fontSize: 24.0)
        )
        context.renderer.renderObject(startTextObject)
    }
}
