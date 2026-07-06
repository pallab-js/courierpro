import Foundation
import SwiftData
import Combine

@MainActor
final class CustomerViewModel: ObservableObject {
    private let persistenceService: PersistenceService

    @Published var customers: [Customer] = []
    @Published var searchText: String = ""

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

    func loadCustomers() throws {
        let descriptor = FetchDescriptor<Customer>(sortBy: [SortDescriptor(\.name)])
        customers = try persistenceService.fetch(descriptor)
    }

    func createCustomer(
        name: String,
        email: String,
        phone: String,
        address: String,
        city: String,
        postalCode: String
    ) throws {
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
        try loadCustomers()
    }

    func updateCustomer(
        _ customer: Customer,
        name: String,
        email: String,
        phone: String,
        address: String,
        city: String,
        postalCode: String
    ) throws {
        customer.name = name
        customer.email = email
        customer.phone = phone
        customer.address = address
        customer.city = city
        customer.postalCode = postalCode
        customer.updatedAt = Date()
        try persistenceService.save()
        try loadCustomers()
    }

    func deleteCustomer(_ customer: Customer) throws {
        persistenceService.delete(customer)
        try persistenceService.save()
        try loadCustomers()
    }
}
