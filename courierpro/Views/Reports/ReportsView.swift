import SwiftUI

struct ReportsView: View {
    @StateObject private var parcelViewModel = ParcelViewModel()
    @StateObject private var customerViewModel = CustomerViewModel()
    @StateObject private var driverViewModel = DriverViewModel()
    @StateObject private var invoiceViewModel = InvoiceViewModel()
    @State private var selectedReport: ReportType = .overview
    @State private var dateRange: ClosedRange<Date>?
    @State private var showingDatePicker = false
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var exportedURL: URL?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Reports")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Spacer()
                Button(action: { showingDatePicker = true }) {
                    Label("Date Range", systemImage: "calendar")
                }
                if dateRange != nil {
                    Button(action: { dateRange = nil }) {
                        Label("Clear Filter", systemImage: "xmark.circle")
                    }
                }
                Button(action: exportCurrentReport) {
                    Label("Export CSV", systemImage: "square.and.arrow.up")
                }
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

            if let range = dateRange {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.blue)
                    Text("Filtered: \(range.lowerBound.formatted(date: .abbreviated, time: .omitted)) - \(range.upperBound.formatted(date: .abbreviated, time: .omitted))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                Divider()
            }

            switch selectedReport {
            case .overview:
                OverviewReportView(
                    parcelViewModel: parcelViewModel,
                    customerViewModel: customerViewModel,
                    driverViewModel: driverViewModel,
                    invoiceViewModel: invoiceViewModel,
                    dateRange: dateRange
                )
            case .revenue:
                RevenueReportView(invoiceViewModel: invoiceViewModel, dateRange: dateRange)
            case .deliveries:
                DeliveryReportView(parcelViewModel: parcelViewModel, dateRange: dateRange)
            case .drivers:
                DriverReportView(driverViewModel: driverViewModel, parcelViewModel: parcelViewModel, dateRange: dateRange)
            }
        }
        .task {
            parcelViewModel.loadParcels()
            customerViewModel.loadCustomers()
            driverViewModel.loadDrivers()
            invoiceViewModel.loadInvoices()
        }
        .sheet(isPresented: $showingDatePicker) {
            DateRangePicker(startDate: $startDate, endDate: $endDate) { range in
                dateRange = range
            }
        }
        .alert("Export Complete", isPresented: .constant(exportedURL != nil)) {
            Button("OK") { exportedURL = nil }
        } message: {
            if let url = exportedURL {
                Text("Report saved to:\n\(url.lastPathComponent)")
            }
        }
    }

    private func exportCurrentReport() {
        let content = ReportExporter.generateCSV(
            parcels: filteredParcels,
            customers: customerViewModel.customers,
            drivers: driverViewModel.drivers,
            invoices: invoiceViewModel.invoices
        )
        exportedURL = ReportExporter.saveCSV(content, filename: "CourierPro_Report_\(dateString)")
    }

    private var filteredParcels: [Parcel] {
        guard let range = dateRange else { return parcelViewModel.parcels }
        return parcelViewModel.parcels.filter { range.contains($0.createdAt) }
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}

struct DateRangePicker: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    let onSelect: (ClosedRange<Date>) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("Select Date Range")
                .font(.headline)

            DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
            DatePicker("End Date", selection: $endDate, displayedComponents: .date)

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button("Apply") {
                    let range = min(startDate.timeIntervalSince1970, endDate.timeIntervalSince1970)
                    let start = Date(timeIntervalSince1970: range)
                    let end = Date(timeIntervalSince1970: max(startDate.timeIntervalSince1970, endDate.timeIntervalSince1970))
                    onSelect(start...end)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 350)
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
    var dateRange: ClosedRange<Date>?

    private var filteredParcels: [Parcel] {
        guard let range = dateRange else { return parcelViewModel.parcels }
        return parcelViewModel.parcels.filter { range.contains($0.createdAt) }
    }

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
                    ReportCard(title: "Total Parcels", value: "\(filteredParcels.count)", icon: "shippingbox.fill", color: .blue)
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
                            count: filteredParcels.filter { $0.status == status }.count
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
    var dateRange: ClosedRange<Date>?

    private var filteredInvoices: [Invoice] {
        guard let range = dateRange else { return invoiceViewModel.invoices }
        return invoiceViewModel.invoices.filter { range.contains($0.createdAt) }
    }

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
                    ReportCard(title: "Total Revenue", value: String(format: "$%.2f", filteredInvoices.filter { $0.status == .paid }.reduce(0) { $0 + $1.totalAmount }), icon: "dollarsign.circle.fill", color: .green)
                    ReportCard(title: "Pending", value: String(format: "$%.2f", filteredInvoices.filter { $0.status == .pending }.reduce(0) { $0 + $1.balanceDue }), icon: "clock.fill", color: .orange)
                    ReportCard(title: "Overdue", value: String(format: "$%.2f", filteredInvoices.filter { $0.status == .overdue }.reduce(0) { $0 + $1.balanceDue }), icon: "exclamationmark.triangle.fill", color: .red)
                    ReportCard(title: "Avg Invoice", value: String(format: "$%.2f", filteredInvoices.isEmpty ? 0 : filteredInvoices.reduce(0) { $0 + $1.totalAmount } / Double(filteredInvoices.count)), icon: "chart.bar.fill", color: .blue)
                }

                Text("Invoices by Status")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .padding(.top)

                ForEach(InvoiceStatus.allCases) { status in
                    let count = filteredInvoices.filter { $0.status == status }.count
                    let total = filteredInvoices.filter { $0.status == status }.reduce(0) { $0 + $1.totalAmount }
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
    var dateRange: ClosedRange<Date>?

    private var filteredParcels: [Parcel] {
        guard let range = dateRange else { return parcelViewModel.parcels }
        return parcelViewModel.parcels.filter { range.contains($0.createdAt) }
    }

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
                    ReportCard(title: "Total Deliveries", value: "\(filteredParcels.count)", icon: "shippingbox.fill", color: .blue)
                    ReportCard(title: "Completed", value: "\(filteredParcels.filter { $0.status == .delivered }.count)", icon: "checkmark.circle.fill", color: .green)
                    ReportCard(title: "Success Rate", value: successRate, icon: "chart.pie.fill", color: .purple)
                }

                Text("Parcels by Status")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .padding(.top)

                ForEach(DeliveryStatus.allCases) { status in
                    let count = filteredParcels.filter { $0.status == status }.count
                    let percentage = filteredParcels.isEmpty ? 0 : Double(count) / Double(filteredParcels.count) * 100
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
        guard !filteredParcels.isEmpty else { return "0%" }
        let delivered = filteredParcels.filter { $0.status == .delivered }.count
        return String(format: "%.1f%%", Double(delivered) / Double(filteredParcels.count) * 100)
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
    var dateRange: ClosedRange<Date>?

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
