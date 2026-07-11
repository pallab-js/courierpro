import Foundation
import SwiftData
import Combine

@MainActor
final class RecurringInvoiceViewModel: ObservableObject {
    private let persistenceService: PersistenceService

    @Published var recurringInvoices: [RecurringInvoice] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false

    init(persistenceService: PersistenceService? = nil) {
        self.persistenceService = persistenceService ?? PersistenceService.shared
    }

    func loadRecurringInvoices() {
        isLoading = true
        defer { isLoading = false }
        do {
            let descriptor = FetchDescriptor<RecurringInvoice>(sortBy: [SortDescriptor(\.nextDueDate)])
            recurringInvoices = try persistenceService.fetch(descriptor)
        } catch {
            errorMessage = "Failed to load recurring invoices"
            showError = true
        }
    }

    func createRecurringInvoice(
        name: String,
        customer: Customer,
        amount: Double,
        taxRate: Double,
        frequency: RecurrenceFrequency,
        notes: String?,
        startDate: Date
    ) {
        do {
            let safeAmount = amount.isFinite ? max(0, amount) : 0
            let safeTaxRate = taxRate.isFinite ? max(0, min(taxRate, 100)) : 0

            let recurringInvoice = RecurringInvoice(
                name: name,
                frequency: frequency,
                amount: safeAmount,
                taxRate: safeTaxRate,
                notes: notes,
                nextDueDate: startDate,
                customer: customer
            )
            persistenceService.insert(recurringInvoice)
            try persistenceService.save()
            loadRecurringInvoices()
        } catch {
            errorMessage = "Failed to create recurring invoice"
            showError = true
        }
    }

    func generateInvoice(from recurring: RecurringInvoice) {
        do {
            guard recurring.amount > 0 else {
                errorMessage = "Amount must be greater than zero"
                showError = true
                return
            }

            if let lastGenerated = recurring.lastGeneratedDate,
               lastGenerated >= recurring.nextDueDate {
                errorMessage = "Invoice already generated for this period"
                showError = true
                return
            }

            guard let invoice = recurring.generateNextInvoice() else {
                errorMessage = "Cannot generate invoice: missing customer or invalid amount"
                showError = true
                return
            }
            persistenceService.insert(invoice)
            recurring.updateNextDueDate()
            try persistenceService.save()
            loadRecurringInvoices()
        } catch {
            errorMessage = "Failed to generate invoice"
            showError = true
        }
    }

    func toggleActive(_ recurring: RecurringInvoice) {
        recurring.isActive.toggle()
        recurring.updatedAt = Date()
        do {
            try persistenceService.save()
            loadRecurringInvoices()
        } catch {
            errorMessage = "Failed to update"
            showError = true
        }
    }

    func deleteRecurringInvoice(_ recurring: RecurringInvoice) {
        do {
            persistenceService.delete(recurring)
            try persistenceService.save()
            loadRecurringInvoices()
        } catch {
            errorMessage = "Failed to delete"
            showError = true
        }
    }
}
