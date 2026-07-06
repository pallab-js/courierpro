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
        self.quantity = quantity
        self.unitPrice = unitPrice
        self.totalPrice = Double(quantity) * unitPrice
        self.parcel = parcel
        self.invoice = invoice
    }
}
