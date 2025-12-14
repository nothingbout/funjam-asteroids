import Foundation
import Engine

public enum UpgradeType: CaseIterable, Codable {
    case laserDamage
    case hullStrength
    case fuelCapacity
    case moreOreOnAsteroids
    case moreValuableAsteroids
    case sometimesMoreOreDrops
    case dangerLevel

    var name: String {
        switch self {
        case .laserDamage: return "Laser Damage"
        case .hullStrength: return "Hull Strength"
        case .fuelCapacity: return "Fuel Capacity"
        case .moreOreOnAsteroids: return "More Ore on Asteroids"
        case .sometimesMoreOreDrops: return "Sometimes More Ore Drops"
        case .moreValuableAsteroids: return "More Valuable Asteroids"
        case .dangerLevel: return "Danger Level"
        }
    }
}

public class UpgradeData {
    static func baseUpgradeCost(_ type: UpgradeType) -> Int {
        switch type {
        case .laserDamage: return 10
        case .hullStrength: return 10
        case .fuelCapacity: return 5
        case .moreOreOnAsteroids: return 5
        case .sometimesMoreOreDrops: return 10
        case .moreValuableAsteroids: return 20
        case .dangerLevel: return 100
        }
    }

    public static func upgradeCost(_ type: UpgradeType, forLevel: Int) -> Int {
        let cost = baseUpgradeCost(type) * Int(round(pow(1.75, Double(forLevel - 2))))
        return cost
    }
}
