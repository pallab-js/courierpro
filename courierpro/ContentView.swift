import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var selectedItem: NavigationItem? = .dashboard
    @Environment(\.modelContext) private var modelContext
    @State private var showingImportSheet = false
    @State private var importType: ImportType = .customers
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isProcessing = false
    @State private var showingSuccess = false
    @State private var successMessage = ""

    enum ImportType {
        case customers
        case drivers
    }

    var body: some View {
        NavigationSplitView {
            SidebarView(selectedItem: $selectedItem)
                .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 280)
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
            case .driverSchedule:
                DriverScheduleView()
            case .invoices:
                InvoiceListView()
            case .recurringInvoices:
                RecurringInvoiceListView()
            case .pricing:
                PricingRuleListView()
            case .reports:
                ReportsView()
            case .map:
                DeliveryMapView()
            case .settings:
                SettingsView()
            case .none:
                Text("Select an item from the sidebar")
                    .foregroundColor(.secondary)
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .onReceive(NotificationCenter.default.publisher(for: .navigateToParcels)) { _ in
            selectedItem = .parcels
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToCustomers)) { _ in
            selectedItem = .customers
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToDrivers)) { _ in
            selectedItem = .drivers
        }
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
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .alert("Success", isPresented: $showingSuccess) {
            Button("OK") { }
        } message: {
            Text(successMessage)
        }
        .overlay {
            if isProcessing {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    VStack(spacing: 12) {
                        ProgressView()
                            .controlSize(.large)
                        Text("Processing...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(24)
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                }
            }
        }
    }

    private func exportParcels() {
        isProcessing = true
        Task {
            do {
                let descriptor = FetchDescriptor<Parcel>()
                let parcels = try modelContext.fetch(descriptor)
                let csv = CSVExporter.exportParcels(parcels)
                saveToDownloads(csv, filename: "parcels_export.csv")
                successMessage = "Parcels exported successfully"
                showingSuccess = true
            } catch {
                errorMessage = "Failed to export parcels: \(error.localizedDescription)"
                showingError = true
            }
            isProcessing = false
        }
    }

    private func exportCustomers() {
        isProcessing = true
        Task {
            do {
                let descriptor = FetchDescriptor<Customer>()
                let customers = try modelContext.fetch(descriptor)
                let csv = CSVExporter.exportCustomers(customers)
                saveToDownloads(csv, filename: "customers_export.csv")
                successMessage = "Customers exported successfully"
                showingSuccess = true
            } catch {
                errorMessage = "Failed to export customers: \(error.localizedDescription)"
                showingError = true
            }
            isProcessing = false
        }
    }

    private func exportDrivers() {
        isProcessing = true
        Task {
            do {
                let descriptor = FetchDescriptor<Driver>()
                let drivers = try modelContext.fetch(descriptor)
                let csv = CSVExporter.exportDrivers(drivers)
                saveToDownloads(csv, filename: "drivers_export.csv")
                successMessage = "Drivers exported successfully"
                showingSuccess = true
            } catch {
                errorMessage = "Failed to export drivers: \(error.localizedDescription)"
                showingError = true
            }
            isProcessing = false
        }
    }

    private func handleImport(_ result: Result<URL, Error>) {
        guard let url = try? result.get() else { return }

        guard let fileSize = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize,
              fileSize <= 10_000_000 else {
            errorMessage = "File too large (max 10MB)"
            showingError = true
            return
        }

        guard let data = try? Data(contentsOf: url),
              let csv = String(data: data, encoding: .utf8) else {
            errorMessage = "Failed to read file"
            showingError = true
            return
        }

        isProcessing = true
        Task {
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
            do {
                try modelContext.save()
                successMessage = "Data imported successfully"
                showingSuccess = true
            } catch {
                errorMessage = "Failed to save imported data: \(error.localizedDescription)"
                showingError = true
            }
            isProcessing = false
        }
    }

    private func saveToDownloads(_ content: String, filename: String) {
        guard let downloads = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first else {
            errorMessage = "Could not access Downloads directory"
            showingError = true
            return
        }
        let url = downloads.appendingPathComponent(filename)
        do {
            try content.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            errorMessage = "Failed to save file: \(error.localizedDescription)"
            showingError = true
        }
    }
}

#Preview {
    ContentView()
}
