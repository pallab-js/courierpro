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
        _databaseError = State(initialValue: false)
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
                        try? DataSeeder.shared.seedSampleData(into: PersistenceService.shared.modelContext)
                    }
                    .modelContainer(PersistenceService.shared.modelContainer)
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

            CommandGroup(after: .toolbar) {
                Button("Dashboard") {
                    NotificationCenter.default.post(name: .navigateToDashboard, object: nil)
                }
                .keyboardShortcut("0", modifiers: .command)

                Button("Invoices") {
                    NotificationCenter.default.post(name: .navigateToInvoices, object: nil)
                }
                .keyboardShortcut("4", modifiers: .command)

                Button("Reports") {
                    NotificationCenter.default.post(name: .navigateToReports, object: nil)
                }
                .keyboardShortcut("5", modifiers: .command)

                Button("Settings") {
                    NotificationCenter.default.post(name: .navigateToSettings, object: nil)
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
    }
}

extension Notification.Name {
    static let navigateToDashboard = Notification.Name("com.courierpro.navigateToDashboard")
    static let navigateToParcels = Notification.Name("com.courierpro.navigateToParcels")
    static let navigateToCustomers = Notification.Name("com.courierpro.navigateToCustomers")
    static let navigateToDrivers = Notification.Name("com.courierpro.navigateToDrivers")
    static let navigateToInvoices = Notification.Name("com.courierpro.navigateToInvoices")
    static let navigateToReports = Notification.Name("com.courierpro.navigateToReports")
    static let navigateToSettings = Notification.Name("com.courierpro.navigateToSettings")
}
