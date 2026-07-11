import Foundation
import SwiftData
import Combine

@MainActor
final class ParcelViewModel: ObservableObject {
    let persistenceService: PersistenceService

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

    var inTransitCount: Int {
        parcels.filter { $0.status == .inTransit }.count
    }

    var deliveredCount: Int {
        parcels.filter { $0.status == .delivered }.count
    }

    func loadParcels() {
        isLoading = true
        defer { isLoading = false }
        do {
            let descriptor = FetchDescriptor<Parcel>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
            parcels = try persistenceService.fetch(descriptor)
        } catch {
            errorMessage = "Failed to load parcels"
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
            guard sender.id != receiver.id else {
                errorMessage = "Sender and receiver must be different"
                showError = true
                return
            }
            guard weight.isFinite, weight >= 0 else {
                errorMessage = "Invalid weight value"
                showError = true
                return
            }

            let parcel = Parcel(
                status: .created,
                weight: weight,
                dimensions: String(dimensions.prefix(200)),
                notes: notes.map { String($0.prefix(1000)) },
                sender: sender,
                receiver: receiver
            )
            persistenceService.insert(parcel)
            try persistenceService.save()
            loadParcels()
        } catch {
            errorMessage = "Failed to create parcel"
            showError = true
        }
    }

    func updateParcelStatus(_ parcel: Parcel, status: DeliveryStatus) {
        do {
            let allowedTransitions: [DeliveryStatus: Set<DeliveryStatus>] = [
                .created: [.pickedUp],
                .pickedUp: [.inTransit],
                .inTransit: [.outForDelivery, .delivered, .failed],
                .outForDelivery: [.delivered, .failed],
                .delivered: [],
                .failed: [.created]
            ]

            guard let allowed = allowedTransitions[parcel.status], allowed.contains(status) else {
                errorMessage = "Cannot transition from \(parcel.status.displayName) to \(status.displayName)"
                showError = true
                return
            }

            parcel.status = status
            parcel.updatedAt = Date()
            if status == .delivered {
                parcel.deliveredAt = Date()
            }
            let history = StatusHistory(
                status: status,
                timestamp: Date(),
                notes: "Status updated to \(status.displayName)",
                updatedBy: "System",
                parcel: parcel
            )
            persistenceService.insert(history)
            try persistenceService.save()
            loadParcels()
        } catch {
            errorMessage = "Failed to update status"
            showError = true
        }
    }

    func deleteParcel(_ parcel: Parcel) {
        do {
            let descriptor = FetchDescriptor<InvoiceItem>()
            let allItems = try? persistenceService.fetch(descriptor)
            let linkedItems = allItems?.filter { item in
                item.parcel?.id == parcel.id
            }
            if let items = linkedItems, !items.isEmpty {
                errorMessage = "Cannot delete parcel linked to an invoice"
                showError = true
                return
            }

            persistenceService.delete(parcel)
            try persistenceService.save()
            loadParcels()
        } catch {
            errorMessage = "Failed to delete parcel"
            showError = true
        }
    }
}
