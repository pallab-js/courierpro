import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var selectedItem: NavigationItem? = .dashboard
    @Environment(\.modelContext) private var modelContext
    @State private var showingImportSheet = false
    @State private var importType: ImportType = .customers

    enum ImportType {
        case customers
        case drivers
    }

    var body: some View {
        NavigationSplitView {
            SidebarView(selectedItem: $selectedItem)
        } detail: {
            switch selectedItem {
            case .dashboard:
                DashboardView()
            case .parcels:
                ParcelListView()
            case .customers:
                CustomerListView()
            case .drivers:
                DriverListView()
            case .invoices:
                InvoiceListView()
            case .pricing:
                PricingRuleListView()
            case .reports:
                ReportsView()
            case .map:
                DeliveryMapView()
            case .none:
                Text("Select an item from the sidebar")
                    .foregroundColor(.secondary)
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Menu {
                    Button("Export Parcels") { exportParcels() }
                    Button("Export Customers") { exportCustomers() }
                    Button("Export Drivers") { exportDrivers() }
                    Divider()
                    Button("Import Customers") {
                        importType = .customers
                        showingImportSheet = true
                    }
                    Button("Import Drivers") {
                        importType = .drivers
                        showingImportSheet = true
                    }
                } label: {
                    Label("Import/Export", systemImage: "arrow.up.arrow.down")
                }
            }
        }
        .fileImporter(
            isPresented: $showingImportSheet,
            allowedContentTypes: [.commaSeparatedText, .text]
        ) { result in
            handleImport(result)
        }
    }

    private func exportParcels() {
        let descriptor = FetchDescriptor<Parcel>()
        guard let parcels = try? modelContext.fetch(descriptor) else { return }
        let csv = CSVExporter.exportParcels(parcels)
        saveToDownloads(csv, filename: "parcels_export.csv")
    }

    private func exportCustomers() {
        let descriptor = FetchDescriptor<Customer>()
        guard let customers = try? modelContext.fetch(descriptor) else { return }
        let csv = CSVExporter.exportCustomers(customers)
        saveToDownloads(csv, filename: "customers_export.csv")
    }

    private func exportDrivers() {
        let descriptor = FetchDescriptor<Driver>()
        guard let drivers = try? modelContext.fetch(descriptor) else { return }
        let csv = CSVExporter.exportDrivers(drivers)
        saveToDownloads(csv, filename: "drivers_export.csv")
    }

    private func handleImport(_ result: Result<URL, Error>) {
        guard let url = try? result.get(),
              let data = try? Data(contentsOf: url),
              let csv = String(data: data, encoding: .utf8) else { return }

        switch importType {
        case .customers:
            let customers = CSVImporter.importCustomers(from: csv)
            for customer in customers {
                modelContext.insert(customer)
            }
        case .drivers:
            let drivers = CSVImporter.importDrivers(from: csv)
            for driver in drivers {
                modelContext.insert(driver)
            }
        }
        try? modelContext.save()
    }

    private func saveToDownloads(_ content: String, filename: String) {
        guard let downloads = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first else { return }
        let url = downloads.appendingPathComponent(filename)
        try? content.write(to: url, atomically: true, encoding: .utf8)
    }
}

#Preview {
    ContentView()
}
