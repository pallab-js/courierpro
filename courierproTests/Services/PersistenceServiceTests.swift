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
        let customer = Customer(name: "HDFC Bank")
        persistenceService.insert(customer)
        try persistenceService.save()

        let descriptor = FetchDescriptor<Customer>()
        let fetched = try persistenceService.fetch(descriptor)

        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.name, "HDFC Bank")
    }

    func testDelete() throws {
        let customer = Customer(name: "HDFC Bank")
        persistenceService.insert(customer)
        try persistenceService.save()

        persistenceService.delete(customer)
        try persistenceService.save()

        let descriptor = FetchDescriptor<Customer>()
        let fetched = try persistenceService.fetch(descriptor)

        XCTAssertTrue(fetched.isEmpty)
    }

    func testDeleteMultiple() throws {
        let customer1 = Customer(name: "HDFC Bank")
        let customer2 = Customer(name: "ICICI Bank")
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
