import SwiftUI
import SwiftData

struct DashboardView: View {
    @StateObject private var parcelViewModel = ParcelViewModel()
    @StateObject private var customerViewModel = CustomerViewModel()
    @StateObject private var driverViewModel = DriverViewModel()
    @StateObject private var invoiceViewModel = InvoiceViewModel()
    @Environment(\.modelContext) private var modelContext

    @State private var showingCreateParcel = false
    @State private var showingCreateCustomer = false
    @State private var showingCreateInvoice = false

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
            VStack(alignment: .leading, spacing: 24) {
                heroHeader
                kpiSection
                bottomSection
            }
            .padding(24)
        }
        .background(Color(NSColor.controlBackgroundColor))
        .task {
            parcelViewModel.loadParcels()
            customerViewModel.loadCustomers()
            driverViewModel.loadDrivers()
            invoiceViewModel.loadInvoices()
        }
        .sheet(isPresented: $showingCreateParcel) {
            ParcelFormView(viewModel: parcelViewModel)
        }
        .sheet(isPresented: $showingCreateCustomer) {
            CustomerFormView(viewModel: customerViewModel)
        }
        .sheet(isPresented: $showingCreateInvoice) {
            InvoiceFormView(viewModel: invoiceViewModel)
        }
    }

    // MARK: - Hero Header

    private var heroHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(greeting)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("CourierPro Dashboard")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text(Date().formatted(date: .complete, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            HStack(spacing: 10) {
                quickAction(title: "New Parcel", icon: "shippingbox.fill", color: .blue, shortcut: "n") {
                    showingCreateParcel = true
                }
                quickAction(title: "New Customer", icon: "person.fill.badge.plus", color: .orange, shortcut: "shift+n") {
                    showingCreateCustomer = true
                }
                quickAction(title: "New Invoice", icon: "doc.text.badge.plus", color: .green, shortcut: "i") {
                    showingCreateInvoice = true
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.ultraThinMaterial)
        )
    }

    private func quickAction(title: String, icon: String, color: Color, shortcut: String? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                Text(title)
                    .font(.caption2)
            }
            .frame(width: 80, height: 52)
            .foregroundColor(color)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.1))
            )
            .contentShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityHint("Creates a new \(title.replacingOccurrences(of: "New ", with: "").lowercased())")
    }

    // MARK: - KPI Section

    private var kpiSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Key Metrics")
                .font(.headline)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                KPICard(
                    title: "Total Parcels",
                    value: "\(parcelViewModel.parcels.count)",
                    icon: "shippingbox.fill",
                    gradient: LinearGradient(
                        colors: [.blue, .blue.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                KPICard(
                    title: "In Transit",
                    value: "\(parcelViewModel.inTransitCount)",
                    icon: "truck.fill",
                    gradient: LinearGradient(
                        colors: [.purple, .purple.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                KPICard(
                    title: "Delivered",
                    value: "\(parcelViewModel.deliveredCount)",
                    icon: "checkmark.circle.fill",
                    gradient: LinearGradient(
                        colors: [.green, .green.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                KPICard(
                    title: "Revenue",
                    value: String(format: "\(AppSettings.shared.currencySymbol)%.0f", invoiceViewModel.totalRevenue),
                    icon: "dollarsign.circle.fill",
                    gradient: LinearGradient(
                        colors: [.orange, .orange.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            }
        }
    }

    // MARK: - Bottom Section

    private var bottomSection: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                statusDistributionCard
                    .frame(minWidth: 320)
                revenueHighlightsCard
                    .frame(minWidth: 280)
            }
            recentParcelsCard
        }
    }

    // MARK: - Status Distribution

    private var statusDistributionCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Delivery Status")
                    .font(.headline)
                Spacer()
                Text("\(parcelViewModel.parcels.count) total")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if parcelViewModel.parcels.isEmpty {
                EmptyStateView(
                    icon: "shippingbox",
                    title: "No Parcels Yet",
                    message: "Create your first parcel to see delivery status"
                )
                .frame(height: 120)
            } else {
                statusDistribution
            }
        }
        .padding(16)
        .background(cardBackground)
    }

    private var statusDistribution: some View {
        VStack(spacing: 10) {
            ForEach(DeliveryStatus.allCases) { status in
                let count = parcelViewModel.parcels.filter { $0.status == status }.count
                let total = parcelViewModel.parcels.count
                let pct = total > 0 ? CGFloat(count) / CGFloat(total) : 0

                HStack(spacing: 10) {
                    Image(systemName: status.systemImage)
                        .font(.caption)
                        .foregroundColor(status.color)
                        .frame(width: 16)
                        .accessibilityHidden(true)

                    Text(status.displayName)
                        .font(.caption)
                        .frame(width: 90, alignment: .leading)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.gray.opacity(0.12))
                            Capsule()
                                .fill(status.color)
                                .frame(width: geo.size.width * pct)
                        }
                    }
                    .frame(height: 6)
                    .accessibilityHidden(true)

                    Text("\(count)")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .frame(width: 24, alignment: .trailing)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(status.displayName): \(count) parcels, \(Int(pct * 100)) percent")
            }
        }
    }

    // MARK: - Revenue Highlights

    private var revenueHighlightsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Financial Overview")
                .font(.headline)

            revenueRow(title: "Revenue", value: String(format: "\(AppSettings.shared.currencySymbol)%.2f", invoiceViewModel.totalRevenue), icon: "dollarsign.circle.fill", color: .green)
            revenueRow(title: "Pending", value: String(format: "\(AppSettings.shared.currencySymbol)%.2f", invoiceViewModel.pendingAmount), icon: "clock.fill", color: .orange)
            revenueRow(title: "Overdue", value: String(format: "\(AppSettings.shared.currencySymbol)%.2f", invoiceViewModel.overdueAmount), icon: "exclamationmark.triangle.fill", color: .red)

            Divider()

            infoRow(label: "Active Drivers", value: "\(driverViewModel.availableDrivers.count) / \(driverViewModel.drivers.count)")
            infoRow(label: "Customers", value: "\(customerViewModel.customers.count)")
            infoRow(label: "Invoices", value: "\(invoiceViewModel.invoices.count)")
        }
        .padding(16)
        .background(cardBackground)
    }

    private func revenueRow(title: String, value: String, icon: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 16)
                .accessibilityHidden(true)
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    // MARK: - Recent Parcels

    private var recentParcelsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Recent Parcels")
                .font(.headline)

            if parcelViewModel.parcels.isEmpty {
                EmptyStateView(
                    icon: "shippingbox",
                    title: "No Parcels Yet",
                    message: "Create your first parcel to see recent deliveries"
                )
                .frame(height: 120)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    recentParcelsTable
                        .frame(minWidth: 700)
                }
            }
        }
        .padding(16)
        .background(cardBackground)
    }

    private var recentParcelsTable: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                tableCell("TRACKING", width: 140, alignment: .leading)
                tableCell("STATUS", width: 100, alignment: .center)
                tableCell("FROM", width: 120, alignment: .leading)
                tableCell("TO", width: 120, alignment: .leading)
                tableCell("DRIVER", width: 110, alignment: .leading)
                tableCell("DATE", width: 90, alignment: .trailing)
                tableCell("WEIGHT", width: 70, alignment: .trailing)
            }
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))

            ForEach(Array(parcelViewModel.parcels.prefix(6).enumerated()), id: \.element.id) { index, parcel in
                parcelRow(parcel, isEven: index.isMultiple(of: 2))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
        )
    }

    private func tableCell(_ text: String, width: CGFloat, alignment: Alignment) -> some View {
        Text(text)
            .frame(width: width, alignment: alignment)
    }

    private func parcelRow(_ parcel: Parcel, isEven: Bool) -> some View {
        HStack(spacing: 0) {
            Text(parcel.trackingNumber)
                .font(.system(.caption, design: .monospaced))
                .fontWeight(.medium)
                .frame(width: 140, alignment: .leading)

            HStack(spacing: 3) {
                Circle()
                    .fill(parcel.status.color)
                    .frame(width: 5, height: 5)
                Text(parcel.status.displayName)
            }
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(parcel.status.color.opacity(0.1))
            .foregroundColor(parcel.status.color)
            .cornerRadius(4)
            .frame(width: 100, alignment: .center)

            Text(parcel.senderName)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 120, alignment: .leading)
                .lineLimit(1)

            Text(parcel.receiverName)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 120, alignment: .leading)
                .lineLimit(1)

            Text(parcel.driverName)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 110, alignment: .leading)
                .lineLimit(1)

            Text(parcel.createdAt, style: .date)
                .font(.caption2)
                .foregroundColor(.secondary)
                .frame(width: 90, alignment: .trailing)

            Text(String(format: "%.1f kg", parcel.weight))
                .font(.caption2)
                .foregroundColor(.secondary)
                .frame(width: 70, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(isEven ? Color(NSColor.controlBackgroundColor).opacity(0.4) : Color.clear)
    }

    // MARK: - Helpers

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color(NSColor.controlBackgroundColor))
            .shadow(color: .black.opacity(0.06), radius: 4, y: 1)
    }

}

// MARK: - KPI Card

struct KPICard: View {
    let title: String
    let value: String
    let icon: String
    let gradient: LinearGradient

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.9))
                Spacer()
            }
            Text(value)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.85))
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(gradient)
                .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

#Preview {
    DashboardView()
        .frame(width: 900, height: 700)
}
