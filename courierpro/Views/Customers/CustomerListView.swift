import SwiftUI

struct CustomerListView: View {
    @StateObject private var viewModel = CustomerViewModel()
    @State private var showingCreateSheet = false
    @State private var selectedCustomer: Customer?
    @State private var deleteConfirmation: Customer?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Customers")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Spacer()
                Button(action: { showingCreateSheet = true }) {
                    Label("New Customer", systemImage: "plus")
                }
            }
            .padding()

            Divider()

            HStack {
                SearchField(text: $viewModel.searchText, placeholder: "Search customers...")
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

            if viewModel.isLoading {
                LoadingView()
            } else if viewModel.filteredCustomers.isEmpty {
                EmptyStateView(
                    icon: "person.2",
                    title: viewModel.customers.isEmpty ? "No Customers Yet" : "No Customers Found",
                    message: viewModel.customers.isEmpty
                        ? "Add your first customer to start managing contacts"
                        : "Try adjusting your search criteria",
                    actionTitle: viewModel.customers.isEmpty ? "Add Customer" : nil,
                    action: viewModel.customers.isEmpty ? { showingCreateSheet = true } : nil
                )
            } else {
                Table(viewModel.filteredCustomers) {
                    TableColumn("Name") { customer in
                        Text(customer.name)
                            .fontWeight(.medium)
                    }
                    .width(min: 150)

                    TableColumn("Email") { customer in
                        Text(customer.email)
                    }
                    .width(min: 180)

                    TableColumn("Phone") { customer in
                        Text(customer.phone)
                    }
                    .width(min: 120)

                    TableColumn("City") { customer in
                        Text(customer.city)
                    }
                    .width(min: 120)

                    TableColumn("Created") { customer in
                        Text(customer.createdAt, style: .date)
                    }
                    .width(min: 100)
                }
                .contextMenu(forSelectionType: Customer.self) { selection in
                    if let customer = selection.first {
                        Button("Edit") {
                            selectedCustomer = customer
                        }
                        Divider()
                        Button("Delete", role: .destructive) {
                            deleteConfirmation = customer
                        }
                    }
                }
            }
        }
        .task {
            viewModel.loadCustomers()
        }
        .sheet(isPresented: $showingCreateSheet) {
            CustomerFormView(viewModel: viewModel)
        }
        .sheet(item: $selectedCustomer) { customer in
            CustomerEditView(customer: customer, viewModel: viewModel)
        }
        .errorAlert(isPresented: $viewModel.showError, message: viewModel.errorMessage)
        .alert("Delete Customer", isPresented: Binding(
            get: { deleteConfirmation != nil },
            set: { if !$0 { deleteConfirmation = nil } }
        )) {
            Button("Cancel", role: .cancel) { deleteConfirmation = nil }
            Button("Delete", role: .destructive) {
                if let customer = deleteConfirmation {
                    viewModel.deleteCustomer(customer)
                    deleteConfirmation = nil
                }
            }
        } message: {
            if let customer = deleteConfirmation {
                Text("Are you sure you want to delete customer \(customer.name)? This action cannot be undone.")
            }
        }
    }
}

#Preview {
    CustomerListView()
        .frame(width: 800, height: 500)
}
