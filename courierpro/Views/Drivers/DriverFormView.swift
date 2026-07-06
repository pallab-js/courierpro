import SwiftUI

struct DriverFormView: View {
    @ObservedObject var viewModel: DriverViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var phone = ""
    @State private var licenseNumber = ""
    @State private var isAvailable = true

    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Add New Driver")
                .font(.title2)
                .fontWeight(.bold)

            Form {
                Section("Driver Info") {
                    HStack {
                        Text("Name:")
                        TextField("Full name", text: $name)
                            .textFieldStyle(.roundedBorder)
                    }

                    HStack {
                        Text("Phone:")
                        TextField("555-1000", text: $phone)
                            .textFieldStyle(.roundedBorder)
                    }

                    HStack {
                        Text("License #:")
                        TextField("DL-001", text: $licenseNumber)
                            .textFieldStyle(.roundedBorder)
                    }

                    Toggle("Available for dispatch", isOn: $isAvailable)
                }
            }
            .formStyle(.grouped)

            HStack {
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button("Add Driver") {
                    addDriver()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.isEmpty || licenseNumber.isEmpty)
            }
        }
        .padding()
        .frame(width: 420, height: 320)
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }

    private func addDriver() {
        guard !name.isEmpty, !licenseNumber.isEmpty else {
            errorMessage = "Name and license number are required"
            showingError = true
            return
        }

        do {
            try viewModel.createDriver(
                name: name,
                phone: phone,
                licenseNumber: licenseNumber,
                isAvailable: isAvailable
            )
            dismiss()
        } catch {
            errorMessage = "Failed to add driver: \(error.localizedDescription)"
            showingError = true
        }
    }
}

#Preview {
    DriverFormView(viewModel: DriverViewModel())
}
