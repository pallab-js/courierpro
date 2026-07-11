import XCTest
@testable import courierpro
import SwiftData
import CoreLocation

@MainActor
final class BugFixesTests: XCTestCase {
    private var persistenceService: PersistenceService!
    private var context: ModelContext { persistenceService.modelContext }

    override func setUp() {
        super.setUp()
        persistenceService = PersistenceService.inMemory
    }

    override func tearDown() {
        persistenceService = nil
        super.tearDown()
    }

    // 1. Backup restore relationships & Purge Database
    func testBackupRestoreAndPurge() throws {
        // Create initial customer and parcel
        let customer = Customer(name: "Tata Steel Ltd")
        let parcel = Parcel(trackingNumber: "CP-1111", weight: 5.0, sender: customer, receiver: customer)
        persistenceService.insert(customer)
        persistenceService.insert(parcel)
        
        let invoice = Invoice(invoiceNumber: "INV-001", customer: customer)
        let item = InvoiceItem(itemDescription: "Delivery", quantity: 1, unitPrice: 20.0, parcel: parcel, invoice: invoice)
        invoice.items = [item]
        persistenceService.insert(invoice)
        persistenceService.insert(item)
        try persistenceService.save()

        // Create a backup file
        let backupURL = try DataBackupService.createBackup(context: context)
        defer { try? DataBackupService.deleteBackup(at: backupURL) }

        // Perform restore (which should purge the DB first and fetch parcels after insert to link items properly)
        try DataBackupService.restoreBackup(from: backupURL, context: context)

        // Verify the restored records
        let restoredInvoices = try context.fetch(FetchDescriptor<Invoice>())
        XCTAssertEqual(restoredInvoices.count, 1)
        XCTAssertEqual(restoredInvoices.first?.invoiceNumber, "INV-001")

        let restoredItems = try context.fetch(FetchDescriptor<InvoiceItem>())
        XCTAssertEqual(restoredItems.count, 1)
        XCTAssertNotNil(restoredItems.first?.parcel)
        XCTAssertEqual(restoredItems.first?.parcel?.trackingNumber, "CP-1111")
    }

    // 2. CSV parsing of CRLF
    func testCSVCRLFParsing() throws {
        let csvContent = "Name,Phone,License,IsAvailable\r\nRajesh Kumar,9876500001,DL-MH-001,Yes\r\n"
        let drivers = CSVImporter.importDrivers(from: csvContent)
        XCTAssertEqual(drivers.count, 1)
        XCTAssertEqual(drivers.first?.name, "Rajesh Kumar")
        XCTAssertEqual(drivers.first?.isAvailable, true) // ensures the "Yes\r" was properly trimmed
    }

    // 3. Distance calculation pricing
    func testDistanceCalculationPricing() throws {
        // Setup Customers with coordinates: sender at Bangalore (12.9716, 77.5946), receiver at Chennai (13.0827, 80.2707) (~290 km)
        let sender = Customer(name: "Infosys Technologies", latitude: 12.9716, longitude: 77.5946)
        let receiver = Customer(name: "TCS Chennai", latitude: 13.0827, longitude: 80.2707)
        let parcel = Parcel(weight: 2.0, sender: sender, receiver: receiver)
        
        let pricingRule = PricingRule(name: "Per Km Rule", pricingType: .perKm, basePrice: 10.0, pricePerUnit: 2.0, minimumWeight: 0, maximumWeight: 10)
        
        let invoiceViewModel = InvoiceViewModel(persistenceService: persistenceService)
        invoiceViewModel.pricingRules = [pricingRule]
        
        let price = invoiceViewModel.calculatePrice(for: parcel)
        
        // Calculate expected price: basePrice (10.0) + distance * pricePerUnit (2.0)
        let dist = RouteOptimizer.distance(from: sender.coordinate, to: receiver.coordinate)
        let expected = 10.0 + (dist * 2.0)
        XCTAssertEqual(price, expected, accuracy: 0.01)
    }

    // 4. Driver status logic
    func testDriverBusyAndAvailability() throws {
        let driver = Driver(name: "Vikram Singh")
        persistenceService.insert(driver)
        try persistenceService.save()

        XCTAssertFalse(driver.isBusy)
        XCTAssertTrue(driver.isAvailable)

        let parcel = Parcel(trackingNumber: "CP-2222", status: .pickedUp)
        parcel.driver = driver
        persistenceService.insert(parcel)
        try persistenceService.save()

        // Vikram should be busy because the parcel is not delivered or failed
        XCTAssertTrue(driver.isBusy)

        // Vikram's isAvailable should NOT have changed (toggled or assignment didn't modify it)
        XCTAssertTrue(driver.isAvailable)

        // Complete the parcel
        parcel.status = .delivered
        try persistenceService.save()
        XCTAssertFalse(driver.isBusy)
    }

    // 5. Recurring invoice generation
    func testRecurringInvoiceGeneration() throws {
        let customer = Customer(name: "Wipro Limited")
        let recurring = RecurringInvoice(name: "Monthly Maintenance", frequency: .monthly, amount: 150.0, taxRate: 18.0, customer: customer)
        
        guard let invoice = recurring.generateNextInvoice() else {
            XCTFail("generateNextInvoice should return a valid invoice")
            return
        }
        
        XCTAssertEqual(invoice.subtotal, 150.0)
        XCTAssertEqual(invoice.taxRate, 18.0)
        XCTAssertEqual(invoice.taxAmount, 27.0)
        XCTAssertEqual(invoice.totalAmount, 177.0)
        XCTAssertEqual(invoice.items?.count, 1)
        XCTAssertEqual(invoice.items?.first?.itemDescription, "Monthly Maintenance")
        XCTAssertEqual(invoice.items?.first?.totalPrice, 150.0)
    }
}
