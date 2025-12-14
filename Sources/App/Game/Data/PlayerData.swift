import Foundation
import Engine

class PlayerData: Codable {
    nonisolated(unsafe) static var shared = PlayerData()

    struct PlayerUpgrade: Codable {
        var type: UpgradeType
        var level: Int
    }

    var ore: Int = 0
    var upgrades: [PlayerUpgrade] = []

    init() {
    }

    func clear() {
        ore = 0
        upgrades = []
    }

    func hasAnyData() -> Bool {
        return ore > 0 || !upgrades.isEmpty
    }

    static func load(storage: WebStorage) {
        if let json = storage.load(key: "playerData") {
            if let data = json.data(using: .utf8) {
                if let playerData = try? JSONDecoder().decode(PlayerData.self, from: data) {
                    PlayerData.shared = playerData
                }
                else {
                    print("Failed to decode player data")
                }
            }
        }
        // PlayerData.shared.ore = 10000000
    }
    
    func save(storage: WebStorage) {
        if let json = try? JSONEncoder().encode(self) {
            storage.save(key: "playerData", value: String(data: json, encoding: .utf8)!)
        }
        else {
            print("Failed to encode player data")
        }
    }

    func upgradeLevel(type: UpgradeType) -> Int {
        return upgrades.first(where: { $0.type == type })?.level ?? 1
    }

    func setUpgradeLevel(type: UpgradeType, level: Int) {
        let index = upgrades.firstIndex(where: { $0.type == type })
        if let index = index {
            upgrades[index].level = level
        }
        else {
            upgrades.append(PlayerUpgrade(type: type, level: level))
        }
    }
}
