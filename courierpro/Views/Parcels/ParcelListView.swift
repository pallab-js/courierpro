import SwiftUI

struct ParcelListView: View {
    @StateObject private var viewModel = ParcelViewModel()
    @State private var showingCreateSheet = false
    @State private var viewingParcel: Parcel?
    @State private var statusUpdateConfirmation: (parcel: Parcel, status: DeliveryStatus)?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Parcels")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Spacer()
                Button(action: { showingCreateSheet = true }) {
                    Label("New Parcel", systemImage: "plus")
                }
            }
            .padding()

            Divider()

            HStack {
                SearchField(text: $viewModel.searchText, placeholder: "Search parcels...")
                Picker("Status", selection: $viewModel.selectedStatus) {
                    Text("All Statuses").tag(nil as DeliveryStatus?)
                    ForEach(DeliveryStatus.allCases) { status in
                        Text(status.displayName).tag(status as DeliveryStatus?)
                    }
                }
                .frame(width: 150)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

            if viewModel.isLoading {
                LoadingView()
            } else if viewModel.filteredParcels.isEmpty {
                EmptyStateView(
                    icon: "shippingbox",
                    title: viewModel.parcels.isEmpty ? "No Parcels Yet" : "No Parcels Found",
                    message: viewModel.parcels.isEmpty
                        ? "Create your first parcel to start tracking deliveries"
                        : "Try adjusting your search or filter criteria",
                    actionTitle: viewModel.parcels.isEmpty ? "Create Parcel" : nil,
                    action: viewModel.parcels.isEmpty ? { showingCreateSheet = true } : nil
                )
            } else {
                List {
                    ForEach(viewModel.filteredParcels) { parcel in
                        ParcelRow(parcel: parcel) {
                            viewingParcel = parcel
                        }
                        .contextMenu {
                            Button("View Details") {
                                viewingParcel = parcel
                            }
                            Button("Mark as Picked Up") {
                                viewModel.updateParcelStatus(parcel, status: .pickedUp)
                            }
                            Button("Mark as In Transit") {
                                viewModel.updateParcelStatus(parcel, status: .inTransit)
                            }
                            Button("Mark as Delivered") {
                                viewModel.updateParcelStatus(parcel, status: .delivered)
                            }
                            Divider()
                            Button("Delete", role: .destructive) {
                                viewModel.deleteParcel(parcel)
                            }
                        }
                    }
                }
            }
        }
        .task {
            viewModel.loadParcels()
        }
        .sheet(isPresented: $showingCreateSheet) {
            ParcelFormView(viewModel: viewModel)
        }
        .sheet(item: $viewingParcel) { parcel in
            ParcelDetailView(parcel: parcel)
        }
        .errorAlert(isPresented: $viewModel.showError, message: viewModel.errorMessage)
    }
}

struct ParcelRow: View {
    let parcel: Parcel
    let onSelect: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(parcel.trackingNumber)
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.medium)
                Text("Sender: \(parcel.senderName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            StatusBadge(status: parcel.status)
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.1f kg", parcel.weight))
                    .font(.subheadline)
                Text(parcel.createdAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
    }
}

struct StatusBadge: View {
    let status: DeliveryStatus

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.systemImage)
                .font(.caption)
            Text(status.displayName)
        }
        .font(.caption)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(status.color.opacity(0.2))
        .foregroundColor(status.color)
        .cornerRadius(8)
    }
}

#Preview {
    ParcelListView()
        .frame(width: 800, height: 500)
}
