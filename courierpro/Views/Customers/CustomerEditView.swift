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
        .frame(width: 450, height: 400)
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }

    private func saveChanges() {
        guard !name.isEmpty else {
            errorMessage = "Customer name is required"
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

        let trimmedPostal = postalCode.trimmingCharacters(in: .whitespaces)
        if !trimmedPostal.isEmpty && trimmedPostal.count != 6 {
            errorMessage = "PIN code must be 6 digits"
            showingError = true
            return
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
