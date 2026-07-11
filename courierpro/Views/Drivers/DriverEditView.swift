import SwiftUI

struct DriverEditView: View {
    let driver: Driver
    @ObservedObject var viewModel: DriverViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var phone: String
    @State private var licenseNumber: String
    @State private var isAvailable: Bool

    @State private var showingError = false
    @State private var errorMessage = ""

    init(driver: Driver, viewModel: DriverViewModel) {
        self.driver = driver
        self.viewModel = viewModel
        _name = State(initialValue: driver.name)
        _phone = State(initialValue: driver.phone)
        _licenseNumber = State(initialValue: driver.licenseNumber)
        _isAvailable = State(initialValue: driver.isAvailable)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Edit Driver")
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
                        TextField("9876543210", text: $phone)
                            .textFieldStyle(.roundedBorder)
                    }

                    HStack {
                        Text("License #:")
                        TextField("e.g., DL-MH-001", text: $licenseNumber)
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

                Button("Save Changes") {
                    saveChanges()
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

    private func saveChanges() {
        guard !name.isEmpty, !licenseNumber.isEmpty else {
            errorMessage = "Name and license number are required"
            showingError = true
            return
        }

        let trimmedPhone = phone.trimmingCharacters(in: .whitespaces)
        if !trimmedPhone.isEmpty {
            let digitsOnly = trimmedPhone.filter { $0.isNumber }
            if digitsOnly.count != 10 {
                errorMessage = "Phone number must be 10 digits"
                showingError = true
                return
            }
        }

        viewModel.updateDriver(
            driver,
            name: name,
            phone: phone,
            licenseNumber: licenseNumber,
            isAvailable: isAvailable
        )
        dismiss()
    }
}

#Preview {
    DriverEditView(
        driver: Driver(name: "Rajesh Kumar", licenseNumber: "DL-MH-001"),
        viewModel: DriverViewModel()
    )
}
