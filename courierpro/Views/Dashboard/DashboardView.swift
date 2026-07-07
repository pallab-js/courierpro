import SwiftUI
import SwiftData

struct DashboardView: View {
    @StateObject private var parcelViewModel = ParcelViewModel()
    @StateObject private var customerViewModel = CustomerViewModel()
    @StateObject private var driverViewModel = DriverViewModel()
    @StateObject private var invoiceViewModel = InvoiceViewModel()

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        default: return "Good Evening"
        }
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 0) {
                heroHeader
                    .padding(.bottom, 24)

                kpiSection
                    .padding(.bottom, 24)

                HStack(alignment: .top, spacing: 20) {
                    statusDistributionCard
                    revenueHighlightsCard
                }
                .padding(.bottom, 24)

                recentParcelsSection
            }
            .padding(28)
        }
        .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
        .task {
            parcelViewModel.loadParcels()
            customerViewModel.loadCustomers()
            driverViewModel.loadDrivers()
            invoiceViewModel.loadInvoices()
        }
    }

    // MARK: - Hero Header

    private var heroHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(greeting)
                    .font(.title3)
                    .foregroundColor(.secondary)
                Text("CourierPro Dashboard")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                Text(Date().formatted(date: .complete, time: .omitted))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            HStack(spacing: 12) {
                quickAction(
                    title: "New Parcel",
                    icon: "plus.circle.fill",
                    color: .blue
                )
                quickAction(
                    title: "New Customer",
                    icon: "person.crop.circle.badge.plus",
                    color: .orange
                )
                quickAction(
                    title: "New Invoice",
                    icon: "doc.text.badge.plus",
                    color: .green
                )
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        )
    }

    private func quickAction(title: String, icon: String, color: Color) -> some View {
        Button(action: {}) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 80)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.08))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - KPI Section

    private var kpiSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Key Metrics")
                .font(.headline)
                .foregroundColor(.primary)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                KPICard(
                    title: "Total Parcels",
                    value: "\(parcelViewModel.parcels.count)",
                    icon: "shippingbox.fill",
                    gradient: LinearGradient(
                        colors: [Color.blue, Color.blue.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    trend: nil
                )

                KPICard(
                    title: "In Transit",
                    value: "\(parcelViewModel.parcels.filter { $0.status == .inTransit }.count)",
                    icon: "truck.fill",
                    gradient: LinearGradient(
                        colors: [Color.purple, Color.purple.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    trend: nil
                )

                KPICard(
                    title: "Delivered",
                    value: "\(parcelViewModel.parcels.filter { $0.status == .delivered }.count)",
                    icon: "checkmark.circle.fill",
                    gradient: LinearGradient(
                        colors: [Color.green, Color.green.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    trend: nil
                )

                KPICard(
                    title: "Revenue",
                    value: String(format: "$%.0f", invoiceViewModel.totalRevenue),
                    icon: "dollarsign.circle.fill",
                    gradient: LinearGradient(
                        colors: [Color.orange, Color.orange.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    trend: nil
                )
            }
        }
    }

    // MARK: - Status Distribution & Revenue Highlights

    private var statusDistributionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Delivery Status")
                    .font(.headline)
                Spacer()
                Text("\(parcelViewModel.parcels.count) total")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if parcelViewModel.parcels.isEmpty {
                emptyStatusCard
            } else {
                statusDistribution
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
        )
    }

    private var emptyStatusCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar")
                .font(.system(size: 32))
                .foregroundColor(.secondary.opacity(0.5))
            Text("No data yet")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 180)
    }

    private var statusDistribution: some View {
        VStack(spacing: 12) {
            ForEach(DeliveryStatus.allCases) { status in
                let count = parcelViewModel.parcels.filter { $0.status == status }.count
                let total = parcelViewModel.parcels.count
                let percentage = total > 0 ? CGFloat(count) / CGFloat(total) : 0

                HStack(spacing: 12) {
                    Image(systemName: status.systemImage)
                        .foregroundColor(statusColor(status))
                        .frame(width: 20)

                    Text(status.displayName)
                        .font(.subheadline)
                        .frame(width: 100, alignment: .leading)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.15))
                            RoundedRectangle(cornerRadius: 4)
                                .fill(statusColor(status).gradient)
                                .frame(width: geo.size.width * percentage)
                        }
                    }
                    .frame(height: 8)

                    Text("\(count)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .frame(width: 30, alignment: .trailing)
                }
            }
        }
    }

    private var revenueHighlightsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Financial Overview")
                    .font(.headline)
                Spacer()
            }

            revenueRow(
                title: "Total Revenue",
                value: String(format: "$%.2f", invoiceViewModel.totalRevenue),
                icon: "dollarsign.circle.fill",
                color: .green
            )

            revenueRow(
                title: "Pending",
                value: String(format: "$%.2f", invoiceViewModel.pendingAmount),
                icon: "clock.fill",
                color: .orange
            )

            revenueRow(
                title: "Overdue",
                value: String(format: "$%.2f", invoiceViewModel.overdueAmount),
                icon: "exclamationmark.triangle.fill",
                color: .red
            )

            Divider()
                .padding(.vertical, 4)

            HStack {
                Text("Active Drivers")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(driverViewModel.availableDrivers.count) available / \(driverViewModel.drivers.count) total")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            HStack {
                Text("Total Customers")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(customerViewModel.customers.count)")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
        )
    }

    private func revenueRow(title: String, value: String, icon: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
    }

    // MARK: - Recent Parcels

    private var recentParcelsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Parcels")
                    .font(.headline)
                Spacer()
                Button("View All") {}
                    .font(.subheadline)
                    .buttonStyle(.plain)
                    .foregroundColor(.accentColor)
            }

            if parcelViewModel.parcels.isEmpty {
                EmptyStateView(
                    icon: "shippingbox",
                    title: "No Parcels Yet",
                    message: "Create your first parcel to start tracking deliveries"
                )
                .frame(height: 150)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(NSColor.controlBackgroundColor))
                )
            } else {
                recentParcelsTable
            }
        }
    }

    private var recentParcelsTable: some View {
        VStack(spacing: 0) {
            tableHeader

            ForEach(Array(parcelViewModel.parcels.prefix(8).enumerated()), id: \.element.id) { index, parcel in
                parcelRow(parcel, isEven: index.isMultiple(of: 2))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
    }

    private var tableHeader: some View {
        HStack(spacing: 0) {
            Text("TRACKING NUMBER")
                .frame(width: 160, alignment: .leading)
            Text("STATUS")
                .frame(width: 120, alignment: .center)
            Text("FROM")
                .frame(width: 140, alignment: .leading)
            Text("TO")
                .frame(width: 140, alignment: .leading)
            Text("DRIVER")
                .frame(width: 120, alignment: .leading)
            Text("DATE")
                .frame(width: 100, alignment: .trailing)
            Text("WEIGHT")
                .frame(width: 80, alignment: .trailing)
        }
        .font(.caption)
        .fontWeight(.semibold)
        .foregroundColor(.secondary)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(NSColor.controlBackgroundColor))
    }

    private func parcelRow(_ parcel: Parcel, isEven: Bool) -> some View {
        HStack(spacing: 0) {
            Text(parcel.trackingNumber)
                .font(.system(.subheadline, design: .monospaced))
                .fontWeight(.medium)
                .frame(width: 160, alignment: .leading)

            HStack(spacing: 4) {
                Image(systemName: parcel.status.systemImage)
                    .font(.caption)
                Text(parcel.status.displayName)
            }
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor(parcel.status).opacity(0.15))
            .foregroundColor(statusColor(parcel.status))
            .cornerRadius(6)
            .frame(width: 120, alignment: .center)

            Text(parcel.senderName)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 140, alignment: .leading)
                .lineLimit(1)

            Text(parcel.receiverName)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 140, alignment: .leading)
                .lineLimit(1)

            Text(parcel.driverName)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 120, alignment: .leading)
                .lineLimit(1)

            Text(parcel.createdAt, style: .date)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .trailing)

            Text(String(format: "%.1f kg", parcel.weight))
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(isEven ? Color(NSColor.controlBackgroundColor).opacity(0.3) : Color.clear)
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

// MARK: - KPI Card Component

struct KPICard: View {
    let title: String
    let value: String
    let icon: String
    let gradient: LinearGradient
    var trend: Double? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.9))
                Spacer()
            }

            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            HStack(spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))

                if let trend = trend {
                    Spacer()
                    HStack(spacing: 2) {
                        Image(systemName: trend >= 0 ? "arrow.up" : "arrow.down")
                            .font(.caption2)
                        Text(String(format: "%.1f%%", abs(trend)))
                            .font(.caption2)
                    }
                    .foregroundColor(.white.opacity(0.9))
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(gradient)
                .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
        )
    }
}

#Preview {
    DashboardView()
        .frame(width: 900, height: 700)
}
