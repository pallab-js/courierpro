import XCTest
@testable import courierpro

@MainActor
final class DriverViewModelTests: XCTestCase {
    private var viewModel: DriverViewModel!
    private var testPersistenceService: PersistenceService!

    @MainActor
    override func setUp() {
        super.setUp()
        testPersistenceService = PersistenceService.inMemory
        viewModel = DriverViewModel(persistenceService: testPersistenceService)
    }

    @MainActor
    override func tearDown() {
        viewModel = nil
        testPersistenceService = nil
        super.tearDown()
    }

    func testLoadDriversEmpty() {
        viewModel.loadDrivers()
        XCTAssertTrue(viewModel.drivers.isEmpty)
    }

    func testCreateDriver() {
        viewModel.createDriver(
            name: "Rajesh Kumar",
            phone: "9876543210",
            licenseNumber: "DL-MH-001",
            isAvailable: true
        )

        XCTAssertEqual(viewModel.drivers.count, 1)
        XCTAssertEqual(viewModel.drivers.first?.name, "Rajesh Kumar")
        XCTAssertEqual(viewModel.drivers.first?.licenseNumber, "DL-MH-001")
        XCTAssertTrue(viewModel.drivers.first?.isAvailable ?? false)
    }

    func testUpdateDriver() {
        viewModel.createDriver(
            name: "Rajesh Kumar",
            phone: "9876543210",
            licenseNumber: "DL-MH-001",
            isAvailable: true
        )

        let driver = viewModel.drivers.first!
        viewModel.updateDriver(
            driver,
            name: "Rajesh Singh",
            phone: "9876543299",
            licenseNumber: "DL-MH-002",
            isAvailable: false
        )

        XCTAssertEqual(viewModel.drivers.first?.name, "Rajesh Singh")
        XCTAssertEqual(viewModel.drivers.first?.licenseNumber, "DL-MH-002")
        XCTAssertFalse(viewModel.drivers.first?.isAvailable ?? true)
    }

    func testToggleAvailability() {
        viewModel.createDriver(
            name: "Vikram Singh",
            phone: "9876543211",
            licenseNumber: "KA-01-001",
            isAvailable: true
        )

        let driver = viewModel.drivers.first!
        XCTAssertTrue(driver.isAvailable)

        viewModel.toggleAvailability(driver)
        XCTAssertFalse(viewModel.drivers.first?.isAvailable ?? true)

        viewModel.toggleAvailability(driver)
        XCTAssertTrue(viewModel.drivers.first?.isAvailable ?? false)
    }

    func testDeleteDriver() {
        viewModel.createDriver(
            name: "Vikram Singh",
            phone: "9876543211",
            licenseNumber: "KA-01-001"
        )

        XCTAssertEqual(viewModel.drivers.count, 1)

        let driver = viewModel.drivers.first!
        viewModel.deleteDriver(driver)
        XCTAssertEqual(viewModel.drivers.count, 0)
    }

    func testFilteredDrivers() {
        viewModel.createDriver(name: "Rajesh Kumar", phone: "9876543210", licenseNumber: "DL-MH-001")
        viewModel.createDriver(name: "Vikram Singh", phone: "9876543211", licenseNumber: "KA-01-001")

        viewModel.searchText = "Rajesh"
        XCTAssertEqual(viewModel.filteredDrivers.count, 1)

        viewModel.searchText = "KA-01"
        XCTAssertEqual(viewModel.filteredDrivers.count, 1)

        viewModel.searchText = "nonexistent"
        XCTAssertEqual(viewModel.filteredDrivers.count, 0)
    }

    func testDriverCaching() {
        viewModel.createDriver(name: "Driver A", phone: "111", licenseNumber: "L1", isAvailable: true)
        viewModel.createDriver(name: "Driver B", phone: "222", licenseNumber: "L2", isAvailable: false)
        viewModel.createDriver(name: "Driver C", phone: "333", licenseNumber: "L3", isAvailable: true)

        XCTAssertEqual(viewModel.availableDrivers.count, 2)
        XCTAssertEqual(viewModel.busyDrivers.count, 1)
        XCTAssertEqual(viewModel.busyDrivers.first?.name, "Driver B")
    }
}
