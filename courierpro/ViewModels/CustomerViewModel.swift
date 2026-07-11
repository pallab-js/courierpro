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
            errorMessage = "Failed to load customers"
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
            let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedName.isEmpty else {
                errorMessage = "Customer name is required"
                showError = true
                return
            }

            let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if !trimmedEmail.isEmpty {
                let allCustomers = try? persistenceService.fetch(FetchDescriptor<Customer>())
                if let matches = allCustomers?.filter({ $0.email.lowercased() == trimmedEmail }), !matches.isEmpty {
                    errorMessage = "A customer with this email already exists"
                    showError = true
                    return
                }
            }

            let customer = Customer(
                name: trimmedName,
                email: trimmedEmail,
                phone: phone.trimmingCharacters(in: .whitespacesAndNewlines),
                address: address.trimmingCharacters(in: .whitespacesAndNewlines),
                city: city.trimmingCharacters(in: .whitespacesAndNewlines),
                postalCode: postalCode.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            persistenceService.insert(customer)
            try persistenceService.save()
            loadCustomers()
        } catch {
            errorMessage = "Failed to create customer"
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
            let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if !trimmedEmail.isEmpty {
                let allCustomers = try? persistenceService.fetch(FetchDescriptor<Customer>())
                if let matches = allCustomers?.filter({ $0.email.lowercased() == trimmedEmail && $0.id != customer.id }), !matches.isEmpty {
                    errorMessage = "A customer with this email already exists"
                    showError = true
                    return
                }
            }

            customer.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
            customer.email = trimmedEmail
            customer.phone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
            customer.address = address.trimmingCharacters(in: .whitespacesAndNewlines)
            customer.city = city.trimmingCharacters(in: .whitespacesAndNewlines)
            customer.postalCode = postalCode.trimmingCharacters(in: .whitespacesAndNewlines)
            customer.updatedAt = Date()
            try persistenceService.save()
            loadCustomers()
        } catch {
            errorMessage = "Failed to update customer"
            showError = true
        }
    }

    func deleteCustomer(_ customer: Customer) {
        do {
            let allParcels = try? persistenceService.fetch(FetchDescriptor<Parcel>())
            let linkedParcels = allParcels?.filter { parcel in
                parcel.sender?.id == customer.id || parcel.receiver?.id == customer.id
            }
            if let parcels = linkedParcels, !parcels.isEmpty {
                errorMessage = "Cannot delete customer with linked parcels"
                showError = true
                return
            }

            persistenceService.delete(customer)
            try persistenceService.save()
            loadCustomers()
        } catch {
            errorMessage = "Failed to delete customer"
            showError = true
        }
    }
}
