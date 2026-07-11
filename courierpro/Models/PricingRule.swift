import Foundation
import SwiftData

enum PricingType: Int, Codable, CaseIterable, Identifiable {
    case flatRate = 0
    case perKg = 1
    case perKm = 2

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .flatRate: return "Flat Rate"
        case .perKg: return "Per Kg"
        case .perKm: return "Per Km"
        }
    }
}

@Model
final class PricingRule {
    var id: UUID
    var name: String
    var pricingTypeRaw: Int
    var basePrice: Double
    var pricePerUnit: Double
    var minimumWeight: Double
    var maximumWeight: Double
    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date

    var pricingType: PricingType {
        get { PricingType(rawValue: pricingTypeRaw) ?? .flatRate }
        set { pricingTypeRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        name: String,
        pricingType: PricingType = .flatRate,
        basePrice: Double = 0,
        pricePerUnit: Double = 0,
        minimumWeight: Double = 0,
        maximumWeight: Double = 100,
        isActive: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.pricingTypeRaw = pricingType.rawValue
        self.basePrice = basePrice.isFinite ? max(0, basePrice) : 0
        self.pricePerUnit = pricePerUnit.isFinite ? max(0, pricePerUnit) : 0
        self.minimumWeight = max(0, minimumWeight)
        self.maximumWeight = max(minimumWeight, maximumWeight)
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    func calculatePrice(weight: Double, distance: Double = 0) -> Double {
        let safeWeight = weight.isFinite ? weight : 0
        let safeDistance = distance.isFinite ? distance : 0
        switch pricingType {
        case .flatRate:
            return basePrice
        case .perKg:
            return basePrice + (safeWeight * pricePerUnit)
        case .perKm:
            return basePrice + (safeDistance * pricePerUnit)
        }
    }

    func isApplicable(weight: Double) -> Bool {
        weight >= minimumWeight && weight <= maximumWeight
    }
}
