import SwiftUI

struct InvoiceListView: View {
    @StateObject private var viewModel = InvoiceViewModel()
    @State private var showingCreateSheet = false
    @State private var viewingInvoice: Invoice?
    @State private var deleteConfirmation: Invoice?

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

            if viewModel.isLoadingInvoices {
                LoadingView()
            } else if viewModel.filteredInvoices.isEmpty {
                EmptyStateView(
                    icon: "doc.text",
                    title: "No Invoices Found",
                    message: viewModel.invoices.isEmpty
                        ? "Create your first invoice to get started"
                        : "Try adjusting your search or filter criteria",
                    actionTitle: viewModel.invoices.isEmpty ? "Create Invoice" : nil,
                    action: viewModel.invoices.isEmpty ? { showingCreateSheet = true } : nil
                )
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
                                    viewModel.updateInvoiceStatus(invoice, status: .pending)
                                }
                            }
                            if invoice.status == .pending {
                                Button("Mark as Paid") {
                                    viewModel.updateInvoiceStatus(invoice, status: .paid)
                                }
                            }
                            Divider()
                            Button("Delete", role: .destructive) {
                                deleteConfirmation = invoice
                            }
                        }
                    }
                }
            }
        }
        .task {
            viewModel.loadInvoices()
        }
        .sheet(isPresented: $showingCreateSheet) {
            InvoiceFormView(viewModel: viewModel)
        }
        .sheet(item: $viewingInvoice) { invoice in
            InvoiceDetailView(invoice: invoice)
        }
        .errorAlert(isPresented: $viewModel.showError, message: viewModel.errorMessage)
        .alert("Delete Invoice", isPresented: Binding(
            get: { deleteConfirmation != nil },
            set: { if !$0 { deleteConfirmation = nil } }
        )) {
            Button("Cancel", role: .cancel) { deleteConfirmation = nil }
            Button("Delete", role: .destructive) {
                if let invoice = deleteConfirmation {
                    viewModel.deleteInvoice(invoice)
                    deleteConfirmation = nil
                }
            }
        } message: {
            if let invoice = deleteConfirmation {
                Text("Are you sure you want to delete invoice \(invoice.invoiceNumber)? This action cannot be undone.")
            }
        }
    }
}

struct InvoiceRow: View {
    let invoice: Invoice
    let onSelect: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: invoice.status.systemImage)
                .foregroundColor(invoice.status.color)
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
                Text("\(AppSettings.shared.currencySymbol)\(String(format: "%.2f", invoice.totalAmount))")
                    .font(.body)
                    .fontWeight(.medium)
                Text(invoice.status.displayName)
                    .font(.caption)
                    .foregroundColor(invoice.status.color)
            }

            VStack(alignment: .trailing, spacing: 2) {
                Text("Due: \(invoice.dueDate, style: .date)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                if !invoice.isFullyPaid {
                    Text("Balance: \(AppSettings.shared.currencySymbol)\(String(format: "%.2f", invoice.balanceDue))")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Invoice \(invoice.invoiceNumber), Status: \(invoice.status.displayName), Amount: \(AppSettings.shared.currencySymbol)\(String(format: "%.2f", invoice.totalAmount))")
        .accessibilityHint("Double tap to view details")
    }
}

#Preview {
    InvoiceListView()
        .frame(width: 800, height: 500)
}
