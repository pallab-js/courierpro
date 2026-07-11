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
            Customer(name: "Reliance Retail", email: "orders@reliance.in", phone: "9876543210", address: "Maker Chambers IV, 222 Nariman Point", city: "Mumbai", postalCode: "400021", latitude: 18.9220, longitude: 72.8347),
            Customer(name: "Tata Steel Ltd", email: "logistics@tatasteel.com", phone: "9876543211", address: "Bistupur, Jamshedpur", city: "Jamshedpur", postalCode: "831001", latitude: 22.8046, longitude: 86.2029),
            Customer(name: "Infosys Technologies", email: "supply@infosys.com", phone: "9876543212", address: "Electronics City, Hosur Road", city: "Bangalore", postalCode: "560100", latitude: 12.8456, longitude: 77.6603),
            Customer(name: "Wipro Limited", email: "procurement@wipro.com", phone: "9876543213", address: "Doddakannelli, Sarjapur Road", city: "Bangalore", postalCode: "560035", latitude: 12.9121, longitude: 77.6446),
            Customer(name: "HDFC Bank", email: "operations@hdfcbank.com", phone: "9876543214", address: "HDFC Bank House, Senapati Bapat Marg", city: "Pune", postalCode: "411013", latitude: 18.5309, longitude: 73.8475),
        ]

        for customer in customers {
            context.insert(customer)
        }

        let drivers = [
            Driver(name: "Rajesh Kumar", phone: "9876500001", licenseNumber: "DL-MH-001"),
            Driver(name: "Priya Sharma", phone: "9876500002", licenseNumber: "DL-KA-002"),
            Driver(name: "Amit Patel", phone: "9876500003", licenseNumber: "DL-GJ-003"),
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
