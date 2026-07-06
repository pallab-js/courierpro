import Foundation
import SwiftData

@MainActor
final class DataSeeder {
    static let shared = DataSeeder()

    private init() {}

    func seedSampleData(into context: ModelContext) throws {
        let customerFetch = FetchDescriptor<Customer>()
        let existingCustomers = try context.fetch(customerFetch)
        guard existingCustomers.isEmpty else { return }

        let customers = [
            Customer(name: "Acme Corp", email: "info@acme.com", phone: "555-0101", address: "123 Business St", city: "San Francisco", postalCode: "94102", latitude: 37.7749, longitude: -122.4194),
            Customer(name: "TechStart Inc", email: "hello@techstart.io", phone: "555-0102", address: "456 Innovation Ave", city: "San Jose", postalCode: "95112", latitude: 37.3382, longitude: -121.8863),
            Customer(name: "Global Logistics", email: "ops@globallog.com", phone: "555-0103", address: "789 Shipping Blvd", city: "Oakland", postalCode: "94601", latitude: 37.8044, longitude: -122.2712),
            Customer(name: "Quick Deliver", email: "service@quickdel.com", phone: "555-0104", address: "321 Express Way", city: "Berkeley", postalCode: "94704", latitude: 37.8716, longitude: -122.2727),
            Customer(name: "Retail Plus", email: "orders@retailplus.com", phone: "555-0105", address: "654 Commerce Dr", city: "Palo Alto", postalCode: "94301", latitude: 37.4419, longitude: -122.1430),
        ]

        for customer in customers {
            context.insert(customer)
        }

        let drivers = [
            Driver(name: "John Smith", phone: "555-1001", licenseNumber: "DL-001"),
            Driver(name: "Maria Garcia", phone: "555-1002", licenseNumber: "DL-002"),
            Driver(name: "David Chen", phone: "555-1003", licenseNumber: "DL-003"),
        ]

        for driver in drivers {
            context.insert(driver)
        }

        let parcels = [
            Parcel(trackingNumber: "CP-000001", status: .created, weight: 2.5, dimensions: "30x20x15 cm", sender: customers[0], receiver: customers[1]),
            Parcel(trackingNumber: "CP-000002", status: .pickedUp, weight: 5.0, dimensions: "40x30x25 cm", sender: customers[1], receiver: customers[2], driver: drivers[0]),
            Parcel(trackingNumber: "CP-000003", status: .inTransit, weight: 1.2, dimensions: "20x15x10 cm", sender: customers[2], receiver: customers[3], driver: drivers[1]),
            Parcel(trackingNumber: "CP-000004", status: .outForDelivery, weight: 8.0, dimensions: "50x40x35 cm", sender: customers[3], receiver: customers[4], driver: drivers[2]),
            Parcel(trackingNumber: "CP-000005", status: .delivered, weight: 3.0, dimensions: "25x20x20 cm", sender: customers[4], receiver: customers[0], driver: drivers[0], deliveredAt: Date()),
        ]

        for parcel in parcels {
            context.insert(parcel)
        }

        try context.save()
    }
}
