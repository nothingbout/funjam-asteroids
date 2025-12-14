import Foundation
import Engine

class SceneManager {
    private var _initialized: Bool = false
    private var _mainMenuScene: MainMenuScene
    private var _stationScene: StationScene? = nil
    private var _gameScene: GameScene? = nil
    private var _gotoMainMenuScene: Bool = false
    private var _gotoStationScene: Bool = false
    private var _gotoGameScene: Bool = false

    init() {
        _mainMenuScene = MainMenuScene()
        _mainMenuScene.onStartGame.addListener { [weak self] in
            self?._gotoGameScene = true
        }
        _mainMenuScene.onStation.addListener { [weak self] in
            self?._gotoStationScene = true
        }
    }
    
    func update(_ context: UpdateContext) {
        if !_initialized {
            _initialized = true
            PlayerData.load(storage: context.storage)
        }

        if _gotoMainMenuScene {
            _gotoMainMenuScene = false
            PlayerData.shared.save(storage: context.storage)
            _gameScene = nil
            _stationScene = nil
            _mainMenuScene.update(context)
        }

        if _gotoStationScene {
            _gotoStationScene = false
            PlayerData.shared.save(storage: context.storage)
            _gameScene = nil
            _stationScene = StationScene()
            _stationScene?.onStartGame.addListener { [weak self] in
                self?._gotoGameScene = true
            }
            _stationScene?.onMainMenu.addListener { [weak self] in
                self?._gotoMainMenuScene = true
            }
        }

        if _gotoGameScene {
            _gotoGameScene = false
            PlayerData.shared.save(storage: context.storage)
            _stationScene = nil
            _gameScene = GameScene()
            _gameScene?.onGameOver.addListener { [weak self] in
                self?._gotoStationScene = true
            }
        }

        if let stationScene = _stationScene {
            stationScene.update(context)
        }
        else if let gameScene = _gameScene {
            gameScene.update(context)
        }
        else {
            _mainMenuScene.update(context)
        }
    }

    func render(_ context: RenderContext) {
        if let gameScene = _gameScene {
            gameScene.render(context)
        }
        else if let stationScene = _stationScene {
            stationScene.render(context)
        }
        else {
            _mainMenuScene.render(context)
        }
    }
}
