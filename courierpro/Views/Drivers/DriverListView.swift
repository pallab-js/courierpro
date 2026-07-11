import SwiftUI

struct DriverListView: View {
    @StateObject private var viewModel = DriverViewModel()
    @State private var showingCreateSheet = false
    @State private var viewingDriver: Driver?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Drivers")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Spacer()
                Button(action: { showingCreateSheet = true }) {
                    Label("New Driver", systemImage: "plus")
                }
            }
            .padding()

            Divider()

            HStack {
                SearchField(text: $viewModel.searchText, placeholder: "Search drivers...")
                Spacer()
                Text("\(viewModel.availableDrivers.count) available")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

            if viewModel.isLoading {
                LoadingView()
            } else if viewModel.filteredDrivers.isEmpty {
                EmptyStateView(
                    icon: "car.fill",
                    title: viewModel.drivers.isEmpty ? "No Drivers Yet" : "No Drivers Found",
                    message: viewModel.drivers.isEmpty
                        ? "Add your first driver to start assigning deliveries"
                        : "Try adjusting your search criteria",
                    actionTitle: viewModel.drivers.isEmpty ? "Add Driver" : nil,
                    action: viewModel.drivers.isEmpty ? { showingCreateSheet = true } : nil
                )
            } else {
                List {
                    ForEach(viewModel.filteredDrivers) { driver in
                        DriverRow(driver: driver) {
                            viewingDriver = driver
                        }
                        .contextMenu {
                            Button("View Details") {
                                viewingDriver = driver
                            }
                            Button(driver.isAvailable ? "Mark Unavailable" : "Mark Available") {
                                viewModel.toggleAvailability(driver)
                            }
                            Divider()
                            Button("Delete", role: .destructive) {
                                viewModel.deleteDriver(driver)
                            }
                        }
                    }
                }
            }
        }
        .task {
            viewModel.loadDrivers()
        }
        .sheet(isPresented: $showingCreateSheet) {
            DriverFormView(viewModel: viewModel)
        }
        .sheet(item: $viewingDriver) { driver in
            DriverDetailView(driver: driver)
        }
        .errorAlert(isPresented: $viewModel.showError, message: viewModel.errorMessage)
    }
}

struct DriverRow: View {
    let driver: Driver
    let onSelect: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(!driver.isAvailable ? Color.red : (driver.isBusy ? Color.orange : Color.green))
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(driver.name)
                    .font(.body)
                    .fontWeight(.medium)
                Text("License: \(driver.licenseNumber)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                if !driver.phone.isEmpty {
                    Label(driver.phone, systemImage: "phone")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Text(!driver.isAvailable ? "Unavailable" : (driver.isBusy ? "Busy" : "Available"))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(!driver.isAvailable ? .red : (driver.isBusy ? .orange : .green))
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
    }
}

#Preview {
    DriverListView()
        .frame(width: 700, height: 500)
}
