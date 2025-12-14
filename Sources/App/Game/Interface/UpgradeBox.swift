import Foundation
import Engine

class UpgradeBox {
    var upgradeType: UpgradeType
    var renderPosition: Vector2 = .zero
    let renderSize = Vector2(800.0, 40.0)

    private var _upgradeButton: Button
    private var _tryUpgrade: Bool = false

    // var onUpgrade: Event<() -> Void> = Event()

    init(type: UpgradeType) {
        self.upgradeType = type
        _upgradeButton = Button(label: "Upgrade")
        _upgradeButton.primaryColor = Color("#99FF99")!
        // _upgradeButton.renderSize.x = 240.0
        _upgradeButton.onClick.addListener { [weak self] in
            guard let self else { return }
            self._tryUpgrade = true
        }
    }

    func update(_ context: UpdateContext) {
        if _tryUpgrade {
            _tryUpgrade = false
            let nextLevel = PlayerData.shared.upgradeLevel(type: self.upgradeType) + 1
            let cost = UpgradeData.upgradeCost(self.upgradeType, forLevel: nextLevel)
            if PlayerData.shared.ore >= cost {
                context.soundPlayer.playSound("upgrade", pitchVariance: 0.0)
                PlayerData.shared.ore -= cost
                PlayerData.shared.setUpgradeLevel(type: self.upgradeType, level: nextLevel)
            }
        }

        let cost = UpgradeData.upgradeCost(upgradeType, forLevel: PlayerData.shared.upgradeLevel(type: upgradeType) + 1)
        _upgradeButton.label = "\(cost) ORE"
        _upgradeButton.renderPosition = renderPosition + Vector2(renderSize.x - _upgradeButton.renderSize.x, 0.0)
        _upgradeButton.disabled = PlayerData.shared.ore < cost
        _upgradeButton.update(context)
    }

    func render(_ context: RenderContext) {
        do {
            let rect = Rect(position: renderPosition, size: renderSize + Vector2(-_upgradeButton.renderSize.x - 10.0, 0.0))

            let backgroundObject = RenderObject(
                transform: Transform2D(translation: rect.center, rotation: .zero, scale: .one), 
                relativePivot: Vector2(0.5, 0.5),
                color: Color("#000000")!.withAlpha(0.7),
                data: .rectangle(width: rect.size.x, height: rect.size.y)
            )
            context.renderer.renderObject(backgroundObject)

            let outlineObject = RenderObject(
                transform: Transform2D(translation: rect.center, rotation: .zero, scale: .one), 
                relativePivot: Vector2(0.5, 0.5),
                color: Color("#777777")!.withAlpha(0.5), 
                data: .rectangle(width: rect.size.x, height: rect.size.y, strokeWidth: 1.0)
            )
            context.renderer.renderObject(outlineObject)

            let labelObject = RenderObject(
                transform: Transform2D(translation: Vector2(rect.xMin + 10.0, rect.center.y), rotation: .zero, scale: .one), 
                relativePivot: Vector2(0.0, 0.5),
                color: Color("#777777")!,
                data: .text(text: upgradeType.name, fontSize: 24.0)
            )
            context.renderer.renderObject(labelObject)

            let valueObject = RenderObject(
                transform: Transform2D(translation: Vector2(rect.xMax - 10.0, rect.center.y), rotation: .zero, scale: .one), 
                relativePivot: Vector2(1.0, 0.5),
                color: Color("#7777FF")!, 
                data: .text(text: "lvl \(PlayerData.shared.upgradeLevel(type: upgradeType))", fontSize: 24.0)
            )
            context.renderer.renderObject(valueObject)
        }

        // do {
        //     let rect = Rect(position: renderPosition + Vector2(renderSize.x - 160.0, 0.0), size: Vector2(160.0, 40.0))

        //     let backgroundObject = RenderObject(
        //         transform: Transform2D(translation: rect.center, rotation: .zero, scale: .one), 
        //         relativePivot: Vector2(0.5, 0.5),
        //         color: Color("#000000")!.withAlpha(0.7),
        //         data: .rectangle(width: rect.size.x, height: rect.size.y)
        //     )
        //     context.renderer.renderObject(backgroundObject)

        //     let outlineObject = RenderObject(
        //         transform: Transform2D(translation: rect.center, rotation: .zero, scale: .one), 
        //         relativePivot: Vector2(0.5, 0.5),
        //         color: Color("#777777")!.withAlpha(0.5), 
        //         data: .rectangle(width: rect.size.x, height: rect.size.y, strokeWidth: 1.0)
        //     )
        //     context.renderer.renderObject(outlineObject)

        //     let valueObject = RenderObject(
        //         transform: Transform2D(translation: Vector2(rect.center.x, rect.center.y), rotation: .zero, scale: .one), 
        //         relativePivot: Vector2(0.5, 0.5),
        //         color: Color("#777777")!, 
        //         data: .text(text: "\(UpgradeData.upgradeCost(upgradeType, forLevel: PlayerData.shared.upgradeLevel(type: upgradeType) + 1)) ORE", fontSize: 24.0)
        //     )
        //     context.renderer.renderObject(valueObject)
        // }
        _upgradeButton.render(context)
    }
}
