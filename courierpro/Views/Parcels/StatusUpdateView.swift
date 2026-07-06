import SwiftUI
import SwiftData

struct StatusUpdateView: View {
    let parcel: Parcel
    @ObservedObject var viewModel: ParcelViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedStatus: DeliveryStatus
    @State private var notes: String = ""
    @State private var updatedBy: String = ""

    @State private var showingError = false
    @State private var errorMessage = ""

    init(parcel: Parcel, viewModel: ParcelViewModel) {
        self.parcel = parcel
        self.viewModel = viewModel
        _selectedStatus = State(initialValue: parcel.status)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Update Status")
                .font(.title2)
                .fontWeight(.bold)

            Text(parcel.trackingNumber)
                .fontDesign(.monospaced)
                .foregroundColor(.secondary)

            Form {
                Section("New Status") {
                    Picker("Status", selection: $selectedStatus) {
                        ForEach(DeliveryStatus.allCases) { status in
                            HStack {
                                Image(systemName: status.systemImage)
                                Text(status.displayName)
                            }
                            .tag(status)
                        }
                    }
                    .pickerStyle(.radioGroup)
                }

                Section("Details") {
                    HStack {
                        Text("Updated By:")
                        TextField("Your name", text: $updatedBy)
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

                Button("Update Status") {
                    updateStatus()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(selectedStatus == parcel.status)
            }
        }
        .padding()
        .frame(width: 450, height: 420)
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }

    private func updateStatus() {
        guard selectedStatus != parcel.status else {
            errorMessage = "Status is already \(selectedStatus.displayName)"
            showingError = true
            return
        }

        let history = StatusHistory(
            status: selectedStatus,
            notes: notes.isEmpty ? nil : notes,
            updatedBy: updatedBy.isEmpty ? nil : updatedBy,
            parcel: parcel
        )
        PersistenceService.shared.insert(history)

        do {
            try viewModel.updateParcelStatus(parcel, status: selectedStatus)
            dismiss()
        } catch {
            errorMessage = "Failed to update status: \(error.localizedDescription)"
            showingError = true
        }
    }
}

#Preview {
    StatusUpdateView(
        parcel: Parcel(trackingNumber: "CP-123456"),
        viewModel: ParcelViewModel()
    )
}
