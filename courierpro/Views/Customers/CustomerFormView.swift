import SwiftUI

struct CustomerFormView: View {
    @ObservedObject var viewModel: CustomerViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var address = ""
    @State private var city = ""
    @State private var postalCode = ""

    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Add New Customer")
                .font(.title2)
                .fontWeight(.bold)

            Form {
                Section("Basic Info") {
                    HStack {
                        Text("Name:")
                        TextField("Company or person name", text: $name)
                            .textFieldStyle(.roundedBorder)
                    }

                    HStack {
                        Text("Email:")
                        TextField("info@company.in", text: $email)
                            .textFieldStyle(.roundedBorder)
                    }

                    HStack {
                        Text("Phone:")
                        TextField("9876543210", text: $phone)
                            .textFieldStyle(.roundedBorder)
                    }
                }

                Section("Address") {
                    HStack {
                        Text("Address:")
                        TextField("Street address, locality", text: $address)
                            .textFieldStyle(.roundedBorder)
                    }

                    HStack {
                        Text("City:")
                        TextField("e.g., Mumbai, Delhi, Bangalore", text: $city)
                            .textFieldStyle(.roundedBorder)
                    }

                    HStack {
                        Text("Postal Code:")
                        TextField("6-digit PIN code", text: $postalCode)
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

                Button("Add Customer") {
                    addCustomer()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.isEmpty)
            }
        }
        .padding()
        .frame(width: 450, height: 400)
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }

    private func addCustomer() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            errorMessage = "Customer name is required"
            showingError = true
            return
        }

        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedEmail.isEmpty {
            let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
            let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
            if !emailPredicate.evaluate(with: trimmedEmail) {
                errorMessage = "Please enter a valid email address"
                showingError = true
                return
            }
        }

        let trimmedPhone = phone.trimmingCharacters(in: .whitespaces)
        if !trimmedPhone.isEmpty {
            let digitsOnly = trimmedPhone.filter { $0.isNumber }
            if digitsOnly.count < 7 || digitsOnly.count > 15 {
                errorMessage = "Phone number must be 7-15 digits"
                showingError = true
                return
            }
        }

        let trimmedPostal = postalCode.trimmingCharacters(in: .whitespaces)
        if !trimmedPostal.isEmpty {
            if trimmedPostal.count < 3 || trimmedPostal.count > 10 || !trimmedPostal.allSatisfy(\.isNumber) {
                errorMessage = "Postal code must be 3-10 digits"
                showingError = true
                return
            }
        }

        viewModel.createCustomer(
            name: trimmedName,
            email: trimmedEmail,
            phone: phone.trimmingCharacters(in: .whitespaces),
            address: address.trimmingCharacters(in: .whitespacesAndNewlines),
            city: city.trimmingCharacters(in: .whitespacesAndNewlines),
            postalCode: trimmedPostal
        )
        dismiss()
    }
}

#Preview {
    CustomerFormView(viewModel: CustomerViewModel())
}
