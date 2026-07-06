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
                        TextField("email@example.com", text: $email)
                            .textFieldStyle(.roundedBorder)
                    }

                    HStack {
                        Text("Phone:")
                        TextField("555-0100", text: $phone)
                            .textFieldStyle(.roundedBorder)
                    }
                }

                Section("Address") {
                    HStack {
                        Text("Address:")
                        TextField("Street address", text: $address)
                            .textFieldStyle(.roundedBorder)
                    }

                    HStack {
                        Text("City:")
                        TextField("City", text: $city)
                            .textFieldStyle(.roundedBorder)
                    }

                    HStack {
                        Text("Postal Code:")
                        TextField("12345", text: $postalCode)
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
        guard !name.isEmpty else {
            errorMessage = "Customer name is required"
            showingError = true
            return
        }

        do {
            try viewModel.createCustomer(
                name: name,
                email: email,
                phone: phone,
                address: address,
                city: city,
                postalCode: postalCode
            )
            dismiss()
        } catch {
            errorMessage = "Failed to add customer: \(error.localizedDescription)"
            showingError = true
        }
    }
}

#Preview {
    CustomerFormView(viewModel: CustomerViewModel())
}
