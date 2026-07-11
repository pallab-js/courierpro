import Foundation
import SwiftData

@Model
final class Driver {
    var id: UUID
    var name: String
    var phone: String
    var licenseNumber: String
    var isAvailable: Bool
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .nullify, inverse: \Parcel.driver)
    var assignedParcels: [Parcel]?

    var isBusy: Bool {
        guard let parcels = assignedParcels else { return false }
        return parcels.contains { $0.status != .delivered && $0.status != .failed }
    }

    init(
        id: UUID = UUID(),
        name: String,
        phone: String = "",
        licenseNumber: String = "",
        isAvailable: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.phone = phone
        self.licenseNumber = licenseNumber
        self.isAvailable = isAvailable
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
