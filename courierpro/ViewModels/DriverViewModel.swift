import Foundation
import SwiftData
import Combine

@MainActor
final class DriverViewModel: ObservableObject {
    private let persistenceService: PersistenceService

    @Published var drivers: [Driver] = []
    @Published var searchText: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false

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

    func loadDrivers() {
        isLoading = true
        defer { isLoading = false }
        do {
            let descriptor = FetchDescriptor<Driver>(sortBy: [SortDescriptor(\.name)])
            drivers = try persistenceService.fetch(descriptor)
        } catch {
            errorMessage = "Failed to load drivers: \(error.localizedDescription)"
            showError = true
        }
    }

    func createDriver(
        name: String,
        phone: String,
        licenseNumber: String,
        isAvailable: Bool = true
    ) {
        do {
            let driver = Driver(
                name: name,
                phone: phone,
                licenseNumber: licenseNumber,
                isAvailable: isAvailable
            )
            persistenceService.insert(driver)
            try persistenceService.save()
            loadDrivers()
        } catch {
            errorMessage = "Failed to create driver: \(error.localizedDescription)"
            showError = true
        }
    }

    func updateDriver(
        _ driver: Driver,
        name: String,
        phone: String,
        licenseNumber: String,
        isAvailable: Bool
    ) {
        do {
            driver.name = name
            driver.phone = phone
            driver.licenseNumber = licenseNumber
            driver.isAvailable = isAvailable
            driver.updatedAt = Date()
            try persistenceService.save()
            loadDrivers()
        } catch {
            errorMessage = "Failed to update driver: \(error.localizedDescription)"
            showError = true
        }
    }

    func toggleAvailability(_ driver: Driver) {
        do {
            driver.isAvailable.toggle()
            driver.updatedAt = Date()
            try persistenceService.save()
            loadDrivers()
        } catch {
            errorMessage = "Failed to update availability: \(error.localizedDescription)"
            showError = true
        }
    }

    func deleteDriver(_ driver: Driver) {
        do {
            persistenceService.delete(driver)
            try persistenceService.save()
            loadDrivers()
        } catch {
            errorMessage = "Failed to delete driver: \(error.localizedDescription)"
            showError = true
        }
    }
}
