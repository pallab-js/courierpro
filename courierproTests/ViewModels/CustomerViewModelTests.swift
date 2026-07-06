import XCTest
@testable import courierpro

@MainActor
final class CustomerViewModelTests: XCTestCase {
    private var viewModel: CustomerViewModel!
    private var testPersistenceService: PersistenceService!

    override func setUp() {
        super.setUp()
        testPersistenceService = PersistenceService.inMemory
        viewModel = CustomerViewModel(persistenceService: testPersistenceService)
    }

    override func tearDown() {
        viewModel = nil
        testPersistenceService = nil
        super.tearDown()
    }

    func testLoadCustomersEmpty() throws {
        try viewModel.loadCustomers()
        XCTAssertTrue(viewModel.customers.isEmpty)
    }

    func testCreateCustomer() throws {
        try viewModel.createCustomer(
            name: "Acme Corp",
            email: "info@acme.com",
            phone: "555-0101",
            address: "123 Business St",
            city: "San Francisco",
            postalCode: "94102"
        )

        XCTAssertEqual(viewModel.customers.count, 1)
        XCTAssertEqual(viewModel.customers.first?.name, "Acme Corp")
        XCTAssertEqual(viewModel.customers.first?.email, "info@acme.com")
    }

    func testUpdateCustomer() throws {
        try viewModel.createCustomer(
            name: "Acme Corp",
            email: "info@acme.com",
            phone: "555-0101",
            address: "123 Business St",
            city: "San Francisco",
            postalCode: "94102"
        )

        let customer = viewModel.customers.first!
        try viewModel.updateCustomer(
            customer,
            name: "Acme Corporation",
            email: "updated@acme.com",
            phone: "555-0199",
            address: "456 New St",
            city: "San Jose",
            postalCode: "95112"
        )

        XCTAssertEqual(viewModel.customers.first?.name, "Acme Corporation")
        XCTAssertEqual(viewModel.customers.first?.email, "updated@acme.com")
    }

    func testDeleteCustomer() throws {
        try viewModel.createCustomer(
            name: "Acme Corp",
            email: "info@acme.com",
            phone: "555-0101",
            address: "123 Business St",
            city: "San Francisco",
            postalCode: "94102"
        )

        XCTAssertEqual(viewModel.customers.count, 1)

        let customer = viewModel.customers.first!
        try viewModel.deleteCustomer(customer)

        XCTAssertEqual(viewModel.customers.count, 0)
    }

    func testFilteredCustomers() throws {
        try viewModel.createCustomer(
            name: "Acme Corp",
            email: "info@acme.com",
            phone: "555-0101",
            address: "123 Business St",
            city: "San Francisco",
            postalCode: "94102"
        )

        try viewModel.createCustomer(
            name: "TechStart Inc",
            email: "hello@techstart.io",
            phone: "555-0102",
            address: "456 Innovation Ave",
            city: "San Jose",
            postalCode: "95112"
        )

        viewModel.searchText = "Acme"
        XCTAssertEqual(viewModel.filteredCustomers.count, 1)

        viewModel.searchText = "San"
        XCTAssertEqual(viewModel.filteredCustomers.count, 2)

        viewModel.searchText = "nonexistent"
        XCTAssertEqual(viewModel.filteredCustomers.count, 0)
    }
}
