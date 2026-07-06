import XCTest
@testable import courierpro
import SwiftData

@MainActor
final class PersistenceServiceTests: XCTestCase {
    private var persistenceService: PersistenceService!

    override func setUp() {
        super.setUp()
        persistenceService = PersistenceService.inMemory
    }

    override func tearDown() {
        persistenceService = nil
        super.tearDown()
    }

    func testSaveAndFetch() throws {
        let customer = Customer(name: "Test Customer")
        persistenceService.insert(customer)
        try persistenceService.save()

        let descriptor = FetchDescriptor<Customer>()
        let fetched = try persistenceService.fetch(descriptor)

        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.name, "Test Customer")
    }

    func testDelete() throws {
        let customer = Customer(name: "Test Customer")
        persistenceService.insert(customer)
        try persistenceService.save()

        persistenceService.delete(customer)
        try persistenceService.save()

        let descriptor = FetchDescriptor<Customer>()
        let fetched = try persistenceService.fetch(descriptor)

        XCTAssertTrue(fetched.isEmpty)
    }

    func testDeleteMultiple() throws {
        let customer1 = Customer(name: "Customer 1")
        let customer2 = Customer(name: "Customer 2")
        persistenceService.insert(customer1)
        persistenceService.insert(customer2)
        try persistenceService.save()

        persistenceService.delete([customer1, customer2])
        try persistenceService.save()

        let descriptor = FetchDescriptor<Customer>()
        let fetched = try persistenceService.fetch(descriptor)

        XCTAssertTrue(fetched.isEmpty)
    }
}
