import XCTest
@testable import courierpro

final class CustomerTests: XCTestCase {
    func testCustomerInitialization() {
        let customer = Customer(
            name: "Acme Corp",
            email: "info@acme.com",
            phone: "555-0101",
            address: "123 Business St",
            city: "San Francisco",
            postalCode: "94102"
        )

        XCTAssertEqual(customer.name, "Acme Corp")
        XCTAssertEqual(customer.email, "info@acme.com")
        XCTAssertEqual(customer.phone, "555-0101")
        XCTAssertEqual(customer.address, "123 Business St")
        XCTAssertEqual(customer.city, "San Francisco")
        XCTAssertEqual(customer.postalCode, "94102")
    }

    func testCustomerFullName() {
        let customer = Customer(name: "John Smith")
        XCTAssertEqual(customer.fullName, "John Smith")
    }

    func testCustomerShortAddress() {
        let customer = Customer(
            name: "Test",
            city: "San Francisco",
            postalCode: "94102"
        )
        XCTAssertEqual(customer.shortAddress, "San Francisco 94102")
    }

    func testCustomerShortAddressEmpty() {
        let customer = Customer(name: "Test")
        XCTAssertEqual(customer.shortAddress, "")
    }

    func testCustomerDefaultValues() {
        let customer = Customer(name: "Test")

        XCTAssertTrue(customer.email.isEmpty)
        XCTAssertTrue(customer.phone.isEmpty)
        XCTAssertTrue(customer.address.isEmpty)
        XCTAssertTrue(customer.city.isEmpty)
        XCTAssertTrue(customer.postalCode.isEmpty)
    }

    func testCustomerTimestamps() {
        let before = Date()
        let customer = Customer(name: "Test")
        let after = Date()

        XCTAssertGreaterThanOrEqual(customer.createdAt, before)
        XCTAssertLessThanOrEqual(customer.createdAt, after)
        XCTAssertGreaterThanOrEqual(customer.updatedAt, before)
        XCTAssertLessThanOrEqual(customer.updatedAt, after)
    }
}
