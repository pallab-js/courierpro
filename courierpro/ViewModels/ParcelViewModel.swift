import Foundation
import SwiftData
import Combine

@MainActor
final class ParcelViewModel: ObservableObject {
    private let persistenceService: PersistenceService

    @Published var parcels: [Parcel] = []
    @Published var searchText: String = ""
    @Published var selectedStatus: DeliveryStatus?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false

    init(persistenceService: PersistenceService? = nil) {
        self.persistenceService = persistenceService ?? PersistenceService.shared
    }

    var filteredParcels: [Parcel] {
        var results = parcels

        if let status = selectedStatus {
            results = results.filter { $0.status == status }
        }

        if !searchText.isEmpty {
            results = results.filter {
                $0.trackingNumber.localizedCaseInsensitiveContains(searchText) ||
                $0.senderName.localizedCaseInsensitiveContains(searchText) ||
                $0.receiverName.localizedCaseInsensitiveContains(searchText)
            }
        }

        return results
    }

    var parcelCountByStatus: [DeliveryStatus: Int] {
        Dictionary(grouping: parcels, by: \.status).mapValues { $0.count }
    }

    func loadParcels() {
        isLoading = true
        defer { isLoading = false }
        do {
            let descriptor = FetchDescriptor<Parcel>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
            parcels = try persistenceService.fetch(descriptor)
        } catch {
            errorMessage = "Failed to load parcels: \(error.localizedDescription)"
            showError = true
        }
    }

    func createParcel(
        sender: Customer,
        receiver: Customer,
        weight: Double,
        dimensions: String,
        notes: String?
    ) {
        do {
            let parcel = Parcel(
                status: .created,
                weight: weight,
                dimensions: dimensions,
                notes: notes,
                sender: sender,
                receiver: receiver
            )
            persistenceService.insert(parcel)
            try persistenceService.save()
            loadParcels()
        } catch {
            errorMessage = "Failed to create parcel: \(error.localizedDescription)"
            showError = true
        }
    }

    func updateParcelStatus(_ parcel: Parcel, status: DeliveryStatus) {
        do {
            parcel.status = status
            parcel.updatedAt = Date()
            if status == .delivered {
                parcel.deliveredAt = Date()
            }
            try persistenceService.save()
            loadParcels()
        } catch {
            errorMessage = "Failed to update status: \(error.localizedDescription)"
            showError = true
        }
    }

    func deleteParcel(_ parcel: Parcel) {
        do {
            persistenceService.delete(parcel)
            try persistenceService.save()
            loadParcels()
        } catch {
            errorMessage = "Failed to delete parcel: \(error.localizedDescription)"
            showError = true
        }
    }
}
