import Foundation
import SwiftData
import CloudKit

@MainActor
final class PersistenceService {
    static let shared = PersistenceService()

    static var inMemory: PersistenceService {
        PersistenceService(isInMemory: true)
    }

    let modelContainer: ModelContainer
    let modelContext: ModelContext
    private let isInMemory: Bool

    private init(isInMemory: Bool = false) {
        self.isInMemory = isInMemory
        let schema = Schema([
            Parcel.self,
            Customer.self,
            Driver.self,
            StatusHistory.self,
            Invoice.self,
            InvoiceItem.self,
            Payment.self,
            PricingRule.self
        ])

        let config: ModelConfiguration
        if isInMemory {
            config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: true
            )
        } else {
            config = ModelConfiguration(
                "CourierProDatabase",
                schema: schema,
                cloudKitDatabase: .automatic
            )
        }

        do {
            modelContainer = try ModelContainer(for: schema, configurations: [config])
            modelContext = modelContainer.mainContext
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }

    var isCloudKitAvailable: Bool {
        !isInMemory && NSUbiquitousKeyValueStore.default.bool(forKey: "cloudKitAvailable")
    }

    func save() throws {
        try modelContext.save()
    }

    func insert<T: PersistentModel>(_ object: T) {
        modelContext.insert(object)
    }

    func delete<T: PersistentModel>(_ object: T) {
        modelContext.delete(object)
    }

    func delete<T: PersistentModel>(_ objects: [T]) {
        for object in objects {
            modelContext.delete(object)
        }
    }

    func fetch<T: PersistentModel>(
        _ descriptor: FetchDescriptor<T>
    ) throws -> [T] {
        try modelContext.fetch(descriptor)
    }
}
