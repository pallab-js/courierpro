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

            if viewModel.filteredDrivers.isEmpty {
                VStack {
                    Image(systemName: "car.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No drivers found")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text("Add your first driver to get started")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                                try? viewModel.toggleAvailability(driver)
                            }
                            Divider()
                            Button("Delete", role: .destructive) {
                                try? viewModel.deleteDriver(driver)
                            }
                        }
                    }
                }
            }
        }
        .task {
            try? viewModel.loadDrivers()
        }
        .sheet(isPresented: $showingCreateSheet) {
            DriverFormView(viewModel: viewModel)
        }
        .sheet(item: $viewingDriver) { driver in
            DriverDetailView(driver: driver)
        }
    }
}

struct DriverRow: View {
    let driver: Driver
    let onSelect: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(driver.isAvailable ? Color.green : Color.orange)
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
                Text(driver.isAvailable ? "Available" : "Busy")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(driver.isAvailable ? .green : .orange)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            onSelect()
        }
    }
}

#Preview {
    DriverListView()
        .frame(width: 700, height: 500)
}
