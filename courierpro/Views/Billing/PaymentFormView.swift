import SwiftUI

struct PaymentFormView: View {
    let invoice: Invoice
    @ObservedObject var viewModel: InvoiceViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var amount: String = ""
    @State private var selectedMethod: PaymentMethod = .cash
    @State private var reference: String = ""
    @State private var notes: String = ""

    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Record Payment")
                .font(.title2)
                .fontWeight(.bold)

            Text("Invoice: \(invoice.invoiceNumber)")
                .font(.subheadline)
                .fontDesign(.monospaced)
                .foregroundColor(.secondary)

            Text("Balance Due: \(AppSettings.shared.currencySymbol)\(String(format: "%.2f", invoice.balanceDue))")
                .font(.headline)
                .foregroundColor(.orange)

            Form {
                Section("Payment Details") {
                    HStack {
                        Text("Amount:")
                        TextField("0.00", text: $amount)
                            .textFieldStyle(.roundedBorder)
                    }

                    Picker("Payment Method", selection: $selectedMethod) {
                        ForEach(PaymentMethod.allCases) { method in
                            HStack {
                                Image(systemName: method.systemImage)
                                Text(method.displayName)
                            }
                            .tag(method)
                        }
                    }

                    HStack {
                        Text("Reference:")
                        TextField("Optional reference number", text: $reference)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: reference) { _, newValue in
                                reference = String(newValue.prefix(200))
                            }
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

                Button("Record Payment") {
                    recordPayment()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(Double(amount) == nil || (Double(amount) ?? 0) <= 0)
            }
        }
        .padding()
        .frame(minWidth: 400, minHeight: 380)
        .errorAlert(isPresented: $showingError, message: errorMessage)
    }

    private func recordPayment() {
        guard let amountValue = Double(amount), amountValue.isFinite, amountValue > 0 else {
            errorMessage = "Please enter a valid amount"
            showingError = true
            return
        }

        guard amountValue <= invoice.balanceDue else {
            errorMessage = "Payment amount exceeds balance due"
            showingError = true
            return
        }

        viewModel.addPayment(
            to: invoice,
            amount: amountValue,
            method: selectedMethod,
            reference: reference.isEmpty ? nil : reference.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        if viewModel.showError {
            errorMessage = viewModel.errorMessage ?? "Failed to record payment"
            showingError = true
        } else {
            dismiss()
        }
    }
}

#Preview {
    PaymentFormView(
        invoice: Invoice(invoiceNumber: "INV-123456"),
        viewModel: InvoiceViewModel()
    )
}
