import SwiftUI
import SwiftData

struct DashboardView: View {
    @StateObject private var parcelViewModel = ParcelViewModel()
    @StateObject private var customerViewModel = CustomerViewModel()
    @StateObject private var driverViewModel = DriverViewModel()
    @StateObject private var invoiceViewModel = InvoiceViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Dashboard")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    StatCard(
                        title: "Total Parcels",
                        value: "\(parcelViewModel.parcels.count)",
                        icon: "shippingbox.fill",
                        color: .blue
                    )

                    StatCard(
                        title: "In Transit",
                        value: "\(parcelViewModel.parcels.filter { $0.status == .inTransit }.count)",
                        icon: "truck.fill",
                        color: .purple
                    )

                    StatCard(
                        title: "Delivered",
                        value: "\(parcelViewModel.parcels.filter { $0.status == .delivered }.count)",
                        icon: "checkmark.circle.fill",
                        color: .green
                    )

                    StatCard(
                        title: "Customers",
                        value: "\(customerViewModel.customers.count)",
                        icon: "person.2.fill",
                        color: .orange
                    )
                }

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    StatCard(
                        title: "Total Drivers",
                        value: "\(driverViewModel.drivers.count)",
                        icon: "car.fill",
                        color: .teal
                    )

                    StatCard(
                        title: "Available Drivers",
                        value: "\(driverViewModel.availableDrivers.count)",
                        icon: "checkmark.circle",
                        color: .green
                    )

                    StatCard(
                        title: "Busy Drivers",
                        value: "\(driverViewModel.busyDrivers.count)",
                        icon: "clock.fill",
                        color: .orange
                    )
                }

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    StatCard(
                        title: "Total Revenue",
                        value: String(format: "$%.0f", invoiceViewModel.totalRevenue),
                        icon: "dollarsign.circle.fill",
                        color: .green
                    )

                    StatCard(
                        title: "Pending",
                        value: String(format: "$%.0f", invoiceViewModel.pendingAmount),
                        icon: "clock.fill",
                        color: .orange
                    )

                    StatCard(
                        title: "Overdue",
                        value: String(format: "$%.0f", invoiceViewModel.overdueAmount),
                        icon: "exclamationmark.triangle.fill",
                        color: .red
                    )

                    StatCard(
                        title: "Invoices",
                        value: "\(invoiceViewModel.invoices.count)",
                        icon: "doc.text.fill",
                        color: .blue
                    )
                }

                Text("Recent Parcels")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top)

                if parcelViewModel.parcels.isEmpty {
                    EmptyStateView(
                        icon: "shippingbox",
                        title: "No Parcels Yet",
                        message: "Create your first parcel to start tracking deliveries"
                    )
                    .frame(height: 150)
                } else {
                    ForEach(parcelViewModel.parcels.prefix(5)) { parcel in
                        HStack {
                            Image(systemName: parcel.status.systemImage)
                                .foregroundColor(.accentColor)
                            Text(parcel.trackingNumber)
                                .font(.headline)
                            Spacer()
                            Text(parcel.statusDisplayName)
                                .font(.subheadline)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(statusColor(parcel.status).opacity(0.2))
                                .foregroundColor(statusColor(parcel.status))
                                .cornerRadius(8)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .padding()
        }
        .task {
            parcelViewModel.loadParcels()
            customerViewModel.loadCustomers()
            driverViewModel.loadDrivers()
            invoiceViewModel.loadInvoices()
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

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                Spacer()
            }
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
    }
}

#Preview {
    DashboardView()
        .frame(width: 600, height: 400)
}
