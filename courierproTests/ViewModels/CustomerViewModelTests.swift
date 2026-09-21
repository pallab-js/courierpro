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

    func testLoadCustomersEmpty() {
        viewModel.loadCustomers()
        XCTAssertTrue(viewModel.customers.isEmpty)
    }

    func testCreateCustomer() {
        viewModel.createCustomer(
            name: "Reliance Retail Ltd",
            email: "orders@reliance.in",
            phone: "9876543210",
            address: "Maker Chambers IV, 222 Nariman Point",
            city: "Mumbai",
            postalCode: "400021"
        )

        XCTAssertEqual(viewModel.customers.count, 1)
        XCTAssertEqual(viewModel.customers.first?.name, "Reliance Retail Ltd")
        XCTAssertEqual(viewModel.customers.first?.email, "orders@reliance.in")
    }

    func testUpdateCustomer() {
        viewModel.createCustomer(
            name: "Reliance Retail Ltd",
            email: "orders@reliance.in",
            phone: "9876543210",
            address: "Maker Chambers IV, 222 Nariman Point",
            city: "Mumbai",
            postalCode: "400021"
        )

        let customer = viewModel.customers.first!
        viewModel.updateCustomer(
            customer,
            name: "Reliance Industries Ltd",
            email: "logistics@ril.com",
            phone: "9876543299",
            address: "Vivek Compound, 23rd Road",
            city: "Mumbai",
            postalCode: "400052"
        )

        XCTAssertEqual(viewModel.customers.first?.name, "Reliance Industries Ltd")
        XCTAssertEqual(viewModel.customers.first?.email, "logistics@ril.com")
    }

    func testDeleteCustomer() {
        viewModel.createCustomer(
            name: "Reliance Retail Ltd",
            email: "orders@reliance.in",
            phone: "9876543210",
            address: "Maker Chambers IV, 222 Nariman Point",
            city: "Mumbai",
            postalCode: "400021"
        )

        XCTAssertEqual(viewModel.customers.count, 1)

        let customer = viewModel.customers.first!
        viewModel.deleteCustomer(customer)

        XCTAssertEqual(viewModel.customers.count, 0)
    }

    func testFilteredCustomers() {
        viewModel.createCustomer(
            name: "Reliance Retail Ltd",
            email: "orders@reliance.in",
            phone: "9876543210",
            address: "Maker Chambers IV, 222 Nariman Point",
            city: "Mumbai",
            postalCode: "400021"
        )

        viewModel.createCustomer(
            name: "Tata Consultancy Services",
            email: "supply@tcs.com",
            phone: "9876543211",
            address: "TCS Campus, Whitefield",
            city: "Bangalore",
            postalCode: "560066"
        )

        viewModel.searchText = "Reliance"
        XCTAssertEqual(viewModel.filteredCustomers.count, 1)

        viewModel.searchText = "Mumbai"
        XCTAssertEqual(viewModel.filteredCustomers.count, 1)

        viewModel.searchText = "nonexistent"
        XCTAssertEqual(viewModel.filteredCustomers.count, 0)
    }
}
