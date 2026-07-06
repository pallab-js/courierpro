import Foundation
import SwiftData
import Combine

@MainActor
final class ParcelViewModel: ObservableObject {
    private let persistenceService: PersistenceService

    @Published var parcels: [Parcel] = []
    @Published var searchText: String = ""
    @Published var selectedStatus: DeliveryStatus?

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

    func loadParcels() throws {
        let descriptor = FetchDescriptor<Parcel>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        parcels = try persistenceService.fetch(descriptor)
    }

    func createParcel(
        sender: Customer,
        receiver: Customer,
        weight: Double,
        dimensions: String,
        notes: String?
    ) throws {
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
        try loadParcels()
    }

    func updateParcelStatus(_ parcel: Parcel, status: DeliveryStatus) throws {
        parcel.status = status
        parcel.updatedAt = Date()
        if status == .delivered {
            parcel.deliveredAt = Date()
        }
        try persistenceService.save()
        try loadParcels()
    }

    func deleteParcel(_ parcel: Parcel) throws {
        persistenceService.delete(parcel)
        try persistenceService.save()
        try loadParcels()
    }
}
