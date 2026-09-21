import XCTest
@testable import courierpro
import CoreLocation

@MainActor
final class RouteOptimizerTests: XCTestCase {
    private var persistenceService: PersistenceService!

    override func setUp() {
        super.setUp()
        persistenceService = PersistenceService.inMemory
    }

    override func tearDown() {
        persistenceService = nil
        super.tearDown()
    }

    func testDistanceCalculation() {
        let bangalore = CLLocationCoordinate2D(latitude: 12.9716, longitude: 77.5946)
        let chennai = CLLocationCoordinate2D(latitude: 13.0827, longitude: 80.2707)

        let distance = RouteOptimizer.distance(from: bangalore, to: chennai)

        XCTAssertGreaterThan(distance, 250)
        XCTAssertLessThan(distance, 350)
    }

    func testDistanceInvalidCoordinates() {
        let invalid = CLLocationCoordinate2D(latitude: Double.greatestFiniteMagnitude, longitude: 0)
        let valid = CLLocationCoordinate2D(latitude: 12.9716, longitude: 77.5946)

        let distance = RouteOptimizer.distance(from: invalid, to: valid)
        XCTAssertEqual(distance, Double.greatestFiniteMagnitude)
    }

    func testOptimizeRouteSingleParcel() {
        let sender = Customer(name: "A", latitude: 12.9716, longitude: 77.5946)
        let receiver = Customer(name: "B", latitude: 13.0827, longitude: 80.2707)
        let parcel = Parcel(weight: 1.0, sender: sender, receiver: receiver)

        let optimized = RouteOptimizer.optimizeRoute(for: [parcel])
        XCTAssertEqual(optimized.count, 1)
        XCTAssertEqual(optimized.first?.id, parcel.id)
    }

    func testOptimizeRouteEmpty() {
        let optimized = RouteOptimizer.optimizeRoute(for: [])
        XCTAssertTrue(optimized.isEmpty)
    }

    func testOptimizeRouteReordersByProximity() {
        let warehouse = Customer(name: "Warehouse", latitude: 12.9716, longitude: 77.5946)
        let nearby = Customer(name: "Nearby", latitude: 12.98, longitude: 77.60)
        let faraway = Customer(name: "Far", latitude: 13.08, longitude: 80.27)

        let parcel1 = Parcel(weight: 1.0, sender: warehouse, receiver: faraway)
        let parcel2 = Parcel(weight: 1.0, sender: warehouse, receiver: nearby)

        let optimized = RouteOptimizer.optimizeRoute(for: [parcel1, parcel2])

        XCTAssertEqual(optimized.count, 2)
        XCTAssertEqual(optimized.first?.id, parcel1.id)
        XCTAssertEqual(optimized.last?.id, parcel2.id)
    }

    func testOptimizeRouteHandlesParcelsWithoutCoordinates() {
        let warehouse = Customer(name: "Warehouse", latitude: 12.9716, longitude: 77.5946)
        let withCoords = Customer(name: "Delivery", latitude: 12.98, longitude: 77.60)
        let noCoords = Customer(name: "No Coords")

        let parcel1 = Parcel(weight: 1.0, sender: warehouse, receiver: withCoords)
        let parcel2 = Parcel(weight: 1.0, sender: warehouse, receiver: noCoords)

        let optimized = RouteOptimizer.optimizeRoute(for: [parcel1, parcel2])
        XCTAssertEqual(optimized.count, 2)
    }

    func testCalculateTotalDistance() {
        let sender1 = Customer(name: "S1", latitude: 12.9716, longitude: 77.5946)
        let receiver1 = Customer(name: "R1", latitude: 13.0827, longitude: 80.2707)
        let sender2 = Customer(name: "S2", latitude: 19.0760, longitude: 72.8777)
        let receiver2 = Customer(name: "R2", latitude: 28.6139, longitude: 77.2090)

        let parcel1 = Parcel(weight: 1.0, sender: sender1, receiver: receiver1)
        let parcel2 = Parcel(weight: 1.0, sender: sender2, receiver: receiver2)

        let total = RouteOptimizer.calculateTotalDistance(for: [parcel1, parcel2])
        XCTAssertGreaterThan(total, 0)
    }
}
