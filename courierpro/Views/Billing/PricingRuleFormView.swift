import SwiftUI

struct PricingRuleFormView: View {
    @ObservedObject var viewModel: InvoiceViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var selectedType: PricingType = .flatRate
    @State private var basePrice: String = "10"
    @State private var pricePerUnit: String = "2"
    @State private var minimumWeight: String = "0"
    @State private var maximumWeight: String = "100"

    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Add Pricing Rule")
                .font(.title2)
                .fontWeight(.bold)

            Form {
                Section("Rule Info") {
                    HStack {
                        Text("Name:")
                        TextField("e.g., Standard Delivery", text: $name)
                            .textFieldStyle(.roundedBorder)
                    }

                    Picker("Pricing Type", selection: $selectedType) {
                        ForEach(PricingType.allCases) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                }

                Section("Pricing") {
                    HStack {
                        Text("Base Price (\(AppSettings.shared.currencySymbol)):")
                        TextField("10", text: $basePrice)
                            .textFieldStyle(.roundedBorder)
                    }

                    if selectedType != .flatRate {
                        HStack {
                            Text("Price per \(selectedType == .perKg ? "kg" : "km") (\(AppSettings.shared.currencySymbol)):")
                            TextField("2", text: $pricePerUnit)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                }

                Section("Weight Range (kg)") {
                    HStack {
                        Text("Minimum:")
                        TextField("0", text: $minimumWeight)
                            .textFieldStyle(.roundedBorder)
                    }
                    HStack {
                        Text("Maximum:")
                        TextField("100", text: $maximumWeight)
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

                Button("Add Rule") {
                    addRule()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.isEmpty)
            }
        }
        .padding()
        .frame(minWidth: 400, minHeight: 380)
        .errorAlert(isPresented: $showingError, message: errorMessage)
    }

    private func addRule() {
        guard !name.isEmpty else {
            errorMessage = "Rule name is required"
            showingError = true
            return
        }

        viewModel.createPricingRule(
            name: name,
            pricingType: selectedType,
            basePrice: Double(basePrice) ?? 0,
            pricePerUnit: Double(pricePerUnit) ?? 0,
            minimumWeight: Double(minimumWeight) ?? 0,
            maximumWeight: Double(maximumWeight) ?? 100
        )

        if viewModel.showError {
            errorMessage = viewModel.errorMessage ?? "Failed to add rule"
            showingError = true
        } else {
            dismiss()
        }
    }
}

#Preview {
    PricingRuleFormView(viewModel: InvoiceViewModel())
}
