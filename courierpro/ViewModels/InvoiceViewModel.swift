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
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false

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

    func loadInvoices() {
        isLoading = true
        defer { isLoading = false }
        do {
            let descriptor = FetchDescriptor<Invoice>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
            invoices = try persistenceService.fetch(descriptor)
        } catch {
            errorMessage = "Failed to load invoices: \(error.localizedDescription)"
            showError = true
        }
    }

    func loadPricingRules() {
        isLoading = true
        defer { isLoading = false }
        do {
            let descriptor = FetchDescriptor<PricingRule>(sortBy: [SortDescriptor(\.name)])
            pricingRules = try persistenceService.fetch(descriptor)
        } catch {
            errorMessage = "Failed to load pricing rules: \(error.localizedDescription)"
            showError = true
        }
    }

    func createInvoice(
        customer: Customer,
        parcels: [Parcel],
        taxRate: Double,
        notes: String?,
        dueDate: Date
    ) {
        do {
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
            loadInvoices()
        } catch {
            errorMessage = "Failed to create invoice: \(error.localizedDescription)"
            showError = true
        }
    }

    func updateInvoiceStatus(_ invoice: Invoice, status: InvoiceStatus) {
        do {
            invoice.status = status
            invoice.updatedAt = Date()
            if status == .paid {
                invoice.paidAt = Date()
            }
            try persistenceService.save()
            loadInvoices()
        } catch {
            errorMessage = "Failed to update invoice status: \(error.localizedDescription)"
            showError = true
        }
    }

    func addPayment(to invoice: Invoice, amount: Double, method: PaymentMethod, reference: String?) {
        do {
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
            loadInvoices()
        } catch {
            errorMessage = "Failed to add payment: \(error.localizedDescription)"
            showError = true
        }
    }

    func deleteInvoice(_ invoice: Invoice) {
        do {
            persistenceService.delete(invoice)
            try persistenceService.save()
            loadInvoices()
        } catch {
            errorMessage = "Failed to delete invoice: \(error.localizedDescription)"
            showError = true
        }
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
    ) {
        do {
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
            loadPricingRules()
        } catch {
            errorMessage = "Failed to create pricing rule: \(error.localizedDescription)"
            showError = true
        }
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
    ) {
        do {
            rule.name = name
            rule.pricingTypeRaw = pricingType.rawValue
            rule.basePrice = basePrice
            rule.pricePerUnit = pricePerUnit
            rule.minimumWeight = minimumWeight
            rule.maximumWeight = maximumWeight
            rule.isActive = isActive
            rule.updatedAt = Date()
            try persistenceService.save()
            loadPricingRules()
        } catch {
            errorMessage = "Failed to update pricing rule: \(error.localizedDescription)"
            showError = true
        }
    }

    func deletePricingRule(_ rule: PricingRule) {
        do {
            persistenceService.delete(rule)
            try persistenceService.save()
            loadPricingRules()
        } catch {
            errorMessage = "Failed to delete pricing rule: \(error.localizedDescription)"
            showError = true
        }
    }
}
