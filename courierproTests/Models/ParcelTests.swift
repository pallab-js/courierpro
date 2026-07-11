import XCTest
@testable import courierpro

final class ParcelTests: XCTestCase {
    func testParcelInitialization() {
        let parcel = Parcel(
            trackingNumber: "CP-123456",
            status: .created,
            weight: 2.5,
            dimensions: "30x20x15 cm"
        )

        XCTAssertEqual(parcel.trackingNumber, "CP-123456")
        XCTAssertEqual(parcel.status, .created)
        XCTAssertEqual(parcel.weight, 2.5)
        XCTAssertEqual(parcel.dimensions, "30x20x15 cm")
    }

    func testTrackingNumberGeneration() {
        let parcel1 = Parcel()
        let parcel2 = Parcel()

        XCTAssertFalse(parcel1.trackingNumber.isEmpty)
        XCTAssertFalse(parcel2.trackingNumber.isEmpty)
        XCTAssertNotEqual(parcel1.trackingNumber, parcel2.trackingNumber)
    }

    func testTrackingNumberFormat() {
        let parcel = Parcel()
        let components = parcel.trackingNumber.split(separator: "-")

        XCTAssertEqual(components.count, 3)
        XCTAssertEqual(components[0], "CP")
    }

    func testStatusDisplayName() {
        XCTAssertEqual(DeliveryStatus.created.displayName, "Created")
        XCTAssertEqual(DeliveryStatus.pickedUp.displayName, "Picked Up")
        XCTAssertEqual(DeliveryStatus.inTransit.displayName, "In Transit")
        XCTAssertEqual(DeliveryStatus.outForDelivery.displayName, "Out for Delivery")
        XCTAssertEqual(DeliveryStatus.delivered.displayName, "Delivered")
        XCTAssertEqual(DeliveryStatus.failed.displayName, "Failed")
    }

    func testStatusSystemImage() {
        XCTAssertEqual(DeliveryStatus.created.systemImage, "doc.badge.plus")
        XCTAssertEqual(DeliveryStatus.pickedUp.systemImage, "hand.raised.fingers.spread")
        XCTAssertEqual(DeliveryStatus.inTransit.systemImage, "truck")
        XCTAssertEqual(DeliveryStatus.outForDelivery.systemImage, "truck.box")
        XCTAssertEqual(DeliveryStatus.delivered.systemImage, "checkmark.circle")
        XCTAssertEqual(DeliveryStatus.failed.systemImage, "exclamationmark.triangle")
    }

    func testParcelStatusUpdate() {
        let parcel = Parcel()
        XCTAssertEqual(parcel.status, .created)

        parcel.status = .inTransit
        XCTAssertEqual(parcel.status, .inTransit)
        XCTAssertEqual(parcel.statusRaw, DeliveryStatus.inTransit.rawValue)
    }

    func testParcelWithSenderAndReceiver() {
        let sender = Customer(name: "Infosys Technologies")
        let receiver = Customer(name: "Wipro Limited")

        let parcel = Parcel(sender: sender, receiver: receiver)

        XCTAssertEqual(parcel.senderName, "Infosys Technologies")
        XCTAssertEqual(parcel.receiverName, "Wipro Limited")
    }
}
