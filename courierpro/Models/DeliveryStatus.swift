import Foundation
import SwiftData

enum DeliveryStatus: Int, Codable, CaseIterable, Identifiable {
    case created = 0
    case pickedUp = 1
    case inTransit = 2
    case outForDelivery = 3
    case delivered = 4
    case failed = 5

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .created: return "Created"
        case .pickedUp: return "Picked Up"
        case .inTransit: return "In Transit"
        case .outForDelivery: return "Out for Delivery"
        case .delivered: return "Delivered"
        case .failed: return "Failed"
        }
    }

    var systemImage: String {
        switch self {
        case .created: return "doc.badge.plus"
        case .pickedUp: return "hand.raised.fingers.spread"
        case .inTransit: return "truck"
        case .outForDelivery: return "truck.box"
        case .delivered: return "checkmark.circle"
        case .failed: return "exclamationmark.triangle"
        }
    }

    var color: String {
        switch self {
        case .created: return "blue"
        case .pickedUp: return "orange"
        case .inTransit: return "purple"
        case .outForDelivery: return "yellow"
        case .delivered: return "green"
        case .failed: return "red"
        }
    }
}
