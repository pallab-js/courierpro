import SwiftUI

struct ParcelDetailView: View {
    let parcel: Parcel
    @StateObject private var viewModel = ParcelViewModel()
    @State private var showingEditSheet = false
    @State private var showingDeleteConfirmation = false
    @State private var showingStatusUpdate = false
    @State private var showingDriverAssignment = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection
                Divider()
                statusSection
                Divider()
                detailsSection
                Divider()
                contactsSection
                Divider()
                statusHistorySection
            }
            .padding()
        }
        .navigationTitle(parcel.trackingNumber)
        .toolbar {
            ToolbarItemGroup {
                Button(action: { showingStatusUpdate = true }) {
                    Label("Update Status", systemImage: "arrow.triangle.2.circlepath")
                }
                Button(action: { showingDriverAssignment = true }) {
                    Label("Assign Driver", systemImage: "car.fill")
                }
                Button(action: { showingEditSheet = true }) {
                    Label("Edit", systemImage: "pencil")
                }
                Button(action: { showingDeleteConfirmation = true }) {
                    Label("Delete", systemImage: "trash")
                }
                .foregroundColor(.red)
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            ParcelEditView(parcel: parcel, viewModel: viewModel)
        }
        .sheet(isPresented: $showingDriverAssignment) {
            DriverAssignmentView(parcel: parcel)
        }
        .sheet(isPresented: $showingStatusUpdate) {
            StatusUpdateView(parcel: parcel, viewModel: viewModel)
        }
        .alert("Delete Parcel", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                try? viewModel.deleteParcel(parcel)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete parcel \(parcel.trackingNumber)? This action cannot be undone.")
        }
    }

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(parcel.trackingNumber)
                    .font(.title)
                    .fontWeight(.bold)
                    .fontDesign(.monospaced)
                Text("Created \(parcel.createdAt, style: .date)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            StatusBadge(status: parcel.status)
                .scaleEffect(1.2)
        }
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Status")
                .font(.headline)

            HStack(spacing: 16) {
                StatusTimelineItem(
                    status: .created,
                    currentStatus: parcel.status,
                    title: "Created"
                )
                StatusTimelineItem(
                    status: .pickedUp,
                    currentStatus: parcel.status,
                    title: "Picked Up"
                )
                StatusTimelineItem(
                    status: .inTransit,
                    currentStatus: parcel.status,
                    title: "In Transit"
                )
                StatusTimelineItem(
                    status: .outForDelivery,
                    currentStatus: parcel.status,
                    title: "Out for Delivery"
                )
                StatusTimelineItem(
                    status: .delivered,
                    currentStatus: parcel.status,
                    title: "Delivered"
                )
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(10)
        }
    }

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Details")
                .font(.headline)

            Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 8) {
                GridRow {
                    Text("Weight:")
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f kg", parcel.weight))
                }
                GridRow {
                    Text("Dimensions:")
                        .foregroundColor(.secondary)
                    Text(parcel.dimensions.isEmpty ? "Not specified" : parcel.dimensions)
                }
                GridRow {
                    Text("Driver:")
                        .foregroundColor(.secondary)
                    Text(parcel.driverName)
                }
                if let notes = parcel.notes, !notes.isEmpty {
                    GridRow {
                        Text("Notes:")
                            .foregroundColor(.secondary)
                        Text(notes)
                    }
                }
                GridRow {
                    Text("Last Updated:")
                        .foregroundColor(.secondary)
                    Text(parcel.updatedAt, style: .date)
                }
                if let deliveredAt = parcel.deliveredAt {
                    GridRow {
                        Text("Delivered:")
                            .foregroundColor(.secondary)
                        Text(deliveredAt, style: .date)
                    }
                }
            }
        }
    }

    private var contactsSection: some View {
        HStack(alignment: .top, spacing: 40) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Sender")
                    .font(.headline)
                if let sender = parcel.sender {
                    ContactCard(customer: sender)
                } else {
                    Text("No sender assigned")
                        .foregroundColor(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Receiver")
                    .font(.headline)
                if let receiver = parcel.receiver {
                    ContactCard(customer: receiver)
                } else {
                    Text("No receiver assigned")
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
    }

    private var statusHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Status History")
                .font(.headline)

            if let history = parcel.statusHistory?.sorted(by: { $0.timestamp > $1.timestamp }),
               !history.isEmpty {
                ForEach(history) { entry in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: entry.status.systemImage)
                            .foregroundColor(statusColor(entry.status))
                            .frame(width: 20)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.status.displayName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(entry.timestamp, style: .date)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            if let notes = entry.notes, !notes.isEmpty {
                                Text(notes)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            if let updatedBy = entry.updatedBy, !updatedBy.isEmpty {
                                Text("by \(updatedBy)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            } else {
                Text("No status history available")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 60)
            }
        }
    }

    private func statusColor(_ status: DeliveryStatus) -> Color {
        switch status {
        case .created: return .blue
        case .pickedUp: return .orange
        case .inTransit: return .purple
        case .outForDelivery: return .yellow
        case .delivered: return .green
        case .failed: return .red
        }
    }
}

struct StatusTimelineItem: View {
    let status: DeliveryStatus
    let currentStatus: DeliveryStatus
    let title: String

    private var isCompleted: Bool {
        currentStatus.rawValue >= status.rawValue
    }

    private var isCurrent: Bool {
        currentStatus == status
    }

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(isCompleted ? statusColor : Color.gray.opacity(0.3))
                    .frame(width: 24, height: 24)
                if isCompleted {
                    Image(systemName: isCurrent ? status.systemImage : "checkmark")
                        .font(.caption)
                        .foregroundColor(.white)
                }
            }
            Text(title)
                .font(.caption2)
                .foregroundColor(isCompleted ? .primary : .secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var statusColor: Color {
        switch status {
        case .created: return .blue
        case .pickedUp: return .orange
        case .inTransit: return .purple
        case .outForDelivery: return .yellow
        case .delivered: return .green
        case .failed: return .red
        }
    }
}

struct ContactCard: View {
    let customer: Customer

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(customer.name)
                .font(.subheadline)
                .fontWeight(.medium)
            if !customer.email.isEmpty {
                Label(customer.email, systemImage: "envelope")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            if !customer.phone.isEmpty {
                Label(customer.phone, systemImage: "phone")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            if !customer.shortAddress.isEmpty {
                Label(customer.shortAddress, systemImage: "mappin.and.ellipse")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(10)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

#Preview {
    ParcelDetailView(parcel: Parcel(
        trackingNumber: "CP-123456",
        status: .inTransit,
        weight: 2.5,
        dimensions: "30x20x15 cm",
        sender: Customer(name: "Sender Corp"),
        receiver: Customer(name: "Receiver Inc")
    ))
    .frame(width: 600, height: 700)
}
