import SwiftUI

struct InvoiceFormView: View {
    @ObservedObject var viewModel: InvoiceViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedCustomer: Customer?
    @State private var selectedParcels: Set<Parcel> = []
    @State private var taxRate: String = "18"
    @State private var notes: String = ""
    @State private var dueDate = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()

    @State private var availableCustomers: [Customer] = []
    @State private var availableParcels: [Parcel] = []
    @State private var isLoadingData = true

    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Create New Invoice")
                .font(.title2)
                .fontWeight(.bold)

            Form {
                Section("Customer") {
                    Picker("Select Customer", selection: $selectedCustomer) {
                        Text("Choose a customer").tag(nil as Customer?)
                        ForEach(availableCustomers) { customer in
                            Text(customer.name).tag(customer as Customer?)
                        }
                    }
                }

                Section("Delivered Parcels") {
                    if availableParcels.isEmpty {
                        Text("No delivered parcels available for invoicing")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(availableParcels) { parcel in
                            HStack {
                                Toggle(isOn: Binding(
                                    get: { selectedParcels.contains(parcel) },
                                    set: { isSelected in
                                        if isSelected {
                                            selectedParcels.insert(parcel)
                                        } else {
                                            selectedParcels.remove(parcel)
                                        }
                                    }
                                )) {
                                    VStack(alignment: .leading) {
                                        Text(parcel.trackingNumber)
                                            .font(.system(.body, design: .monospaced))
                                        Text("To: \(parcel.receiverName)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                Spacer()
                                Text("\(AppSettings.shared.currencySymbol)\(String(format: "%.2f", viewModel.calculatePrice(for: parcel)))")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                Section("Invoice Details") {
                    HStack {
                        Text("Tax Rate (%):")
                        TextField("10", text: $taxRate)
                            .textFieldStyle(.roundedBorder)
                    }

                    HStack {
                        Text("Due Date:")
                        DatePicker("", selection: $dueDate, displayedComponents: .date)
                    }

                    HStack {
                        Text("Notes:")
                        TextEditor(text: $notes)
                            .frame(height: 60)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: notes) { _, newValue in
                                notes = String(newValue.prefix(500))
                            }
                    }
                }
            }
            .formStyle(.grouped)

            HStack {
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button("Create Invoice") {
                    createInvoice()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(selectedCustomer == nil || selectedParcels.isEmpty)
            }
        }
        .padding()
        .frame(minWidth: 500, minHeight: 500)
        .task {
            await loadData()
        }
        .errorAlert(isPresented: $showingError, message: errorMessage)
    }

    private func loadData() async {
        let data = viewModel.loadInvoiceFormData()
        availableCustomers = data.customers
        availableParcels = data.parcels
        isLoadingData = false
    }

    private func createInvoice() {
        guard let customer = selectedCustomer, !selectedParcels.isEmpty else {
            errorMessage = "Please select a customer and at least one parcel"
            showingError = true
            return
        }

        guard let taxRateValue = Double(taxRate),
              taxRateValue.isFinite,
              taxRateValue >= 0,
              taxRateValue <= 100 else {
            errorMessage = "Tax rate must be between 0 and 100"
            showingError = true
            return
        }

        viewModel.createInvoice(
            customer: customer,
            parcels: Array(selectedParcels),
            taxRate: taxRateValue,
            notes: notes.isEmpty ? nil : notes,
            dueDate: dueDate
        )

        if viewModel.showError {
            errorMessage = viewModel.errorMessage ?? "Failed to create invoice"
            showingError = true
        } else {
            dismiss()
        }
    }
}

#Preview {
    InvoiceFormView(viewModel: InvoiceViewModel())
}
