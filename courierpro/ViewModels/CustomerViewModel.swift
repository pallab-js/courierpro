import Foundation
import SwiftData
import Combine

@MainActor
final class CustomerViewModel: ObservableObject {
    private let persistenceService: PersistenceService

    @Published var customers: [Customer] = []
    @Published var searchText: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false

    init(persistenceService: PersistenceService? = nil) {
        self.persistenceService = persistenceService ?? PersistenceService.shared
    }

    var filteredCustomers: [Customer] {
        if searchText.isEmpty {
            return customers
        }
        return customers.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.email.localizedCaseInsensitiveContains(searchText) ||
            $0.city.localizedCaseInsensitiveContains(searchText)
        }
    }

    func loadCustomers() {
        isLoading = true
        defer { isLoading = false }
        do {
            let descriptor = FetchDescriptor<Customer>(sortBy: [SortDescriptor(\.name)])
            customers = try persistenceService.fetch(descriptor)
        } catch {
            errorMessage = "Failed to load customers: \(error.localizedDescription)"
            showError = true
        }
    }

    func createCustomer(
        name: String,
        email: String,
        phone: String,
        address: String,
        city: String,
        postalCode: String
    ) {
        do {
            let customer = Customer(
                name: name,
                email: email,
                phone: phone,
                address: address,
                city: city,
                postalCode: postalCode
            )
            persistenceService.insert(customer)
            try persistenceService.save()
            loadCustomers()
        } catch {
            errorMessage = "Failed to create customer: \(error.localizedDescription)"
            showError = true
        }
    }

    func updateCustomer(
        _ customer: Customer,
        name: String,
        email: String,
        phone: String,
        address: String,
        city: String,
        postalCode: String
    ) {
        do {
            customer.name = name
            customer.email = email
            customer.phone = phone
            customer.address = address
            customer.city = city
            customer.postalCode = postalCode
            customer.updatedAt = Date()
            try persistenceService.save()
            loadCustomers()
        } catch {
            errorMessage = "Failed to update customer: \(error.localizedDescription)"
            showError = true
        }
    }

    func deleteCustomer(_ customer: Customer) {
        do {
            persistenceService.delete(customer)
            try persistenceService.save()
            loadCustomers()
        } catch {
            errorMessage = "Failed to delete customer: \(error.localizedDescription)"
            showError = true
        }
    }
}
