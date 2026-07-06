import SwiftUI
import SwiftData

struct ParcelEditView: View {
    let parcel: Parcel
    @ObservedObject var viewModel: ParcelViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var weight: String
    @State private var dimensions: String
    @State private var notes: String
    @State private var selectedSender: Customer?
    @State private var selectedReceiver: Customer?
    @State private var selectedDriver: Driver?

    @State private var availableSenders: [Customer] = []
    @State private var availableReceivers: [Customer] = []
    @State private var availableDrivers: [Driver] = []

    @State private var showingError = false
    @State private var errorMessage = ""

    init(parcel: Parcel, viewModel: ParcelViewModel) {
        self.parcel = parcel
        self.viewModel = viewModel
        _weight = State(initialValue: String(format: "%.1f", parcel.weight))
        _dimensions = State(initialValue: parcel.dimensions)
        _notes = State(initialValue: parcel.notes ?? "")
        _selectedSender = State(initialValue: parcel.sender)
        _selectedReceiver = State(initialValue: parcel.receiver)
        _selectedDriver = State(initialValue: parcel.driver)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Edit Parcel")
                .font(.title2)
                .fontWeight(.bold)

            Form {
                Section("Tracking Info") {
                    HStack {
                        Text("Tracking #:")
                        Text(parcel.trackingNumber)
                            .fontDesign(.monospaced)
                            .foregroundColor(.secondary)
                    }
                }

                Section("Contacts") {
                    Picker("Sender", selection: $selectedSender) {
                        Text("Choose a customer").tag(nil as Customer?)
                        ForEach(availableSenders) { customer in
                            Text(customer.name).tag(customer as Customer?)
                        }
                    }

                    Picker("Receiver", selection: $selectedReceiver) {
                        Text("Choose a customer").tag(nil as Customer?)
                        ForEach(availableReceivers) { customer in
                            Text(customer.name).tag(customer as Customer?)
                        }
                    }

                    Picker("Driver", selection: $selectedDriver) {
                        Text("Unassigned").tag(nil as Driver?)
                        ForEach(availableDrivers) { driver in
                            Text(driver.name).tag(driver as Driver?)
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

                Button("Save Changes") {
                    saveChanges()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 500, height: 480)
        .task {
            await loadCustomers()
            await loadDrivers()
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

    private func loadDrivers() async {
        let descriptor = FetchDescriptor<Driver>()
        if let drivers = try? PersistenceService.shared.fetch(descriptor) {
            availableDrivers = drivers
        }
    }

    private func saveChanges() {
        guard let sender = selectedSender,
              let receiver = selectedReceiver else {
            errorMessage = "Please select both sender and receiver"
            showingError = true
            return
        }

        let weightValue = Double(weight) ?? 0

        parcel.sender = sender
        parcel.receiver = receiver
        parcel.driver = selectedDriver
        parcel.weight = weightValue
        parcel.dimensions = dimensions
        parcel.notes = notes.isEmpty ? nil : notes
        parcel.updatedAt = Date()

        do {
            try PersistenceService.shared.save()
            try viewModel.loadParcels()
            dismiss()
        } catch {
            errorMessage = "Failed to save changes: \(error.localizedDescription)"
            showingError = true
        }
    }
}

#Preview {
    ParcelEditView(
        parcel: Parcel(trackingNumber: "CP-123456"),
        viewModel: ParcelViewModel()
    )
}
