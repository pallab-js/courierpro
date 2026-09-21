import XCTest
@testable import courierpro

@MainActor
final class CSVServiceTests: XCTestCase {

    // MARK: - CSVExporter Tests

    func testExportParcels() {
        let sender = Customer(name: "Mumbai Warehouse")
        let receiver = Customer(name: "Delhi Office")
        let driver = Driver(name: "Rajesh Kumar")
        let parcel = Parcel(
            trackingNumber: "CP-123456-7890",
            status: .inTransit,
            weight: 5.5,
            dimensions: "30x20x15 cm",
            sender: sender,
            receiver: receiver,
            driver: driver
        )

        let csv = CSVExporter.exportParcels([parcel])
        let lines = csv.components(separatedBy: .newlines).filter { !$0.isEmpty }

        XCTAssertEqual(lines.count, 2)
        XCTAssertTrue(lines[0].contains("Tracking Number"))
        XCTAssertTrue(lines[1].contains("CP-123456-7890"))
        XCTAssertTrue(lines[1].contains("In Transit"))
        XCTAssertTrue(lines[1].contains("5.5"))
    }

    func testExportCustomers() {
        let customer = Customer(
            name: "Reliance Retail",
            email: "orders@reliance.in",
            phone: "9876543210",
            address: "Maker Chambers",
            city: "Mumbai",
            postalCode: "400021"
        )

        let csv = CSVExporter.exportCustomers([customer])
        let lines = csv.components(separatedBy: .newlines).filter { !$0.isEmpty }

        XCTAssertEqual(lines.count, 2)
        XCTAssertTrue(lines[0].contains("Name"))
        XCTAssertTrue(lines[1].contains("Reliance Retail"))
        XCTAssertTrue(lines[1].contains("orders@reliance.in"))
    }

    func testExportDrivers() {
        let driver = Driver(name: "Vikram Singh", phone: "9876543211", licenseNumber: "KA-01-001", isAvailable: true)

        let csv = CSVExporter.exportDrivers([driver])
        let lines = csv.components(separatedBy: .newlines).filter { !$0.isEmpty }

        XCTAssertEqual(lines.count, 2)
        XCTAssertTrue(lines[0].contains("Name"))
        XCTAssertTrue(lines[1].contains("Vikram Singh"))
        XCTAssertTrue(lines[1].contains("Yes"))
    }

    func testExportEscapesCSVFormulaInjection() {
        let customer = Customer(name: "=SUM(A1:A10)", email: "+script@test.com")
        let csv = CSVExporter.exportCustomers([customer])
        let lines = csv.components(separatedBy: .newlines).filter { !$0.isEmpty }

        XCTAssertEqual(lines.count, 2)
        XCTAssertTrue(lines[1].contains("'=SUM"))
        XCTAssertTrue(lines[1].contains("'+script"))
    }

    func testExportHandlesCommasInValues() {
        let customer = Customer(name: "Tata, Sons Pvt Ltd", city: "Mumbai, Maharashtra")
        let csv = CSVExporter.exportCustomers([customer])
        let lines = csv.components(separatedBy: .newlines).filter { !$0.isEmpty }

        XCTAssertEqual(lines.count, 2)
        XCTAssertTrue(lines[1].contains("\"Tata, Sons Pvt Ltd\""))
        XCTAssertTrue(lines[1].contains("\"Mumbai, Maharashtra\""))
    }

    func testExportHandlesQuotesInValues() {
        let customer = Customer(name: "He said \"hello\"", city: "Delhi")
        let csv = CSVExporter.exportCustomers([customer])
        let lines = csv.components(separatedBy: .newlines).filter { !$0.isEmpty }

        XCTAssertEqual(lines.count, 2)
        XCTAssertTrue(lines[1].contains("\"He said \"\"hello\"\"\""))
    }

    // MARK: - CSVImporter Tests

    func testImportCustomers() {
        let csv = """
        Name,Email,Phone,Address,City,Postal Code
        Reliance Retail,orders@reliance.in,9876543210,Maker Chambers,Mumbai,400021
        Tata Steel,tata@steel.com,9876543211,Bombay House,Mumbai,400001
        """

        let customers = CSVImporter.importCustomers(from: csv)
        XCTAssertEqual(customers.count, 2)
        XCTAssertEqual(customers[0].name, "Reliance Retail")
        XCTAssertEqual(customers[0].email, "orders@reliance.in")
        XCTAssertEqual(customers[1].name, "Tata Steel")
    }

    func testImportCustomersSkipsEmpty() {
        let csv = """
        Name,Email,Phone,Address,City,Postal Code
        Valid Customer,valid@test.com,9876543210,Address,City,12345
        ,,,
        """

        let customers = CSVImporter.importCustomers(from: csv)
        XCTAssertEqual(customers.count, 1)
        XCTAssertEqual(customers[0].name, "Valid Customer")
    }

    func testImportDrivers() {
        let csv = """
        Name,Phone,License Number,Available
        Rajesh Kumar,9876543210,DL-MH-001,Yes
        Vikram Singh,9876543211,KA-01-001,No
        """

        let drivers = CSVImporter.importDrivers(from: csv)
        XCTAssertEqual(drivers.count, 2)
        XCTAssertEqual(drivers[0].name, "Rajesh Kumar")
        XCTAssertTrue(drivers[0].isAvailable)
        XCTAssertEqual(drivers[1].name, "Vikram Singh")
        XCTAssertFalse(drivers[1].isAvailable)
    }

    func testImportDriversCRLFParsing() {
        let csv = "Name,Phone,License Number,Available\r\nRajesh Kumar,9876543210,DL-MH-001,Yes\r\n"

        let drivers = CSVImporter.importDrivers(from: csv)
        XCTAssertEqual(drivers.count, 1)
        XCTAssertEqual(drivers[0].name, "Rajesh Kumar")
        XCTAssertTrue(drivers[0].isAvailable)
    }

    func testImportSkipsOversizedFile() {
        let largeCSV = String(repeating: "a", count: 10_000_001)
        let customers = CSVImporter.importCustomers(from: largeCSV)
        XCTAssertTrue(customers.isEmpty)
    }

    func testImportSkipsHeaderOnly() {
        let csv = "Name,Email,Phone,Address,City,Postal Code"
        let customers = CSVImporter.importCustomers(from: csv)
        XCTAssertTrue(customers.isEmpty)
    }

    func testImportHandlesQuotedFields() {
        let csv = "Name,Email,Phone,Address,City,Postal Code\n\"Tata, Sons\",tata@test.com,9876543210,\"123 Main St, Floor 2\",Mumbai,400001"
        let customers = CSVImporter.importCustomers(from: csv)
        XCTAssertEqual(customers.count, 1)
        XCTAssertEqual(customers[0].name, "Tata, Sons")
    }

    func testImportFiltersNonNumericPhone() {
        let csv = "Name,Email,Phone,Address,City,Postal Code\nTest,test@test.com,987-654-3210,Address,City,12345"
        let customers = CSVImporter.importCustomers(from: csv)
        XCTAssertEqual(customers.count, 1)
        XCTAssertEqual(customers[0].phone, "9876543210")
    }

    func testImportFiltersNonNumericPostalCode() {
        let csv = "Name,Email,Phone,Address,City,Postal Code\nTest,test@test.com,9876543210,Address,City,AB-12345"
        let customers = CSVImporter.importCustomers(from: csv)
        XCTAssertEqual(customers.count, 1)
        XCTAssertEqual(customers[0].postalCode, "12345")
    }

    func testImportTruncatesLongNames() {
        let longName = String(repeating: "A", count: 300)
        let csv = "Name,Email,Phone,Address,City,Postal Code\n\(longName),test@test.com,9876543210,Address,City,12345"
        let customers = CSVImporter.importCustomers(from: csv)
        XCTAssertEqual(customers.count, 1)
        XCTAssertLessThanOrEqual(customers[0].name.count, 200)
    }

    // MARK: - CSVUtilities Tests

    func testEscapeCSVFormulaPrefix() {
        XCTAssertEqual(CSVUtilities.escapeCSV("=SUM(A1)"), "'=SUM(A1)")
        XCTAssertEqual(CSVUtilities.escapeCSV("+script"), "'+script")
        XCTAssertEqual(CSVUtilities.escapeCSV("-cmd"), "'-cmd")
        XCTAssertEqual(CSVUtilities.escapeCSV("@import"), "'@import")
    }

    func testEscapeCSVNormalValues() {
        XCTAssertEqual(CSVUtilities.escapeCSV("hello"), "hello")
        XCTAssertEqual(CSVUtilities.escapeCSV("123"), "123")
    }

    func testEscapeCSVWrapsCommas() {
        XCTAssertEqual(CSVUtilities.escapeCSV("a,b"), "\"a,b\"")
    }

    func testEscapeCSVWrapsQuotes() {
        XCTAssertEqual(CSVUtilities.escapeCSV("say \"hi\""), "\"say \"\"hi\"\"\"")
    }

    func testValidatePhoneNumber() {
        XCTAssertTrue(CSVUtilities.validatePhoneNumber("9876543210"))
        XCTAssertTrue(CSVUtilities.validatePhoneNumber("987-654-3210"))
        XCTAssertTrue(CSVUtilities.validatePhoneNumber("+919876543210"))
        XCTAssertFalse(CSVUtilities.validatePhoneNumber("12345"))
        XCTAssertFalse(CSVUtilities.validatePhoneNumber("12345678901234567"))
    }
}
