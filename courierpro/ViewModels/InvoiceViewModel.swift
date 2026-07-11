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
    @Published var isLoadingInvoices = false
    @Published var isLoadingPricingRules = false
    @Published var errorMessage: String?
    @Published var showError = false

    var isLoading: Bool {
        isLoadingInvoices || isLoadingPricingRules
    }

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
        isLoadingInvoices = true
        defer { isLoadingInvoices = false }
        do {
            let descriptor = FetchDescriptor<Invoice>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
            invoices = try persistenceService.fetch(descriptor)
        } catch {
            errorMessage = "Failed to load invoices"
            showError = true
        }
    }

    func loadPricingRules() {
        isLoadingPricingRules = true
        defer { isLoadingPricingRules = false }
        do {
            let descriptor = FetchDescriptor<PricingRule>(sortBy: [SortDescriptor(\.name)])
            pricingRules = try persistenceService.fetch(descriptor)
        } catch {
            errorMessage = "Failed to load pricing rules"
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
            if pricingRules.isEmpty {
                loadPricingRules()
            }

            let safeTaxRate = taxRate.isFinite ? max(0, min(taxRate, 100)) : 0
            let invoice = Invoice(
                taxRate: safeTaxRate,
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
            errorMessage = "Failed to create invoice"
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
            errorMessage = "Failed to update invoice status"
            showError = true
        }
    }

    func addPayment(to invoice: Invoice, amount: Double, method: PaymentMethod, reference: String?) {
        do {
            guard amount.isFinite, amount > 0 else {
                errorMessage = "Invalid payment amount"
                showError = true
                return
            }

            let cappedAmount = min(amount, invoice.balanceDue)
            let payment = Payment(
                amount: cappedAmount,
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
            errorMessage = "Failed to add payment"
            showError = true
        }
    }

    func deleteInvoice(_ invoice: Invoice) {
        do {
            persistenceService.delete(invoice)
            try persistenceService.save()
            loadInvoices()
        } catch {
            errorMessage = "Failed to delete invoice"
            showError = true
        }
    }

    func calculatePrice(for parcel: Parcel) -> Double {
        let weight = parcel.weight
        var distance: Double = 0
        if let sender = parcel.sender, let receiver = parcel.receiver {
            distance = RouteOptimizer.distance(from: sender.coordinate, to: receiver.coordinate)
        }
        if let rule = pricingRules.first(where: { $0.isActive && $0.isApplicable(weight: weight) }) {
            let price = rule.calculatePrice(weight: weight, distance: distance)
            return price.isFinite ? max(0, price) : 10.0
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
            let safeBasePrice = basePrice.isFinite ? max(0, basePrice) : 0
            let safePricePerUnit = pricePerUnit.isFinite ? max(0, pricePerUnit) : 0
            let safeMinWeight = max(0, minimumWeight)
            let safeMaxWeight = max(safeMinWeight, maximumWeight)

            let rule = PricingRule(
                name: name,
                pricingType: pricingType,
                basePrice: safeBasePrice,
                pricePerUnit: safePricePerUnit,
                minimumWeight: safeMinWeight,
                maximumWeight: safeMaxWeight
            )
            persistenceService.insert(rule)
            try persistenceService.save()
            loadPricingRules()
        } catch {
            errorMessage = "Failed to create pricing rule"
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
            let safeBasePrice = basePrice.isFinite ? max(0, basePrice) : 0
            let safePricePerUnit = pricePerUnit.isFinite ? max(0, pricePerUnit) : 0
            let safeMinWeight = max(0, minimumWeight)
            let safeMaxWeight = max(safeMinWeight, maximumWeight)

            rule.name = name
            rule.pricingTypeRaw = pricingType.rawValue
            rule.basePrice = safeBasePrice
            rule.pricePerUnit = safePricePerUnit
            rule.minimumWeight = safeMinWeight
            rule.maximumWeight = safeMaxWeight
            rule.isActive = isActive
            rule.updatedAt = Date()
            try persistenceService.save()
            loadPricingRules()
        } catch {
            errorMessage = "Failed to update pricing rule"
            showError = true
        }
    }

    func deletePricingRule(_ rule: PricingRule) {
        do {
            persistenceService.delete(rule)
            try persistenceService.save()
            loadPricingRules()
        } catch {
            errorMessage = "Failed to delete pricing rule"
            showError = true
        }
    }
}
