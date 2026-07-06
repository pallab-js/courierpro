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

    func testLoadParcelsEmpty() throws {
        try viewModel.loadParcels()
        XCTAssertTrue(viewModel.parcels.isEmpty)
    }

    func testCreateParcel() throws {
        let sender = Customer(name: "Sender")
        let receiver = Customer(name: "Receiver")

        try viewModel.createParcel(
            sender: sender,
            receiver: receiver,
            weight: 2.0,
            dimensions: "30x20x15 cm",
            notes: nil
        )

        XCTAssertEqual(viewModel.parcels.count, 1)
        XCTAssertEqual(viewModel.parcels.first?.senderName, "Sender")
        XCTAssertEqual(viewModel.parcels.first?.receiverName, "Receiver")
    }

    func testUpdateParcelStatus() throws {
        let sender = Customer(name: "Sender")
        let receiver = Customer(name: "Receiver")

        try viewModel.createParcel(
            sender: sender,
            receiver: receiver,
            weight: 2.0,
            dimensions: "30x20x15 cm",
            notes: nil
        )

        let parcel = viewModel.parcels.first!
        try viewModel.updateParcelStatus(parcel, status: .inTransit)

        XCTAssertEqual(viewModel.parcels.first?.status, .inTransit)
    }

    func testDeleteParcel() throws {
        let sender = Customer(name: "Sender")
        let receiver = Customer(name: "Receiver")

        try viewModel.createParcel(
            sender: sender,
            receiver: receiver,
            weight: 2.0,
            dimensions: "30x20x15 cm",
            notes: nil
        )

        XCTAssertEqual(viewModel.parcels.count, 1)

        let parcel = viewModel.parcels.first!
        try viewModel.deleteParcel(parcel)

        XCTAssertEqual(viewModel.parcels.count, 0)
    }

    func testFilteredParcels() throws {
        let sender = Customer(name: "Sender")
        let receiver = Customer(name: "Receiver")

        try viewModel.createParcel(
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

    func testParcelCountByStatus() throws {
        let sender = Customer(name: "Sender")
        let receiver = Customer(name: "Receiver")

        try viewModel.createParcel(
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
