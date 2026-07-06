import Foundation
import SwiftData

enum PaymentMethod: Int, Codable, CaseIterable, Identifiable {
    case cash = 0
    case creditCard = 1
    case bankTransfer = 2
    case check = 3

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .cash: return "Cash"
        case .creditCard: return "Credit Card"
        case .bankTransfer: return "Bank Transfer"
        case .check: return "Check"
        }
    }

    var systemImage: String {
        switch self {
        case .cash: return "banknote"
        case .creditCard: return "creditcard"
        case .bankTransfer: return "building.columns"
        case .check: return "checkmark.doc"
        }
    }
}

@Model
final class Payment {
    var id: UUID
    var amount: Double
    var methodRaw: Int
    var reference: String?
    var notes: String?
    var paymentDate: Date
    var createdAt: Date

    var invoice: Invoice?

    var method: PaymentMethod {
        get { PaymentMethod(rawValue: methodRaw) ?? .cash }
        set { methodRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        amount: Double,
        method: PaymentMethod = .cash,
        reference: String? = nil,
        notes: String? = nil,
        paymentDate: Date = Date(),
        invoice: Invoice? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.amount = amount
        self.methodRaw = method.rawValue
        self.reference = reference
        self.notes = notes
        self.paymentDate = paymentDate
        self.invoice = invoice
        self.createdAt = createdAt
    }
}
