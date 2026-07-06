import Foundation
import SwiftData
import Combine

@MainActor
final class DriverViewModel: ObservableObject {
    private let persistenceService: PersistenceService

    @Published var drivers: [Driver] = []
    @Published var searchText: String = ""

    init(persistenceService: PersistenceService? = nil) {
        self.persistenceService = persistenceService ?? PersistenceService.shared
    }

    var filteredDrivers: [Driver] {
        if searchText.isEmpty {
            return drivers
        }
        return drivers.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.licenseNumber.localizedCaseInsensitiveContains(searchText)
        }
    }

    var availableDrivers: [Driver] {
        drivers.filter { $0.isAvailable }
    }

    var busyDrivers: [Driver] {
        drivers.filter { !$0.isAvailable }
    }

    func loadDrivers() throws {
        let descriptor = FetchDescriptor<Driver>(sortBy: [SortDescriptor(\.name)])
        drivers = try persistenceService.fetch(descriptor)
    }

    func createDriver(
        name: String,
        phone: String,
        licenseNumber: String,
        isAvailable: Bool = true
    ) throws {
        let driver = Driver(
            name: name,
            phone: phone,
            licenseNumber: licenseNumber,
            isAvailable: isAvailable
        )
        persistenceService.insert(driver)
        try persistenceService.save()
        try loadDrivers()
    }

    func updateDriver(
        _ driver: Driver,
        name: String,
        phone: String,
        licenseNumber: String,
        isAvailable: Bool
    ) throws {
        driver.name = name
        driver.phone = phone
        driver.licenseNumber = licenseNumber
        driver.isAvailable = isAvailable
        driver.updatedAt = Date()
        try persistenceService.save()
        try loadDrivers()
    }

    func toggleAvailability(_ driver: Driver) throws {
        driver.isAvailable.toggle()
        driver.updatedAt = Date()
        try persistenceService.save()
        try loadDrivers()
    }

    func deleteDriver(_ driver: Driver) throws {
        persistenceService.delete(driver)
        try persistenceService.save()
        try loadDrivers()
    }
}
