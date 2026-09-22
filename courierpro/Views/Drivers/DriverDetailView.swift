import SwiftUI

struct DriverDetailView: View {
    let driver: Driver
    @StateObject private var viewModel = DriverViewModel()
    @State private var showingEditSheet = false
    @State private var showingDeleteConfirmation = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection
                actionsSection
                Divider()
                infoSection
                Divider()
                assignedParcelsSection
            }
            .padding()
        }
        .sheet(isPresented: $showingEditSheet) {
            DriverEditView(driver: driver, viewModel: viewModel)
        }
        .alert("Delete Driver", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                viewModel.deleteDriver(driver)
                if viewModel.errorMessage == nil {
                    dismiss()
                }
            }
        } message: {
            Text("Are you sure you want to delete driver \(driver.name)? This action cannot be undone.")
        }
        .errorAlert(isPresented: $viewModel.showError, message: viewModel.errorMessage)
    }

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(driver.name)
                    .font(.title)
                    .fontWeight(.bold)
                Text("License: \(driver.licenseNumber)")
                    .font(.subheadline)
                    .fontDesign(.monospaced)
                    .foregroundColor(.secondary)
            }
            Spacer()
            driverStatusBadge
        }
    }

    private var driverStatusBadge: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(driver.statusColor)
                .frame(width: 12, height: 12)
            Text(driver.statusLabel)
                .font(.headline)
                .foregroundColor(driver.statusColor)
        }
        .padding(10)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
    }

    private var actionsSection: some View {
        HStack(spacing: 12) {
            Button(action: { showingEditSheet = true }) {
                Label("Edit", systemImage: "pencil")
            }
            Button(role: .destructive, action: { showingDeleteConfirmation = true }) {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Contact Information")
                .font(.headline)

            Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 8) {
                GridRow {
                    Text("Phone:")
                        .foregroundColor(.secondary)
                    Text(driver.phone.isEmpty ? "Not provided" : driver.phone)
                }
                GridRow {
                    Text("License Number:")
                        .foregroundColor(.secondary)
                    Text(driver.licenseNumber)
                        .fontDesign(.monospaced)
                }
                GridRow {
                    Text("Status:")
                        .foregroundColor(.secondary)
                    Text(!driver.isAvailable ? "Unavailable" : (driver.isBusy ? "Currently busy" : "Available for dispatch"))
                }
                GridRow {
                    Text("Added:")
                        .foregroundColor(.secondary)
                    Text(driver.createdAt, style: .date)
                }
                GridRow {
                    Text("Last Updated:")
                        .foregroundColor(.secondary)
                    Text(driver.updatedAt, style: .date)
                }
            }
        }
    }

    private var assignedParcelsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Assigned Parcels")
                .font(.headline)

            if let parcels = driver.assignedParcels, !parcels.isEmpty {
                ForEach(parcels) { parcel in
                    HStack(spacing: 12) {
                        Image(systemName: parcel.status.systemImage)
                            .foregroundColor(parcel.status.color)
                            .frame(width: 20)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(parcel.trackingNumber)
                                .font(.system(.body, design: .monospaced))
                                .fontWeight(.medium)
                            Text("To: \(parcel.receiverName)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        StatusBadge(status: parcel.status)
                    }
                    .padding(.vertical, 4)
                }
            } else {
                EmptyStateView(
                    icon: "shippingbox",
                    title: "No Assigned Parcels",
                    message: "Parcels assigned to this driver will appear here"
                )
                .frame(maxWidth: .infinity, minHeight: 60)
            }
        }
    }
}

#Preview {
    DriverDetailView(driver: Driver(
        name: "John Smith",
        phone: "555-1001",
        licenseNumber: "DL-001"
    ))
    .frame(width: 600, height: 500)
}
