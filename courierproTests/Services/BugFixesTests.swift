import XCTest
@testable import courierpro
import SwiftData
import CoreLocation

@MainActor
final class BugFixesTests: XCTestCase {
    private var persistenceService: PersistenceService!
    private var context: ModelContext { persistenceService.modelContext }
    private var viewModel: InvoiceViewModel!

    override func setUp() {
        super.setUp()
        persistenceService = PersistenceService.inMemory
        viewModel = InvoiceViewModel(persistenceService: persistenceService)
    }

    override func tearDown() {
        viewModel = nil
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

    // 6. Deleting a customer that an invoice points to must not leave a dangling reference
    func testDeleteCustomerBlockedWhenLinkedInvoiceExists() throws {
        let customer = Customer(name: "B Corp")
        let invoice = Invoice(invoiceNumber: "INV-C1", customer: customer)
        persistenceService.insert(customer)
        persistenceService.insert(invoice)
        try persistenceService.save()

        let viewModel = CustomerViewModel(persistenceService: persistenceService)
        viewModel.deleteCustomer(customer)

        XCTAssertTrue(viewModel.showError)
        XCTAssertNotNil(viewModel.errorMessage)

        let remaining = try context.fetch(FetchDescriptor<Customer>())
        XCTAssertEqual(remaining.count, 1, "Customer referenced by an invoice must not be deleted")
        XCTAssertEqual(remaining.first?.name, "B Corp")
    }

    // 7. Backup/restore must preserve invoice tax and total
    func testBackupRestorePreservesInvoiceTotals() throws {
        let customer = Customer(name: "Tata Steel Ltd")
        persistenceService.insert(customer)

        let invoice = Invoice(
            invoiceNumber: "INV-C2",
            status: .pending,
            subtotal: 1000,
            taxRate: 18,
            customer: customer
        )
        invoice.taxAmount = 180
        invoice.totalAmount = 1180
        let item = InvoiceItem(itemDescription: "Delivery", quantity: 1, unitPrice: 1000, invoice: invoice)
        invoice.items = [item]
        persistenceService.insert(invoice)
        persistenceService.insert(item)
        try persistenceService.save()

        let backupURL = try DataBackupService.createBackup(context: context)
        defer { try? DataBackupService.deleteBackup(at: backupURL) }
        try DataBackupService.restoreBackup(from: backupURL, context: context)

        let restored = try context.fetch(FetchDescriptor<Invoice>())
        XCTAssertEqual(restored.count, 1)
        XCTAssertEqual(restored.first?.subtotal ?? -1, 1000, accuracy: 0.01)
        XCTAssertEqual(restored.first?.taxAmount ?? -1, 180, accuracy: 0.01)
        XCTAssertEqual(restored.first?.totalAmount ?? -1, 1180, accuracy: 0.01)
    }

    // 8. Backup/restore must not drop recurring invoices or status history
    func testBackupRestorePreservesRecurringInvoicesAndStatusHistory() throws {
        let customer = Customer(name: "Wipro Ltd")
        let parcel = Parcel(trackingNumber: "CP-C3", weight: 2.0, sender: customer, receiver: customer)
        let recurring = RecurringInvoice(
            name: "Monthly Maintenance",
            frequency: .monthly,
            amount: 150,
            taxRate: 18,
            customer: customer
        )
        let history = StatusHistory(
            status: .pickedUp,
            timestamp: Date(),
            notes: "Collected from origin",
            updatedBy: "Ravi",
            parcel: parcel
        )

        persistenceService.insert(customer)
        persistenceService.insert(parcel)
        persistenceService.insert(recurring)
        persistenceService.insert(history)
        try persistenceService.save()

        let backupURL = try DataBackupService.createBackup(context: context)
        defer { try? DataBackupService.deleteBackup(at: backupURL) }
        try DataBackupService.restoreBackup(from: backupURL, context: context)

        let restoredRecurring = try context.fetch(FetchDescriptor<RecurringInvoice>())
        XCTAssertEqual(restoredRecurring.count, 1)
        XCTAssertEqual(restoredRecurring.first?.name, "Monthly Maintenance")
        XCTAssertEqual(restoredRecurring.first?.amount ?? -1, 150, accuracy: 0.01)
        XCTAssertEqual(restoredRecurring.first?.customer?.name, "Wipro Ltd")

        let restoredHistory = try context.fetch(FetchDescriptor<StatusHistory>())
        XCTAssertEqual(restoredHistory.count, 1)
        XCTAssertEqual(restoredHistory.first?.status, .pickedUp)
        XCTAssertEqual(restoredHistory.first?.updatedBy, "Ravi")
        XCTAssertEqual(restoredHistory.first?.parcel?.trackingNumber, "CP-C3")
    }

    // 9. Status timeline must mark every step up to (and including) the current one as complete
    func testStatusTimelineCompletionLogic() {
        for step in [DeliveryStatus.created, .pickedUp, .inTransit, .outForDelivery, .delivered] {
            XCTAssertTrue(
                step.isCompletedOrSucceeded(by: .delivered),
                "\(step.displayName) should be complete for a delivered parcel"
            )
        }

        XCTAssertTrue(DeliveryStatus.created.isCompletedOrSucceeded(by: .inTransit))
        XCTAssertTrue(DeliveryStatus.pickedUp.isCompletedOrSucceeded(by: .inTransit))
        XCTAssertTrue(DeliveryStatus.inTransit.isCompletedOrSucceeded(by: .inTransit))
        XCTAssertFalse(DeliveryStatus.outForDelivery.isCompletedOrSucceeded(by: .inTransit))
        XCTAssertFalse(DeliveryStatus.delivered.isCompletedOrSucceeded(by: .inTransit))
    }

    // 10. Saving settings must refresh the shared instance the rest of the app reads
    func testAppSettingsSharedReflectsSave() {
        let original = AppSettings.load()
        defer { original.save() }

        // Force the shared cache to initialize while it still holds the old values;
        // otherwise a lazy `static let` would pick up the save below on first access.
        _ = AppSettings.shared
        XCTAssertEqual(AppSettings.shared.currencySymbol, original.currencySymbol)

        let newSymbol = original.currencySymbol == "$" ? "€" : "$"
        let newPrefix = original.trackingPrefix == "ZX" ? "QQ" : "ZX"

        var settings = original
        settings.currencySymbol = newSymbol
        settings.trackingPrefix = newPrefix
        settings.save()

        XCTAssertEqual(AppSettings.shared.currencySymbol, newSymbol)
        XCTAssertEqual(AppSettings.shared.trackingPrefix, newPrefix)
    }

    // 11. Pricing rules must be loaded before the invoice form prices parcels
    func testLoadInvoiceFormDataLoadsPricingRules() {
        let rule = PricingRule(
            name: "Per Kg",
            pricingType: .perKg,
            basePrice: 10.0,
            pricePerUnit: 2.0,
            minimumWeight: 0,
            maximumWeight: 100
        )
        let sender = Customer(name: "Origin Warehouse")
        let receiver = Customer(name: "Destination Office")
        let parcel = Parcel(weight: 5, sender: sender, receiver: receiver)
        parcel.statusRaw = DeliveryStatus.delivered.rawValue

        persistenceService.insert(rule)
        persistenceService.insert(sender)
        persistenceService.insert(receiver)
        persistenceService.insert(parcel)
        try? persistenceService.save()

        let data = viewModel.loadInvoiceFormData()

        XCTAssertEqual(viewModel.pricingRules.count, 1, "Form data must load pricing rules")
        XCTAssertEqual(data.parcels.count, 1)
        let price = viewModel.calculatePrice(for: parcel)
        XCTAssertEqual(price, 20.0, accuracy: 0.01, "Rule-based price must be used instead of the ₹10 fallback")
    }

    // 12. CSV escaping must not strip accented / non-ASCII characters
    func testCSVEscapePreservesNonASCII() {
        XCTAssertEqual(CSVUtilities.escapeCSV("José García"), "José García")
        XCTAssertEqual(CSVUtilities.escapeCSV("₹500"), "₹500")
        XCTAssertEqual(CSVUtilities.escapeCSV("Tōkyō"), "Tōkyō")

        // Control characters must still be removed
        XCTAssertEqual(CSVUtilities.escapeCSV("a\u{0007}b"), "ab")

        // Existing behaviours must hold
        XCTAssertEqual(CSVUtilities.escapeCSV("a,b"), "\"a,b\"")
        XCTAssertEqual(CSVUtilities.escapeCSV("=SUM(A1)"), "'=SUM(A1)")
    }

    // 13. Pending invoices past their due date must be flagged overdue
    func testInvoicesPastDueMarkedOverdue() {
        let customer = Customer(name: "Late Payer")
        let yesterday = Date().addingTimeInterval(-86_400)
        let tomorrow = Date().addingTimeInterval(86_400)

        let pastDue = Invoice(
            invoiceNumber: "INV-OD1", status: .pending, subtotal: 100, taxRate: 0,
            dueDate: yesterday, customer: customer
        )
        pastDue.totalAmount = 100

        let paidLate = Invoice(
            invoiceNumber: "INV-OD2", status: .paid, subtotal: 100, taxRate: 0,
            dueDate: yesterday, customer: customer
        )
        paidLate.totalAmount = 100

        let notYetDue = Invoice(
            invoiceNumber: "INV-OD3", status: .pending, subtotal: 100, taxRate: 0,
            dueDate: tomorrow, customer: customer
        )
        notYetDue.totalAmount = 100

        [pastDue, paidLate, notYetDue].forEach(persistenceService.insert)
        try? persistenceService.save()

        viewModel.loadInvoices()

        XCTAssertEqual(pastDue.status, .overdue, "Pending invoice past due date must become overdue")
        XCTAssertEqual(paidLate.status, .paid, "Paid invoices must not be re-flagged")
        XCTAssertEqual(notYetDue.status, .pending, "Invoice not yet due must stay pending")
        XCTAssertEqual(viewModel.overdueAmount, 100, accuracy: 0.01)
    }

    // 14. A successful delete must clear a stale error left by an earlier failed operation
    func testDeleteClearsPreviousErrorMessage() {
        let sender = Customer(name: "Reliance Retail")
        let receiver = Customer(name: "Tata Steel")
        let parcelVM = ParcelViewModel(persistenceService: persistenceService)
        parcelVM.createParcel(sender: sender, receiver: receiver, weight: 2.0, dimensions: "", notes: nil)
        let parcel = parcelVM.parcels.first!

        parcelVM.updateParcelStatus(parcel, status: .delivered)
        XCTAssertTrue(parcelVM.showError)
        XCTAssertNotNil(parcelVM.errorMessage)

        parcelVM.deleteParcel(parcel)
        XCTAssertNil(parcelVM.errorMessage, "A successful delete must clear the stale error")
        XCTAssertFalse(parcelVM.showError)
        XCTAssertTrue(parcelVM.parcels.isEmpty)

        let invoiceVM = InvoiceViewModel(persistenceService: persistenceService)
        let invoice = Invoice(invoiceNumber: "INV-H7", customer: Customer(name: "HCL"))
        persistenceService.insert(invoice)
        try? persistenceService.save()

        invoiceVM.addPayment(to: invoice, amount: 0, method: .cash, reference: nil)
        XCTAssertTrue(invoiceVM.showError)
        XCTAssertNotNil(invoiceVM.errorMessage)

        invoiceVM.deleteInvoice(invoice)
        XCTAssertNil(invoiceVM.errorMessage, "A successful delete must clear the stale error")
        XCTAssertFalse(invoiceVM.showError)
    }
}
