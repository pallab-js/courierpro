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
            errorMessage = "Failed to load recurring invoices: \(error.localizedDescription)"
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
            let recurringInvoice = RecurringInvoice(
                name: name,
                frequency: frequency,
                amount: amount,
                taxRate: taxRate,
                notes: notes,
                nextDueDate: startDate,
                customer: customer
            )
            persistenceService.insert(recurringInvoice)
            try persistenceService.save()
            loadRecurringInvoices()
        } catch {
            errorMessage = "Failed to create recurring invoice: \(error.localizedDescription)"
            showError = true
        }
    }

    func generateInvoice(from recurring: RecurringInvoice) {
        do {
            let invoice = recurring.generateNextInvoice()
            persistenceService.insert(invoice)
            recurring.updateNextDueDate()
            try persistenceService.save()
            loadRecurringInvoices()
        } catch {
            errorMessage = "Failed to generate invoice: \(error.localizedDescription)"
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
            errorMessage = "Failed to update: \(error.localizedDescription)"
            showError = true
        }
    }

    func deleteRecurringInvoice(_ recurring: RecurringInvoice) {
        do {
            persistenceService.delete(recurring)
            try persistenceService.save()
            loadRecurringInvoices()
        } catch {
            errorMessage = "Failed to delete: \(error.localizedDescription)"
            showError = true
        }
    }
}
