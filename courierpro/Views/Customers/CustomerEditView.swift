import SwiftUI

struct CustomerEditView: View {
    let customer: Customer
    @ObservedObject var viewModel: CustomerViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var email: String
    @State private var phone: String
    @State private var address: String
    @State private var city: String
    @State private var postalCode: String

    @State private var showingError = false
    @State private var errorMessage = ""

    init(customer: Customer, viewModel: CustomerViewModel) {
        self.customer = customer
        self.viewModel = viewModel
        _name = State(initialValue: customer.name)
        _email = State(initialValue: customer.email)
        _phone = State(initialValue: customer.phone)
        _address = State(initialValue: customer.address)
        _city = State(initialValue: customer.city)
        _postalCode = State(initialValue: customer.postalCode)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Edit Customer")
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

                Button("Save Changes") {
                    saveChanges()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.isEmpty)
            }
        }
        .padding()
        .frame(minWidth: 400, minHeight: 360)
        .errorAlert(isPresented: $showingError, message: errorMessage)
    }

    private func saveChanges() {
        guard !name.isEmpty else {
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
        if !trimmedPhone.isEmpty && !CSVUtilities.validatePhoneNumber(trimmedPhone) {
            errorMessage = "Phone number must be 7-15 digits"
            showingError = true
            return
        }

        let trimmedPostal = postalCode.trimmingCharacters(in: .whitespaces)
        if !trimmedPostal.isEmpty {
            if trimmedPostal.count < 3 || trimmedPostal.count > 10 || !trimmedPostal.allSatisfy(\.isNumber) {
                errorMessage = "Postal code must be 3-10 digits"
                showingError = true
                return
            }
        }

        viewModel.updateCustomer(
            customer,
            name: name,
            email: email,
            phone: phone,
            address: address,
            city: city,
            postalCode: postalCode
        )
        dismiss()
    }
}

#Preview {
    CustomerEditView(
        customer: Customer(name: "Test Customer"),
        viewModel: CustomerViewModel()
    )
}
