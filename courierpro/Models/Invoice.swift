import Foundation
import SwiftData
import SwiftUI
import CryptoKit

enum InvoiceStatus: Int, Codable, CaseIterable, Identifiable {
    case draft = 0
    case pending = 1
    case paid = 2
    case overdue = 3
    case cancelled = 4

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .draft: return "Draft"
        case .pending: return "Pending"
        case .paid: return "Paid"
        case .overdue: return "Overdue"
        case .cancelled: return "Cancelled"
        }
    }

    var systemImage: String {
        switch self {
        case .draft: return "doc.text"
        case .pending: return "clock"
        case .paid: return "checkmark.circle.fill"
        case .overdue: return "exclamationmark.circle"
        case .cancelled: return "xmark.circle"
        }
    }

    var color: Color {
        switch self {
        case .draft: return .gray
        case .pending: return .orange
        case .paid: return .green
        case .overdue: return .red
        case .cancelled: return .gray
        }
    }
}

@Model
final class Invoice {
    var id: UUID
    var invoiceNumber: String
    var statusRaw: Int
    var subtotal: Double
    var taxRate: Double
    var taxAmount: Double
    var totalAmount: Double
    var notes: String?
    var dueDate: Date
    var createdAt: Date
    var updatedAt: Date
    var paidAt: Date?

    var customer: Customer?
    @Relationship(deleteRule: .cascade, inverse: \InvoiceItem.invoice)
    var items: [InvoiceItem]?
    @Relationship(deleteRule: .cascade, inverse: \Payment.invoice)
    var payments: [Payment]?

    var status: InvoiceStatus {
        get { InvoiceStatus(rawValue: statusRaw) ?? .draft }
        set { statusRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        invoiceNumber: String = "",
        status: InvoiceStatus = .draft,
        subtotal: Double = 0,
        taxRate: Double = 0,
        taxAmount: Double = 0,
        totalAmount: Double = 0,
        notes: String? = nil,
        dueDate: Date = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date(),
        customer: Customer? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.invoiceNumber = invoiceNumber.isEmpty ? Self.generateInvoiceNumber() : invoiceNumber
        self.statusRaw = status.rawValue
        self.subtotal = subtotal
        self.taxRate = max(0, min(taxRate, 100))
        self.taxAmount = taxAmount.isFinite ? max(0, taxAmount) : 0
        self.totalAmount = totalAmount.isFinite ? max(0, totalAmount) : 0
        self.notes = notes
        self.dueDate = dueDate
        self.customer = customer
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    static func generateInvoiceNumber() -> String {
        let prefix = "INV"
        let randomBytes = UnsafeMutableRawPointer.allocate(byteCount: 4, alignment: 1)
        defer { randomBytes.deallocate() }
        _ = SecRandomCopyBytes(kSecRandomDefault, 4, randomBytes)
        let randomInt = UInt32(bitPattern: Int32(bigEndian: randomBytes.load(as: Int32.self)))
        let random = String(format: "%08X", randomInt)
        return "\(prefix)-\(random)"
    }

    func recalculateTotals() {
        let safeSubtotal = items?.reduce(0) { $0 + $1.totalPrice } ?? 0
        subtotal = safeSubtotal
        taxAmount = safeSubtotal * taxRate / 100
        totalAmount = safeSubtotal + taxAmount
    }

    var totalPaid: Double {
        payments?.reduce(0) { $0 + $1.amount } ?? 0
    }

    var balanceDue: Double {
        totalAmount - totalPaid
    }

    var isFullyPaid: Bool {
        balanceDue <= 0
    }
}
