import XCTest
@testable import courierpro

@MainActor
final class ParcelViewModelTests: XCTestCase {
    private var viewModel: ParcelViewModel!
    private var testPersistenceService: PersistenceService!

    override func setUp() {
        super.setUp()
        testPersistenceService = PersistenceService.inMemory
        viewModel = ParcelViewModel(persistenceService: testPersistenceService)
    }

    override func tearDown() {
        viewModel = nil
        testPersistenceService = nil
        super.tearDown()
    }

    func testLoadParcelsEmpty() {
        viewModel.loadParcels()
        XCTAssertTrue(viewModel.parcels.isEmpty)
    }

    func testCreateParcel() {
        let sender = Customer(name: "Reliance Retail")
        let receiver = Customer(name: "Tata Steel")

        viewModel.createParcel(
            sender: sender,
            receiver: receiver,
            weight: 2.0,
            dimensions: "30x20x15 cm",
            notes: nil
        )

        XCTAssertEqual(viewModel.parcels.count, 1)
        XCTAssertEqual(viewModel.parcels.first?.senderName, "Reliance Retail")
        XCTAssertEqual(viewModel.parcels.first?.receiverName, "Tata Steel")
    }

    func testUpdateParcelStatus() {
        let sender = Customer(name: "Reliance Retail")
        let receiver = Customer(name: "Tata Steel")

        viewModel.createParcel(
            sender: sender,
            receiver: receiver,
            weight: 2.0,
            dimensions: "30x20x15 cm",
            notes: nil
        )

        let parcel = viewModel.parcels.first!
        viewModel.updateParcelStatus(parcel, status: .pickedUp)
        XCTAssertEqual(viewModel.parcels.first?.status, .pickedUp)

        viewModel.updateParcelStatus(parcel, status: .inTransit)
        XCTAssertEqual(viewModel.parcels.first?.status, .inTransit)
    }

    func testDeleteParcel() {
        let sender = Customer(name: "Reliance Retail")
        let receiver = Customer(name: "Tata Steel")

        viewModel.createParcel(
            sender: sender,
            receiver: receiver,
            weight: 2.0,
            dimensions: "30x20x15 cm",
            notes: nil
        )

        XCTAssertEqual(viewModel.parcels.count, 1)

        let parcel = viewModel.parcels.first!
        viewModel.deleteParcel(parcel)

        XCTAssertEqual(viewModel.parcels.count, 0)
    }

    func testFilteredParcels() {
        let sender = Customer(name: "Reliance Retail")
        let receiver = Customer(name: "Tata Steel")

        viewModel.createParcel(
            sender: sender,
            receiver: receiver,
            weight: 2.0,
            dimensions: "30x20x15 cm",
            notes: nil
        )

        viewModel.searchText = "CP"
        XCTAssertEqual(viewModel.filteredParcels.count, 1)

        viewModel.searchText = "nonexistent"
        XCTAssertEqual(viewModel.filteredParcels.count, 0)
    }

    func testParcelCountByStatus() {
        let sender = Customer(name: "Reliance Retail")
        let receiver = Customer(name: "Tata Steel")

        viewModel.createParcel(
            sender: sender,
            receiver: receiver,
            weight: 2.0,
            dimensions: "30x20x15 cm",
            notes: nil
        )

        let counts = viewModel.parcelCountByStatus
        XCTAssertEqual(counts[.created], 1)
        XCTAssertNil(counts[.inTransit])
    }
}
