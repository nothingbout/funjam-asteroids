import Foundation
import Engine

class MainMenuScene {
    private let _arenaBounds: ArenaBounds
    private var _sourceCodeLinkObject: RenderObject? = nil
    private var _navigationBar: NavigationBar = NavigationBar()
    private var _hasAnyPlayerData: Bool = false
    private var _clearDataButton: Button = Button(label: "Clear Data")
    private var _clearingData: Bool = false

    var onStartGame: Event<() -> Void> = Event()
    var onStation: Event<() -> Void> = Event()

    init() {
        _arenaBounds = ArenaBounds(topMargin: 20.0, otherMargins: 20.0)
        _navigationBar.mainMenuButton.isSelected = true
        _navigationBar.onStation.addListener { [weak self] in
            self?.onStation.invoke { $0() }
        }
        _clearDataButton.onClick.addListener { [weak self] in
            self?._clearingData = true
        }
    }
    
    func update(_ context: UpdateContext) {
        _arenaBounds.update(context)

        _hasAnyPlayerData = PlayerData.shared.hasAnyData()

        if _hasAnyPlayerData {
            _clearDataButton.renderPosition = Vector2(
                _arenaBounds.bounds.max.x - _clearDataButton.renderSize.x - 20.0,
                _arenaBounds.bounds.min.y + 20.0
            )
            _clearDataButton.update(context)
        }

        if _clearingData {
            if context.inputState.keyboardKeyPressedState(.y).wasPressedThisFrame {
                _clearingData = false
                PlayerData.shared.clear()
                PlayerData.shared.save(storage: context.storage)
            }
            else if context.inputState.keyboardKeyPressedState(.escape).wasPressedThisFrame {
                _clearingData = false
            }
        }

        if _hasAnyPlayerData {
            _navigationBar.renderPosition = _arenaBounds.bounds.min + Vector2(20.0, 20.0)
            _navigationBar.update(context)
        }

        if context.inputState.keyboardKeyPressedState(.enter).wasPressedThisFrame {
            onStartGame.invoke { $0() }
        }
    }

    func render(_ context: RenderContext) {
        _arenaBounds.render(context)
        if _hasAnyPlayerData {
            _navigationBar.render(context)
        }
        if _hasAnyPlayerData {
            _clearDataButton.render(context)
        }

        let gameTitlePosition = _arenaBounds.bounds.center + Vector2(0.0, -120.0)
        let gameTitleObject = RenderObject(
            transform: Transform2D(translation: gameTitlePosition, rotation: .zero, scale: .one), 
            relativePivot: Vector2(0.5, 1.0),
            color: Color("#777777")!, 
            data: .text(text: """
                 ██████╗ ██████╗ ███████╗ ██████╗ ██╗██████╗ ███████╗
                ██╔═══██╗██╔══██╗██╔════╝██╔═══██╗██║██╔══██╗██╔════╝
                ██║   ██║██████╔╝█████╗  ██║   ██║██║██║  ██║███████╗
                ██║   ██║██╔══██╗██╔══╝  ██║   ██║██║██║  ██║╚════██║
                ╚██████╔╝██║  ██║███████╗╚██████╔╝██║██████╔╝███████║
                 ╚═════╝ ╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═╝╚═════╝ ╚══════╝
            """, fontSize: 24.0)
        )
        context.renderer.renderObject(gameTitleObject)

        // let gameTitleDisclaimerObject = RenderObject(
        //     transform: Transform2D(translation: gameTitlePosition + Vector2(0.0, 8.0), rotation: .zero, scale: .one), 
        //     relativePivot: Vector2(0.5, 0.0),
        //     color: Color("#555555")!, 
        //     data: .text(text: "Disclaimer: AI was used in the creation of this ASTEROIDS title art.", fontSize: 14.0)
        // )
        // context.renderer.renderObject(gameTitleDisclaimerObject)

        let versionTextObject = RenderObject(
            transform: Transform2D(translation: gameTitlePosition + Vector2(400, 4.0), rotation: .zero, scale: .one), 
            relativePivot: Vector2(1.0, 0.0),
            color: Color("#777777")!, 
            data: .text(text: "v0.2", fontSize: 18.0)
        )
        context.renderer.renderObject(versionTextObject)

        let startText = _clearingData ? 
            "Press [Y] to confirm deletion of all player data. Press [Escape] to cancel." : 
            "Maneuver with [Arrow Keys], fire with [Space], press [Enter] to go fly."

        let startTextObject = RenderObject(
            transform: Transform2D(translation: _arenaBounds.bounds.center + Vector2(0.0, 120.0), rotation: .zero, scale: .one), 
            color: Color("#777777")!, 
            data: .text(text: startText, fontSize: 24.0)
        )
        context.renderer.renderObject(startTextObject)

        let sourceAvailablePos = _arenaBounds.bounds.center + Vector2(0.0, 400.0)
        let sourceAvailableTextObject = RenderObject(
            transform: Transform2D(translation: sourceAvailablePos + Vector2(0.0, -16.0), rotation: .zero, scale: .one), 
            color: Color("#777777")!, 
            data: .text(text: "Source available at:", fontSize: 18.0)
        )
        context.renderer.renderObject(sourceAvailableTextObject)

        if _sourceCodeLinkObject == nil {
            let url = "https://github.com/nothingbout/funjam-asteroids"
            _sourceCodeLinkObject = RenderObject(
                transform: Transform2D(translation: sourceAvailablePos + Vector2(0.0, 16.0), rotation: .zero, scale: .one), 
                color: Color("#7777BB")!, 
                data: .link(text: url, url: url, fontSize: 18.0)
            )
        }
        context.renderer.renderObject(_sourceCodeLinkObject!)
    }
}
