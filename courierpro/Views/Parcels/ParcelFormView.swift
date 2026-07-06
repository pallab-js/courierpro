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

    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Create New Parcel")
                .font(.title2)
                .fontWeight(.bold)

            Form {
                Section("Sender") {
                    Picker("Select Sender", selection: $selectedSender) {
                        Text("Choose a customer").tag(nil as Customer?)
                        ForEach(availableSenders) { customer in
                            Text(customer.name).tag(customer as Customer?)
                        }
                    }
                }

                Section("Receiver") {
                    Picker("Select Receiver", selection: $selectedReceiver) {
                        Text("Choose a customer").tag(nil as Customer?)
                        ForEach(availableReceivers) { customer in
                            Text(customer.name).tag(customer as Customer?)
                        }
                    }
                }

                Section("Details") {
                    HStack {
                        Text("Weight (kg):")
                        TextField("0.0", text: $weight)
                            .textFieldStyle(.roundedBorder)
                    }

                    HStack {
                        Text("Dimensions:")
                        TextField("e.g., 30x20x15 cm", text: $dimensions)
                            .textFieldStyle(.roundedBorder)
                    }

                    HStack {
                        Text("Notes:")
                        TextEditor(text: $notes)
                            .frame(height: 80)
                            .textFieldStyle(.roundedBorder)
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
        .frame(width: 500, height: 450)
        .task {
            await loadCustomers()
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }

    private func loadCustomers() async {
        let customerViewModel = CustomerViewModel()
        try? customerViewModel.loadCustomers()
        availableSenders = customerViewModel.customers
        availableReceivers = customerViewModel.customers
    }

    private func createParcel() {
        guard let sender = selectedSender,
              let receiver = selectedReceiver else {
            errorMessage = "Please select both sender and receiver"
            showingError = true
            return
        }

        let weightValue = Double(weight) ?? 0

        do {
            try viewModel.createParcel(
                sender: sender,
                receiver: receiver,
                weight: weightValue,
                dimensions: dimensions,
                notes: notes.isEmpty ? nil : notes
            )
            dismiss()
        } catch {
            errorMessage = "Failed to create parcel: \(error.localizedDescription)"
            showingError = true
        }
    }
}

#Preview {
    ParcelFormView(viewModel: ParcelViewModel())
}
