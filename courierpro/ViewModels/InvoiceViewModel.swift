import Foundation
import SwiftData
import Combine

@MainActor
final class InvoiceViewModel: ObservableObject {
    private let persistenceService: PersistenceService

    @Published var invoices: [Invoice] = []
    @Published var pricingRules: [PricingRule] = []
    @Published var searchText: String = ""
    @Published var selectedStatus: InvoiceStatus?

    init(persistenceService: PersistenceService? = nil) {
        self.persistenceService = persistenceService ?? PersistenceService.shared
    }

    var filteredInvoices: [Invoice] {
        var results = invoices

        if let status = selectedStatus {
            results = results.filter { $0.status == status }
        }

        if !searchText.isEmpty {
            results = results.filter {
                $0.invoiceNumber.localizedCaseInsensitiveContains(searchText) ||
                $0.customer?.name.localizedCaseInsensitiveContains(searchText) == true
            }
        }

        return results
    }

    var totalRevenue: Double {
        invoices.filter { $0.status == .paid }.reduce(0) { $0 + $1.totalAmount }
    }

    var pendingAmount: Double {
        invoices.filter { $0.status == .pending }.reduce(0) { $0 + $1.balanceDue }
    }

    var overdueAmount: Double {
        invoices.filter { $0.status == .overdue }.reduce(0) { $0 + $1.balanceDue }
    }

    func loadInvoices() throws {
        let descriptor = FetchDescriptor<Invoice>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        invoices = try persistenceService.fetch(descriptor)
    }

    func loadPricingRules() throws {
        let descriptor = FetchDescriptor<PricingRule>(sortBy: [SortDescriptor(\.name)])
        pricingRules = try persistenceService.fetch(descriptor)
    }

    func createInvoice(
        customer: Customer,
        parcels: [Parcel],
        taxRate: Double,
        notes: String?,
        dueDate: Date
    ) throws {
        let invoice = Invoice(
            taxRate: taxRate,
            notes: notes,
            dueDate: dueDate,
            customer: customer
        )
        persistenceService.insert(invoice)

        for parcel in parcels {
            let price = calculatePrice(for: parcel)
            let item = InvoiceItem(
                itemDescription: "Delivery: \(parcel.trackingNumber)",
                quantity: 1,
                unitPrice: price,
                parcel: parcel,
                invoice: invoice
            )
            persistenceService.insert(item)
        }

        invoice.recalculateTotals()
        try persistenceService.save()
        try loadInvoices()
    }

    func updateInvoiceStatus(_ invoice: Invoice, status: InvoiceStatus) throws {
        invoice.status = status
        invoice.updatedAt = Date()
        if status == .paid {
            invoice.paidAt = Date()
        }
        try persistenceService.save()
        try loadInvoices()
    }

    func addPayment(to invoice: Invoice, amount: Double, method: PaymentMethod, reference: String?) throws {
        let payment = Payment(
            amount: amount,
            method: method,
            reference: reference,
            invoice: invoice
        )
        persistenceService.insert(payment)

        if invoice.isFullyPaid {
            invoice.status = .paid
            invoice.paidAt = Date()
        }

        try persistenceService.save()
        try loadInvoices()
    }

    func deleteInvoice(_ invoice: Invoice) throws {
        persistenceService.delete(invoice)
        try persistenceService.save()
        try loadInvoices()
    }

    func calculatePrice(for parcel: Parcel) -> Double {
        let weight = parcel.weight
        if let rule = pricingRules.first(where: { $0.isActive && $0.isApplicable(weight: weight) }) {
            return rule.calculatePrice(weight: weight)
        }
        return 10.0
    }

    func createPricingRule(
        name: String,
        pricingType: PricingType,
        basePrice: Double,
        pricePerUnit: Double,
        minimumWeight: Double,
        maximumWeight: Double
    ) throws {
        let rule = PricingRule(
            name: name,
            pricingType: pricingType,
            basePrice: basePrice,
            pricePerUnit: pricePerUnit,
            minimumWeight: minimumWeight,
            maximumWeight: maximumWeight
        )
        persistenceService.insert(rule)
        try persistenceService.save()
        try loadPricingRules()
    }

    func updatePricingRule(
        _ rule: PricingRule,
        name: String,
        pricingType: PricingType,
        basePrice: Double,
        pricePerUnit: Double,
        minimumWeight: Double,
        maximumWeight: Double,
        isActive: Bool
    ) throws {
        rule.name = name
        rule.pricingTypeRaw = pricingType.rawValue
        rule.basePrice = basePrice
        rule.pricePerUnit = pricePerUnit
        rule.minimumWeight = minimumWeight
        rule.maximumWeight = maximumWeight
        rule.isActive = isActive
        rule.updatedAt = Date()
        try persistenceService.save()
        try loadPricingRules()
    }

    func deletePricingRule(_ rule: PricingRule) throws {
        persistenceService.delete(rule)
        try persistenceService.save()
        try loadPricingRules()
    }
}
