import SwiftUI

struct ParcelFormView: View {
    @ObservedObject var viewModel: ParcelViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var senderName = ""
    @State private var receiverName = ""
    @State private var weight = ""
    @State private var dimensions = ""
    @State private var notes = ""

    @State private var availableSenders: [Customer] = []
    @State private var availableReceivers: [Customer] = []
    @State private var selectedSender: Customer?
    @State private var selectedReceiver: Customer?
    @State private var isLoadingCustomers = true

    @State private var showingError = false
    @State private var errorMessage = ""
    @FocusState private var focusedField: Field?

    private enum Field {
        case weight, dimensions, notes
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Create New Parcel")
                .font(.title2)
                .fontWeight(.bold)

            Form {
                Section("Sender") {
                    if isLoadingCustomers {
                        HStack {
                            ProgressView()
                                .controlSize(.small)
                            Text("Loading customers...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Picker("Select Sender", selection: $selectedSender) {
                            Text("Choose a customer").tag(nil as Customer?)
                            ForEach(availableSenders) { customer in
                                Text(customer.name).tag(customer as Customer?)
                            }
                        }
                    }
                }

                Section("Receiver") {
                    if isLoadingCustomers {
                        HStack {
                            ProgressView()
                                .controlSize(.small)
                            Text("Loading customers...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Picker("Select Receiver", selection: $selectedReceiver) {
                            Text("Choose a customer").tag(nil as Customer?)
                            ForEach(availableReceivers) { customer in
                                Text(customer.name).tag(customer as Customer?)
                            }
                        }
                    }
                }

                Section("Details") {
                    HStack {
                        Text("Weight (kg):")
                        TextField("0.0", text: $weight)
                            .textFieldStyle(.roundedBorder)
                            .focused($focusedField, equals: .weight)
                    }

                    HStack {
                        Text("Dimensions:")
                        TextField("e.g., 30x20x15 cm", text: $dimensions)
                            .textFieldStyle(.roundedBorder)
                            .focused($focusedField, equals: .dimensions)
                            .onChange(of: dimensions) { _, newValue in
                                dimensions = String(newValue.prefix(200))
                            }
                    }

                    HStack {
                        Text("Notes:")
                        TextEditor(text: $notes)
                            .frame(height: 80)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: notes) { _, newValue in
                                notes = String(newValue.prefix(1000))
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

                Button("Create Parcel") {
                    createParcel()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(selectedSender == nil || selectedReceiver == nil)
            }
        }
        .padding()
        .frame(minWidth: 450, minHeight: 400)
        .task {
            await loadCustomers()
            focusedField = .weight
        }
        .errorAlert(isPresented: $showingError, message: errorMessage)
    }

    private func loadCustomers() async {
        let customerViewModel = CustomerViewModel()
        customerViewModel.loadCustomers()
        availableSenders = customerViewModel.customers
        availableReceivers = customerViewModel.customers
        isLoadingCustomers = false
    }

    private func createParcel() {
        guard let sender = selectedSender,
              let receiver = selectedReceiver else {
            errorMessage = "Please select both sender and receiver"
            showingError = true
            return
        }

        guard !weight.isEmpty,
              let weightValue = Double(weight),
              weightValue.isFinite,
              weightValue >= 0,
              weightValue <= 10_000 else {
            errorMessage = "Please enter a valid weight (0-10000 kg)"
            showingError = true
            return
        }

        viewModel.createParcel(
            sender: sender,
            receiver: receiver,
            weight: weightValue,
            dimensions: dimensions,
            notes: notes.isEmpty ? nil : notes
        )

        if viewModel.showError {
            errorMessage = viewModel.errorMessage ?? "Failed to create parcel"
            showingError = true
        } else {
            dismiss()
        }
    }
}

#Preview {
    ParcelFormView(viewModel: ParcelViewModel())
}
