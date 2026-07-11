import Foundation
import SwiftData

@Model
final class InvoiceItem {
    var id: UUID
    var itemDescription: String
    var quantity: Int
    var unitPrice: Double
    var totalPrice: Double

    var invoice: Invoice?
    var parcel: Parcel?

    init(
        id: UUID = UUID(),
        itemDescription: String,
        quantity: Int = 1,
        unitPrice: Double = 0,
        parcel: Parcel? = nil,
        invoice: Invoice? = nil
    ) {
        self.id = id
        self.itemDescription = itemDescription
        self.quantity = max(0, quantity)
        self.unitPrice = unitPrice.isFinite ? max(0, unitPrice) : 0
        self.totalPrice = Double(max(0, quantity)) * (unitPrice.isFinite ? max(0, unitPrice) : 0)
        self.parcel = parcel
        self.invoice = invoice
    }
}
