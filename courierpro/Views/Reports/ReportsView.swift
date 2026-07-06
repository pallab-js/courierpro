import SwiftUI

struct ReportsView: View {
    @StateObject private var parcelViewModel = ParcelViewModel()
    @StateObject private var customerViewModel = CustomerViewModel()
    @StateObject private var driverViewModel = DriverViewModel()
    @StateObject private var invoiceViewModel = InvoiceViewModel()
    @State private var selectedReport: ReportType = .overview

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Reports")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Spacer()
                Picker("Report", selection: $selectedReport) {
                    ForEach(ReportType.allCases) { report in
                        Text(report.displayName).tag(report)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 300)
            }
            .padding()

            Divider()

            switch selectedReport {
            case .overview:
                OverviewReportView(
                    parcelViewModel: parcelViewModel,
                    customerViewModel: customerViewModel,
                    driverViewModel: driverViewModel,
                    invoiceViewModel: invoiceViewModel
                )
            case .revenue:
                RevenueReportView(invoiceViewModel: invoiceViewModel)
            case .deliveries:
                DeliveryReportView(parcelViewModel: parcelViewModel)
            case .drivers:
                DriverReportView(driverViewModel: driverViewModel, parcelViewModel: parcelViewModel)
            }
        }
        .task {
            try? parcelViewModel.loadParcels()
            try? customerViewModel.loadCustomers()
            try? driverViewModel.loadDrivers()
            try? invoiceViewModel.loadInvoices()
        }
    }
}

enum ReportType: String, CaseIterable, Identifiable {
    case overview
    case revenue
    case deliveries
    case drivers

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .overview: return "Overview"
        case .revenue: return "Revenue"
        case .deliveries: return "Deliveries"
        case .drivers: return "Drivers"
        }
    }
}

struct OverviewReportView: View {
    @ObservedObject var parcelViewModel: ParcelViewModel
    @ObservedObject var customerViewModel: CustomerViewModel
    @ObservedObject var driverViewModel: DriverViewModel
    @ObservedObject var invoiceViewModel: InvoiceViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Business Overview")
                    .font(.title2)
                    .fontWeight(.semibold)

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ReportCard(title: "Total Parcels", value: "\(parcelViewModel.parcels.count)", icon: "shippingbox.fill", color: .blue)
                    ReportCard(title: "Active Customers", value: "\(customerViewModel.customers.count)", icon: "person.2.fill", color: .orange)
                    ReportCard(title: "Total Drivers", value: "\(driverViewModel.drivers.count)", icon: "car.fill", color: .teal)
                    ReportCard(title: "Total Invoices", value: "\(invoiceViewModel.invoices.count)", icon: "doc.text.fill", color: .purple)
                }

                Text("Delivery Status Breakdown")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .padding(.top)

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(DeliveryStatus.allCases) { status in
                        StatusCountCard(
                            status: status,
                            count: parcelViewModel.parcels.filter { $0.status == status }.count
                        )
                    }
                }

                Text("Financial Summary")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .padding(.top)

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ReportCard(title: "Total Revenue", value: String(format: "$%.2f", invoiceViewModel.totalRevenue), icon: "dollarsign.circle.fill", color: .green)
                    ReportCard(title: "Pending", value: String(format: "$%.2f", invoiceViewModel.pendingAmount), icon: "clock.fill", color: .orange)
                    ReportCard(title: "Overdue", value: String(format: "$%.2f", invoiceViewModel.overdueAmount), icon: "exclamationmark.triangle.fill", color: .red)
                }
            }
            .padding()
        }
    }
}

struct RevenueReportView: View {
    @ObservedObject var invoiceViewModel: InvoiceViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Revenue Analysis")
                    .font(.title2)
                    .fontWeight(.semibold)

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ReportCard(title: "Total Revenue", value: String(format: "$%.2f", invoiceViewModel.totalRevenue), icon: "dollarsign.circle.fill", color: .green)
                    ReportCard(title: "Pending", value: String(format: "$%.2f", invoiceViewModel.pendingAmount), icon: "clock.fill", color: .orange)
                    ReportCard(title: "Overdue", value: String(format: "$%.2f", invoiceViewModel.overdueAmount), icon: "exclamationmark.triangle.fill", color: .red)
                    ReportCard(title: "Avg Invoice", value: String(format: "$%.2f", averageInvoiceValue), icon: "chart.bar.fill", color: .blue)
                }

                Text("Invoices by Status")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .padding(.top)

                ForEach(InvoiceStatus.allCases) { status in
                    let count = invoiceViewModel.invoices.filter { $0.status == status }.count
                    let total = invoiceViewModel.invoices.filter { $0.status == status }.reduce(0) { $0 + $1.totalAmount }
                    HStack {
                        Image(systemName: status.systemImage)
                            .foregroundColor(statusColor(status))
                            .frame(width: 20)
                        Text(status.displayName)
                        Spacer()
                        Text("\(count) invoices")
                            .foregroundColor(.secondary)
                        Text(String(format: "$%.2f", total))
                            .fontWeight(.medium)
                            .frame(width: 100, alignment: .trailing)
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding()
        }
    }

    private var averageInvoiceValue: Double {
        guard !invoiceViewModel.invoices.isEmpty else { return 0 }
        return invoiceViewModel.invoices.reduce(0) { $0 + $1.totalAmount } / Double(invoiceViewModel.invoices.count)
    }

    private func statusColor(_ status: InvoiceStatus) -> Color {
        switch status {
        case .draft: return .gray
        case .pending: return .orange
        case .paid: return .green
        case .overdue: return .red
        case .cancelled: return .gray
        }
    }
}

struct DeliveryReportView: View {
    @ObservedObject var parcelViewModel: ParcelViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Delivery Performance")
                    .font(.title2)
                    .fontWeight(.semibold)

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ReportCard(title: "Total Deliveries", value: "\(parcelViewModel.parcels.count)", icon: "shippingbox.fill", color: .blue)
                    ReportCard(title: "Completed", value: "\(parcelViewModel.parcels.filter { $0.status == .delivered }.count)", icon: "checkmark.circle.fill", color: .green)
                    ReportCard(title: "Success Rate", value: successRate, icon: "chart.pie.fill", color: .purple)
                }

                Text("Parcels by Status")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .padding(.top)

                ForEach(DeliveryStatus.allCases) { status in
                    let count = parcelViewModel.parcels.filter { $0.status == status }.count
                    let percentage = parcelViewModel.parcels.isEmpty ? 0 : Double(count) / Double(parcelViewModel.parcels.count) * 100
                    HStack {
                        Image(systemName: status.systemImage)
                            .foregroundColor(statusColor(status))
                            .frame(width: 20)
                        Text(status.displayName)
                        Spacer()
                        Text("\(count)")
                            .foregroundColor(.secondary)
                        ProgressView(value: percentage, total: 100)
                            .frame(width: 100)
                        Text(String(format: "%.1f%%", percentage))
                            .foregroundColor(.secondary)
                            .frame(width: 50, alignment: .trailing)
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding()
        }
    }

    private var successRate: String {
        guard !parcelViewModel.parcels.isEmpty else { return "0%" }
        let delivered = parcelViewModel.parcels.filter { $0.status == .delivered }.count
        return String(format: "%.1f%%", Double(delivered) / Double(parcelViewModel.parcels.count) * 100)
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

struct DriverReportView: View {
    @ObservedObject var driverViewModel: DriverViewModel
    @ObservedObject var parcelViewModel: ParcelViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Driver Performance")
                    .font(.title2)
                    .fontWeight(.semibold)

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ReportCard(title: "Total Drivers", value: "\(driverViewModel.drivers.count)", icon: "car.fill", color: .teal)
                    ReportCard(title: "Available", value: "\(driverViewModel.availableDrivers.count)", icon: "checkmark.circle.fill", color: .green)
                    ReportCard(title: "Busy", value: "\(driverViewModel.busyDrivers.count)", icon: "clock.fill", color: .orange)
                }

                Text("Driver Assignments")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .padding(.top)

                ForEach(driverViewModel.drivers) { driver in
                    let assignedCount = driver.assignedParcels?.count ?? 0
                    let activeCount = driver.assignedParcels?.filter { $0.status != .delivered && $0.status != .failed }.count ?? 0
                    HStack {
                        Circle()
                            .fill(driver.isAvailable ? Color.green : Color.orange)
                            .frame(width: 10, height: 10)
                        VStack(alignment: .leading) {
                            Text(driver.name)
                                .font(.body)
                                .fontWeight(.medium)
                            Text("License: \(driver.licenseNumber)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("\(assignedCount) assigned")
                                .font(.subheadline)
                            Text("\(activeCount) active")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding()
        }
    }
}

struct ReportCard: View {
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

struct StatusCountCard: View {
    let status: DeliveryStatus
    let count: Int

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: status.systemImage)
                .foregroundColor(statusColor)
                .font(.title2)
            Text("\(count)")
                .font(.title3)
                .fontWeight(.bold)
            Text(status.displayName)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
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

#Preview {
    ReportsView()
        .frame(width: 800, height: 600)
}
