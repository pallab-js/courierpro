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
    @State private var databaseError: Bool

    init() {
        if let service = PersistenceService.shared {
            _databaseError = State(initialValue: false)
        } else {
            _databaseError = State(initialValue: true)
        }
    }

    var body: some Scene {
        WindowGroup {
            if databaseError {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.red)
                    Text("Database Error")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("Failed to initialize the database. The app cannot function without it. Please restart or reinstall the app.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: 400)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ContentView()
                    .task {
                        if let context = PersistenceService.shared?.modelContext {
                            try? DataSeeder.shared.seedSampleData(into: context)
                        }
                    }
                    .modelContainer(PersistenceService.shared!.modelContainer)
            }
        }
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
