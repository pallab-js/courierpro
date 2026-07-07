import Foundation
import MapKit
import Combine
import SwiftData

struct RouteOptimizer {
    static func optimizeRoute(for parcels: [Parcel]) -> [Parcel] {
        guard parcels.count > 1 else { return parcels }

        let parcelsWithCoordinates = parcels.filter { parcel in
            parcel.sender?.hasCoordinates == true && parcel.receiver?.hasCoordinates == true
        }

        guard !parcelsWithCoordinates.isEmpty else { return parcels }

        var optimized: [Parcel] = []
        var remaining = parcelsWithCoordinates

        if let start = remaining.first {
            optimized.append(start)
            remaining.removeAll { $0.id == start.id }
        }

        while !remaining.isEmpty {
            guard let lastParcel = optimized.last,
                  let lastReceiver = lastParcel.receiver else { break }

            let nearest = remaining.min(by: { parcel1, parcel2 in
                let dist1 = distance(from: lastReceiver.coordinate, to: parcel1.sender?.coordinate ?? lastReceiver.coordinate)
                let dist2 = distance(from: lastReceiver.coordinate, to: parcel2.sender?.coordinate ?? lastReceiver.coordinate)
                return dist1 < dist2
            })

            if let nearest = nearest {
                optimized.append(nearest)
                remaining.removeAll { $0.id == nearest.id }
            } else {
                break
            }
        }

        let unoptimizedParcels = parcels.filter { parcel in
            !parcelsWithCoordinates.contains { $0.id == parcel.id }
        }

        return optimized + unoptimizedParcels
    }

    static func calculateTotalDistance(for parcels: [Parcel]) -> Double {
        var totalDistance: Double = 0
        for parcel in parcels {
            if let sender = parcel.sender, let receiver = parcel.receiver {
                totalDistance += distance(from: sender.coordinate, to: receiver.coordinate)
            }
        }
        return totalDistance
    }

    static func distance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation) / 1000
    }
}

struct DriverSchedule: Identifiable {
    let id = UUID()
    let driver: Driver
    var assignedParcels: [Parcel]
    var date: Date
    var isAvailable: Bool

    var totalDistance: Double {
        RouteOptimizer.calculateTotalDistance(for: assignedParcels)
    }

    var estimatedTime: TimeInterval {
        totalDistance * 120
    }
}

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
                let driverParcels = parcels.filter { $0.driver?.id == driver.id && $0.status != .delivered && $0.status != .failed }
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
        driver.isAvailable = false
        do {
            try persistenceService.save()
            loadSchedules()
        } catch {
            errorMessage = "Failed to assign parcel: \(error.localizedDescription)"
            showError = true
        }
    }

    func unassignParcel(_ parcel: Parcel) {
        let driver = parcel.driver
        parcel.driver = nil
        if let driver = driver {
            let hasOtherParcels = (driver.assignedParcels ?? []).contains { $0.id != parcel.id && $0.status != .delivered }
            driver.isAvailable = !hasOtherParcels
        }
        do {
            try persistenceService.save()
            loadSchedules()
        } catch {
            errorMessage = "Failed to unassign parcel: \(error.localizedDescription)"
            showError = true
        }
    }
}
