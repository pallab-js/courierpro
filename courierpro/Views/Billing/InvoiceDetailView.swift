import SwiftUI

struct InvoiceDetailView: View {
    let invoice: Invoice
    @StateObject private var viewModel = InvoiceViewModel()
    @State private var showingPaymentSheet = false
    @State private var showingDeleteConfirmation = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection
                Divider()
                amountsSection
                Divider()
                lineItemsSection
                Divider()
                paymentsSection
            }
            .padding()
        }
        .navigationTitle(invoice.invoiceNumber)
        .toolbar {
            ToolbarItemGroup {
                if invoice.status == .draft {
                    Button(action: {
                        try? viewModel.updateInvoiceStatus(invoice, status: .pending)
                    }) {
                        Label("Send", systemImage: "paperplane")
                    }
                }
                if invoice.status == .pending {
                    Button(action: { showingPaymentSheet = true }) {
                        Label("Record Payment", systemImage: "creditcard")
                    }
                }
                ExportButton(invoice: invoice)
                Button(action: { showingDeleteConfirmation = true }) {
                    Label("Delete", systemImage: "trash")
                }
                .foregroundColor(.red)
            }
        }
        .sheet(isPresented: $showingPaymentSheet) {
            PaymentFormView(invoice: invoice, viewModel: viewModel)
        }
        .alert("Delete Invoice", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                try? viewModel.deleteInvoice(invoice)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete invoice \(invoice.invoiceNumber)? This action cannot be undone.")
        }
        .errorAlert(isPresented: $viewModel.showError, message: viewModel.errorMessage)
    }

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(invoice.invoiceNumber)
                    .font(.title)
                    .fontWeight(.bold)
                    .fontDesign(.monospaced)
                Text("Created \(invoice.createdAt, style: .date)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            InvoiceStatusBadge(status: invoice.status)
                .scaleEffect(1.2)
        }
    }

    private var amountsSection: some View {
        HStack(alignment: .top, spacing: 40) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Customer")
                    .font(.headline)
                if let customer = invoice.customer {
                    Text(customer.name)
                        .font(.body)
                    if !customer.email.isEmpty {
                        Text(customer.email)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("No customer")
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 8) {
                HStack {
                    Text("Subtotal:")
                        .foregroundColor(.secondary)
                    Text("\(AppSettings.shared.currencySymbol)\(String(format: "%.2f", invoice.subtotal))")
                }
                HStack {
                    Text("Tax (\(String(format: "%.1f", invoice.taxRate))%):")
                        .foregroundColor(.secondary)
                    Text("\(AppSettings.shared.currencySymbol)\(String(format: "%.2f", invoice.taxAmount))")
                }
                Divider()
                HStack {
                    Text("Total:")
                        .fontWeight(.bold)
                    Text("\(AppSettings.shared.currencySymbol)\(String(format: "%.2f", invoice.totalAmount))")
                        .fontWeight(.bold)
                }
                if invoice.totalPaid > 0 {
                    HStack {
                        Text("Paid:")
                            .foregroundColor(.green)
                        Text("\(AppSettings.shared.currencySymbol)\(String(format: "%.2f", invoice.totalPaid))")
                            .foregroundColor(.green)
                    }
                }
                HStack {
                    Text("Balance Due:")
                        .fontWeight(.bold)
                        .foregroundColor(invoice.balanceDue > 0 ? .orange : .green)
                    Text("\(AppSettings.shared.currencySymbol)\(String(format: "%.2f", invoice.balanceDue))")
                        .fontWeight(.bold)
                        .foregroundColor(invoice.balanceDue > 0 ? .orange : .green)
                }
            }
        }
    }

    private var lineItemsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Line Items")
                .font(.headline)

            if let items = invoice.items, !items.isEmpty {
                ForEach(items) { item in
                    HStack {
                        Text(item.itemDescription)
                        Spacer()
                        Text("\(item.quantity) x \(AppSettings.shared.currencySymbol)\(String(format: "%.2f", item.unitPrice))")
                            .foregroundColor(.secondary)
                        Text("\(AppSettings.shared.currencySymbol)\(String(format: "%.2f", item.totalPrice))")
                            .fontWeight(.medium)
                            .frame(width: 80, alignment: .trailing)
                    }
                    .padding(.vertical, 4)
                }
            } else {
                Text("No items")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 40)
            }
        }
    }

    private var paymentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Payment History")
                .font(.headline)

            if let payments = invoice.payments, !payments.isEmpty {
                ForEach(payments) { payment in
                    HStack {
                        Image(systemName: payment.method.systemImage)
                            .foregroundColor(.accentColor)
                            .frame(width: 20)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(payment.method.displayName)
                                .font(.subheadline)
                            Text(payment.paymentDate, style: .date)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            if let ref = payment.reference, !ref.isEmpty {
                                Text("Ref: \(ref)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        Text("\(AppSettings.shared.currencySymbol)\(String(format: "%.2f", payment.amount))")
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                    .padding(.vertical, 4)
                }
            } else {
                Text("No payments recorded")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 40)
            }
        }
    }
}

struct InvoiceStatusBadge: View {
    let status: InvoiceStatus

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.systemImage)
                .font(.caption)
            Text(status.displayName)
        }
        .font(.caption)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(backgroundColor.opacity(0.2))
        .foregroundColor(backgroundColor)
        .cornerRadius(8)
    }

    private var backgroundColor: Color {
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
    InvoiceDetailView(invoice: Invoice(invoiceNumber: "INV-123456"))
        .frame(width: 600, height: 700)
}
