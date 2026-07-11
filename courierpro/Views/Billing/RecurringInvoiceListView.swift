import SwiftUI

struct RecurringInvoiceListView: View {
    @StateObject private var viewModel = RecurringInvoiceViewModel()
    @State private var showingCreateSheet = false
    @State private var viewingRecurring: RecurringInvoice?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Recurring Invoices")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Spacer()
                Button(action: { showingCreateSheet = true }) {
                    Label("New Recurring", systemImage: "plus")
                }
            }
            .padding()

            Divider()

            if viewModel.isLoading {
                LoadingView()
            } else if viewModel.recurringInvoices.isEmpty {
                EmptyStateView(
                    icon: "arrow.clockwise",
                    title: "No Recurring Invoices",
                    message: "Set up automatic invoice generation on a schedule",
                    actionTitle: "Create Recurring",
                    action: { showingCreateSheet = true }
                )
            } else {
                List {
                    ForEach(viewModel.recurringInvoices) { recurring in
                        RecurringInvoiceRow(recurring: recurring) {
                            viewingRecurring = recurring
                        }
                        .contextMenu {
                            Button("Generate Invoice Now") {
                                viewModel.generateInvoice(from: recurring)
                            }
                            Button(recurring.isActive ? "Pause" : "Resume") {
                                viewModel.toggleActive(recurring)
                            }
                            Divider()
                            Button("Delete", role: .destructive) {
                                viewModel.deleteRecurringInvoice(recurring)
                            }
                        }
                    }
                }
            }
        }
        .task {
            viewModel.loadRecurringInvoices()
        }
        .sheet(isPresented: $showingCreateSheet) {
            RecurringInvoiceFormView(viewModel: viewModel)
        }
        .errorAlert(isPresented: $viewModel.showError, message: viewModel.errorMessage)
    }
}

struct RecurringInvoiceRow: View {
    let recurring: RecurringInvoice
    let onSelect: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(recurring.isActive ? Color.green : Color.gray)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(recurring.name)
                    .font(.body)
                    .fontWeight(.medium)
                Text("Customer: \(recurring.customer?.name ?? "Unknown")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .center, spacing: 2) {
                Text(recurring.frequency.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
                Text("\(AppSettings.shared.currencySymbol)\(String(format: "%.2f", recurring.amount))")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            VStack(alignment: .trailing, spacing: 2) {
                Text("Next: \(recurring.nextDueDate, style: .date)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                if recurring.isActive {
                    Text("Active")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
                    Text("Paused")
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
    }
}

struct RecurringInvoiceFormView: View {
    @ObservedObject var viewModel: RecurringInvoiceViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var selectedCustomer: Customer?
    @State private var amount = ""
    @State private var taxRate = "0"
    @State private var frequency: RecurrenceFrequency = .monthly
    @State private var notes = ""
    @State private var startDate = Date()

    @State private var availableCustomers: [Customer] = []
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Create Recurring Invoice")
                .font(.title2)
                .fontWeight(.bold)

            Form {
                Section("Basic Info") {
                    TextField("Invoice Name", text: $name)

                    Picker("Customer", selection: $selectedCustomer) {
                        Text("Choose a customer").tag(nil as Customer?)
                        ForEach(availableCustomers) { customer in
                            Text(customer.name).tag(customer as Customer?)
                        }
                    }
                }

                Section("Amount") {
                    HStack {
                        Text("Amount:")
                        TextField("0.00", text: $amount)
                            .textFieldStyle(.roundedBorder)
                    }

                    HStack {
                        Text("Tax Rate (%):")
                        TextField("0", text: $taxRate)
                            .textFieldStyle(.roundedBorder)
                    }
                }

                Section("Schedule") {
                    Picker("Frequency", selection: $frequency) {
                        ForEach(RecurrenceFrequency.allCases) { freq in
                            Text(freq.displayName).tag(freq)
                        }
                    }

                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(height: 60)
                }
            }
            .formStyle(.grouped)

            HStack {
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button("Create") {
                    createRecurring()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.isEmpty || selectedCustomer == nil || amount.isEmpty)
            }
        }
        .padding()
        .frame(width: 500, height: 550)
        .task {
            loadCustomers()
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }

    private func loadCustomers() {
        let customerViewModel = CustomerViewModel()
        customerViewModel.loadCustomers()
        availableCustomers = customerViewModel.customers
    }

    private func createRecurring() {
        guard let customer = selectedCustomer, let amountValue = Double(amount) else {
            errorMessage = "Please fill in all required fields"
            showingError = true
            return
        }

        let taxRateValue = Double(taxRate) ?? 0

        viewModel.createRecurringInvoice(
            name: name,
            customer: customer,
            amount: amountValue,
            taxRate: taxRateValue,
            frequency: frequency,
            notes: notes.isEmpty ? nil : notes,
            startDate: startDate
        )
        dismiss()
    }
}

#Preview {
    RecurringInvoiceListView()
        .frame(width: 800, height: 500)
}
