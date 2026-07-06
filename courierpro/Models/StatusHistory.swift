import Foundation
import SwiftData

@Model
final class StatusHistory {
    var id: UUID
    var statusRaw: Int
    var timestamp: Date
    var notes: String?
    var updatedBy: String?

    var parcel: Parcel?

    var status: DeliveryStatus {
        get { DeliveryStatus(rawValue: statusRaw) ?? .created }
        set { statusRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        status: DeliveryStatus,
        timestamp: Date = Date(),
        notes: String? = nil,
        updatedBy: String? = nil,
        parcel: Parcel? = nil
    ) {
        self.id = id
        self.statusRaw = status.rawValue
        self.timestamp = timestamp
        self.notes = notes
        self.updatedBy = updatedBy
        self.parcel = parcel
    }
}
