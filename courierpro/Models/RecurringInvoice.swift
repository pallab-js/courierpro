import Foundation
import SwiftData

enum RecurrenceFrequency: Int, Codable, CaseIterable, Identifiable {
    case weekly = 0
    case biweekly = 1
    case monthly = 2
    case quarterly = 3
    case yearly = 4

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .weekly: return "Weekly"
        case .biweekly: return "Bi-weekly"
        case .monthly: return "Monthly"
        case .quarterly: return "Quarterly"
        case .yearly: return "Yearly"
        }
    }

    var intervalDays: Int {
        switch self {
        case .weekly: return 7
        case .biweekly: return 14
        case .monthly: return 30
        case .quarterly: return 90
        case .yearly: return 365
        }
    }
}

@Model
final class RecurringInvoice {
    var id: UUID
    var name: String
    var frequencyRaw: Int
    var amount: Double
    var taxRate: Double
    var notes: String?
    var isActive: Bool
    var nextDueDate: Date
    var lastGeneratedDate: Date?
    var createdAt: Date
    var updatedAt: Date

    var customer: Customer?

    var frequency: RecurrenceFrequency {
        get { RecurrenceFrequency(rawValue: frequencyRaw) ?? .monthly }
        set { frequencyRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        name: String,
        frequency: RecurrenceFrequency = .monthly,
        amount: Double = 0,
        taxRate: Double = 0,
        notes: String? = nil,
        isActive: Bool = true,
        nextDueDate: Date = Date(),
        customer: Customer? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.frequencyRaw = frequency.rawValue
        self.amount = amount.isFinite ? max(0, amount) : 0
        self.taxRate = max(0, min(taxRate, 100))
        self.notes = notes
        self.isActive = isActive
        self.nextDueDate = nextDueDate
        self.customer = customer
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    func generateNextInvoice() -> Invoice? {
        guard let customer = customer else { return nil }
        guard amount > 0 else { return nil }

        let invoice = Invoice(
            status: .pending,
            subtotal: amount,
            taxRate: taxRate,
            notes: notes,
            dueDate: nextDueDate,
            customer: customer
        )
        let item = InvoiceItem(
            itemDescription: name.isEmpty ? "Recurring Service Fee" : name,
            quantity: 1,
            unitPrice: amount,
            invoice: invoice
        )
        invoice.items = [item]
        invoice.recalculateTotals()
        return invoice
    }

    func updateNextDueDate() {
        lastGeneratedDate = nextDueDate
        nextDueDate = Calendar.current.date(byAdding: .day, value: frequency.intervalDays, to: nextDueDate) ?? Date()
    }
}
