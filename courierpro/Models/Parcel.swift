import Foundation
import SwiftData

@Model
final class Parcel {
    var id: UUID
    var trackingNumber: String
    var statusRaw: Int
    var weight: Double
    var dimensions: String
    var notes: String?
    var createdAt: Date
    var updatedAt: Date
    var deliveredAt: Date?

    var sender: Customer?
    var receiver: Customer?
    var driver: Driver?

    @Relationship(deleteRule: .cascade, inverse: \StatusHistory.parcel)
    var statusHistory: [StatusHistory]?

    var status: DeliveryStatus {
        get { DeliveryStatus(rawValue: statusRaw) ?? .created }
        set { statusRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        trackingNumber: String = "",
        status: DeliveryStatus = .created,
        weight: Double = 0,
        dimensions: String = "",
        notes: String? = nil,
        sender: Customer? = nil,
        receiver: Customer? = nil,
        driver: Driver? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        deliveredAt: Date? = nil
    ) {
        self.id = id
        self.trackingNumber = trackingNumber.isEmpty ? Self.generateTrackingNumber() : trackingNumber
        self.statusRaw = status.rawValue
        self.weight = weight.isFinite ? max(0, weight) : 0
        self.dimensions = dimensions
        self.notes = notes
        self.sender = sender
        self.receiver = receiver
        self.driver = driver
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deliveredAt = deliveredAt
    }

    static func generateTrackingNumber() -> String {
        let prefix = "CP"
        let timestamp = String(Int(Date().timeIntervalSince1970).description.suffix(6))
        let random = String(format: "%04d", Int.random(in: 0...9999))
        return "\(prefix)-\(timestamp)-\(random)"
    }

    var statusDisplayName: String {
        status.displayName
    }

    var senderName: String {
        sender?.name ?? "Unknown"
    }

    var receiverName: String {
        receiver?.name ?? "Unknown"
    }

    var driverName: String {
        driver?.name ?? "Unassigned"
    }
}
