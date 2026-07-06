import SwiftUI

struct InvoiceListView: View {
    @StateObject private var viewModel = InvoiceViewModel()
    @State private var showingCreateSheet = false
    @State private var viewingInvoice: Invoice?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Invoices")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Spacer()
                Button(action: { showingCreateSheet = true }) {
                    Label("New Invoice", systemImage: "plus")
                }
            }
            .padding()

            Divider()

            HStack {
                SearchField(text: $viewModel.searchText, placeholder: "Search invoices...")
                Picker("Status", selection: $viewModel.selectedStatus) {
                    Text("All Statuses").tag(nil as InvoiceStatus?)
                    ForEach(InvoiceStatus.allCases) { status in
                        Text(status.displayName).tag(status as InvoiceStatus?)
                    }
                }
                .frame(width: 130)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

            if viewModel.filteredInvoices.isEmpty {
                VStack {
                    Image(systemName: "doc.text")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No invoices found")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text("Create your first invoice to get started")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(viewModel.filteredInvoices) { invoice in
                        InvoiceRow(invoice: invoice) {
                            viewingInvoice = invoice
                        }
                        .contextMenu {
                            Button("View Details") {
                                viewingInvoice = invoice
                            }
                            if invoice.status == .draft {
                                Button("Send Invoice") {
                                    try? viewModel.updateInvoiceStatus(invoice, status: .pending)
                                }
                            }
                            if invoice.status == .pending {
                                Button("Mark as Paid") {
                                    try? viewModel.updateInvoiceStatus(invoice, status: .paid)
                                }
                            }
                            Divider()
                            Button("Delete", role: .destructive) {
                                try? viewModel.deleteInvoice(invoice)
                            }
                        }
                    }
                }
            }
        }
        .task {
            try? viewModel.loadInvoices()
        }
        .sheet(isPresented: $showingCreateSheet) {
            InvoiceFormView(viewModel: viewModel)
        }
        .sheet(item: $viewingInvoice) { invoice in
            InvoiceDetailView(invoice: invoice)
        }
    }
}

struct InvoiceRow: View {
    let invoice: Invoice
    let onSelect: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: invoice.status.systemImage)
                .foregroundColor(statusColor(invoice.status))
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(invoice.invoiceNumber)
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.medium)
                Text("Customer: \(invoice.customer?.name ?? "Unknown")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "$%.2f", invoice.totalAmount))
                    .font(.body)
                    .fontWeight(.medium)
                Text(invoice.status.displayName)
                    .font(.caption)
                    .foregroundColor(statusColor(invoice.status))
            }

            VStack(alignment: .trailing, spacing: 2) {
                Text("Due: \(invoice.dueDate, style: .date)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                if !invoice.isFullyPaid {
                    Text("Balance: $\(String(format: "%.2f", invoice.balanceDue))")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            onSelect()
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

#Preview {
    InvoiceListView()
        .frame(width: 800, height: 500)
}
