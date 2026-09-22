import Foundation
import SwiftData
import Combine

@MainActor
final class DriverScheduleViewModel: ObservableObject {
    private let persistenceService: PersistenceService

    @Published var schedules: [DriverSchedule] = []
    @Published var selectedDate = Date()
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false

    init(persistenceService: PersistenceService? = nil) {
        self.persistenceService = persistenceService ?? PersistenceService.shared
    }

    func loadSchedules() {
        isLoading = true
        defer { isLoading = false }

        do {
            let drivers = try persistenceService.fetch(FetchDescriptor<Driver>())
            let parcels = try persistenceService.fetch(FetchDescriptor<Parcel>())

            var result: [DriverSchedule] = []
            for driver in drivers {
                let driverParcels = parcels.filter { parcel in
                    parcel.driver?.id == driver.id &&
                    parcel.status != .delivered &&
                    parcel.status != .failed
                }
                let optimizedParcels = RouteOptimizer.optimizeRoute(for: driverParcels)
                let schedule = DriverSchedule(
                    driver: driver,
                    assignedParcels: optimizedParcels,
                    date: selectedDate,
                    isAvailable: driver.isAvailable
                )
                result.append(schedule)
            }
            schedules = result
        } catch {
            errorMessage = "Failed to load schedules: \(error.localizedDescription)"
            showError = true
        }
    }

    func assignParcel(_ parcel: Parcel, to driver: Driver) {
        parcel.driver = driver
        do {
            try persistenceService.save()
            loadSchedules()
        } catch {
            errorMessage = "Failed to assign parcel: \(error.localizedDescription)"
            showError = true
        }
    }

    func unassignParcel(_ parcel: Parcel) {
        parcel.driver = nil
        do {
            try persistenceService.save()
            loadSchedules()
        } catch {
            errorMessage = "Failed to unassign parcel: \(error.localizedDescription)"
            showError = true
        }
    }
}
