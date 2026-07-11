//
//  courierproApp.swift
//  courierpro
//
//  Created by Pallab Jyoti Sonowal on 06/07/26.
//

import SwiftUI
import SwiftData

@main
struct courierproApp: App {
    let persistenceService = PersistenceService.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    try? DataSeeder.shared.seedSampleData(into: persistenceService.modelContext)
                }
        }
        .modelContainer(persistenceService.modelContainer)
        .commands {
            CommandGroup(after: .newItem) {
                Button("New Parcel") {
                    NotificationCenter.default.post(name: .navigateToParcels, object: nil)
                }
                .keyboardShortcut("1", modifiers: .command)

                Button("New Customer") {
                    NotificationCenter.default.post(name: .navigateToCustomers, object: nil)
                }
                .keyboardShortcut("2", modifiers: .command)

                Button("New Driver") {
                    NotificationCenter.default.post(name: .navigateToDrivers, object: nil)
                }
                .keyboardShortcut("3", modifiers: .command)
            }
        }
    }
}

extension Notification.Name {
    static let navigateToParcels = Notification.Name("com.courierpro.navigateToParcels")
    static let navigateToCustomers = Notification.Name("com.courierpro.navigateToCustomers")
    static let navigateToDrivers = Notification.Name("com.courierpro.navigateToDrivers")
}
