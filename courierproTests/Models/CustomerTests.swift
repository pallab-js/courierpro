import XCTest
@testable import courierpro

final class CustomerTests: XCTestCase {
    func testCustomerInitialization() {
        let customer = Customer(
            name: "Reliance Retail Ltd",
            email: "orders@reliance.in",
            phone: "9876543210",
            address: "Maker Chambers IV, 222 Nariman Point",
            city: "Mumbai",
            postalCode: "400021"
        )

        XCTAssertEqual(customer.name, "Reliance Retail Ltd")
        XCTAssertEqual(customer.email, "orders@reliance.in")
        XCTAssertEqual(customer.phone, "9876543210")
        XCTAssertEqual(customer.address, "Maker Chambers IV, 222 Nariman Point")
        XCTAssertEqual(customer.city, "Mumbai")
        XCTAssertEqual(customer.postalCode, "400021")
    }

    func testCustomerFullName() {
        let customer = Customer(name: "Tata Consultancy Services")
        XCTAssertEqual(customer.fullName, "Tata Consultancy Services")
    }

    func testCustomerShortAddress() {
        let customer = Customer(
            name: "Test",
            city: "Bangalore",
            postalCode: "560100"
        )
        XCTAssertEqual(customer.shortAddress, "Bangalore 560100")
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
