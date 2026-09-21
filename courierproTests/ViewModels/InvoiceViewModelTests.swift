import XCTest
@testable import courierpro

@MainActor
final class InvoiceViewModelTests: XCTestCase {
    private var viewModel: InvoiceViewModel!
    private var testPersistenceService: PersistenceService!

    override func setUp() {
        super.setUp()
        testPersistenceService = PersistenceService.inMemory
        viewModel = InvoiceViewModel(persistenceService: testPersistenceService)
    }

    override func tearDown() {
        viewModel = nil
        testPersistenceService = nil
        super.tearDown()
    }

    func testLoadInvoicesEmpty() {
        viewModel.loadInvoices()
        XCTAssertTrue(viewModel.invoices.isEmpty)
    }

    func testLoadPricingRulesEmpty() {
        viewModel.loadPricingRules()
        XCTAssertTrue(viewModel.pricingRules.isEmpty)
    }

    func testCreateInvoice() {
        let customer = Customer(name: "Tata Steel Ltd")
        let sender = Customer(name: "Mumbai Warehouse")
        let receiver = Customer(name: "Delhi Office")
        let parcel = Parcel(weight: 5.0, sender: sender, receiver: receiver)

        testPersistenceService.insert(customer)
        testPersistenceService.insert(sender)
        testPersistenceService.insert(receiver)
        testPersistenceService.insert(parcel)
        try? testPersistenceService.save()

        viewModel.createInvoice(
            customer: customer,
            parcels: [parcel],
            taxRate: 18.0,
            notes: "Test invoice",
            dueDate: Date()
        )

        XCTAssertEqual(viewModel.invoices.count, 1)
        XCTAssertEqual(viewModel.invoices.first?.customer?.name, "Tata Steel Ltd")
        XCTAssertEqual(viewModel.invoices.first?.taxRate, 18.0)
    }

    func testUpdateInvoiceStatus() {
        let customer = Customer(name: "Wipro Ltd")
        let invoice = Invoice(taxRate: 18.0, customer: customer)
        testPersistenceService.insert(invoice)
        try? testPersistenceService.save()

        viewModel.loadInvoices()
        XCTAssertEqual(viewModel.invoices.first?.status, .draft)

        viewModel.updateInvoiceStatus(invoice, status: .pending)
        XCTAssertEqual(viewModel.invoices.first?.status, .pending)

        viewModel.updateInvoiceStatus(invoice, status: .paid)
        XCTAssertEqual(viewModel.invoices.first?.status, .paid)
        XCTAssertNotNil(viewModel.invoices.first?.paidAt)
    }

    func testAddPayment() {
        let customer = Customer(name: "Infosys Ltd")
        let invoice = Invoice(taxRate: 18.0, customer: customer)
        invoice.subtotal = 100.0
        invoice.taxAmount = 18.0
        invoice.totalAmount = 118.0
        testPersistenceService.insert(invoice)
        try? testPersistenceService.save()

        viewModel.loadInvoices()

        viewModel.addPayment(to: invoice, amount: 50.0, method: .cash, reference: "CASH-001")
        XCTAssertEqual(viewModel.invoices.first?.totalPaid, 50.0)
        XCTAssertEqual(viewModel.invoices.first?.balanceDue, 68.0)
        XCTAssertFalse(viewModel.invoices.first?.isFullyPaid ?? true)

        viewModel.addPayment(to: invoice, amount: 68.0, method: .bankTransfer, reference: "NEFT-001")
        XCTAssertEqual(viewModel.invoices.first?.totalPaid, 118.0)
        XCTAssertEqual(viewModel.invoices.first?.balanceDue, 0.0)
        XCTAssertTrue(viewModel.invoices.first?.isFullyPaid ?? false)
        XCTAssertEqual(viewModel.invoices.first?.status, .paid)
    }

    func testAddPaymentCapsAtBalanceDue() {
        let customer = Customer(name: "HCL Tech")
        let invoice = Invoice(taxRate: 0, customer: customer)
        invoice.subtotal = 100.0
        invoice.totalAmount = 100.0
        testPersistenceService.insert(invoice)
        try? testPersistenceService.save()

        viewModel.loadInvoices()

        viewModel.addPayment(to: invoice, amount: 200.0, method: .cash, reference: nil)
        XCTAssertEqual(viewModel.invoices.first?.totalPaid, 100.0)
        XCTAssertEqual(viewModel.invoices.first?.balanceDue, 0.0)
    }

    func testDeleteInvoice() {
        let customer = Customer(name: "Test Customer")
        let invoice = Invoice(customer: customer)
        testPersistenceService.insert(invoice)
        try? testPersistenceService.save()

        viewModel.loadInvoices()
        XCTAssertEqual(viewModel.invoices.count, 1)

        viewModel.deleteInvoice(invoice)
        XCTAssertEqual(viewModel.invoices.count, 0)
    }

    func testCreatePricingRule() {
        viewModel.createPricingRule(
            name: "Weight Based",
            pricingType: .perKg,
            basePrice: 10.0,
            pricePerUnit: 2.5,
            minimumWeight: 0,
            maximumWeight: 50
        )

        XCTAssertEqual(viewModel.pricingRules.count, 1)
        XCTAssertEqual(viewModel.pricingRules.first?.name, "Weight Based")
        XCTAssertEqual(viewModel.pricingRules.first?.pricingType, .perKg)
        XCTAssertEqual(viewModel.pricingRules.first?.basePrice, 10.0)
        XCTAssertEqual(viewModel.pricingRules.first?.pricePerUnit, 2.5)
    }

    func testDeletePricingRule() {
        viewModel.createPricingRule(
            name: "Flat Rate",
            pricingType: .flatRate,
            basePrice: 25.0,
            pricePerUnit: 0,
            minimumWeight: 0,
            maximumWeight: 100
        )

        XCTAssertEqual(viewModel.pricingRules.count, 1)

        let rule = viewModel.pricingRules.first!
        viewModel.deletePricingRule(rule)
        XCTAssertEqual(viewModel.pricingRules.count, 0)
    }

    func testCalculatePriceFlatRate() {
        let rule = PricingRule(name: "Flat", pricingType: .flatRate, basePrice: 50.0, pricePerUnit: 0)
        viewModel.pricingRules = [rule]

        let parcel = Parcel(weight: 5.0)
        let price = viewModel.calculatePrice(for: parcel)
        XCTAssertEqual(price, 50.0)
    }

    func testCalculatePricePerKg() {
        let rule = PricingRule(name: "Per Kg", pricingType: .perKg, basePrice: 10.0, pricePerUnit: 2.0, minimumWeight: 0, maximumWeight: 100)
        viewModel.pricingRules = [rule]

        let parcel = Parcel(weight: 5.0)
        let price = viewModel.calculatePrice(for: parcel)
        XCTAssertEqual(price, 20.0)
    }

    func testCalculatePriceFallback() {
        viewModel.pricingRules = []

        let parcel = Parcel(weight: 5.0)
        let price = viewModel.calculatePrice(for: parcel)
        XCTAssertEqual(price, 10.0)
    }

    func testFinancialCaching() {
        let customer = Customer(name: "Test")

        let inv1 = Invoice(taxRate: 0, customer: customer)
        inv1.subtotal = 100
        inv1.totalAmount = 100
        inv1.statusRaw = InvoiceStatus.paid.rawValue
        testPersistenceService.insert(inv1)

        let inv2 = Invoice(taxRate: 0, customer: customer)
        inv2.subtotal = 200
        inv2.totalAmount = 200
        inv2.statusRaw = InvoiceStatus.pending.rawValue
        testPersistenceService.insert(inv2)

        let inv3 = Invoice(taxRate: 0, customer: customer)
        inv3.subtotal = 50
        inv3.totalAmount = 50
        inv3.statusRaw = InvoiceStatus.overdue.rawValue
        testPersistenceService.insert(inv3)

        try? testPersistenceService.save()
        viewModel.loadInvoices()

        XCTAssertEqual(viewModel.totalRevenue, 100.0)
        XCTAssertEqual(viewModel.pendingAmount, 200.0)
        XCTAssertEqual(viewModel.overdueAmount, 50.0)
    }
}
