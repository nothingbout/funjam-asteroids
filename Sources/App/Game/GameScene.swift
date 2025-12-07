import Foundation
import Engine

class GameScene {
    private let _arenaBounds: ArenaBounds

    init() {
        _arenaBounds = ArenaBounds(topMargin: 50.0, otherMargins: 20.0)
    }
    
    func update(_ context: UpdateContext) {
        _arenaBounds.update(context)
    }

    func render(_ context: RenderContext) {
        _arenaBounds.render(context)
    }
}
