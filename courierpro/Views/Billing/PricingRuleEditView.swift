import SwiftUI

struct PricingRuleEditView: View {
    let rule: PricingRule
    @ObservedObject var viewModel: InvoiceViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var selectedType: PricingType
    @State private var basePrice: String
    @State private var pricePerUnit: String
    @State private var minimumWeight: String
    @State private var maximumWeight: String
    @State private var isActive: Bool

    @State private var showingError = false
    @State private var errorMessage = ""

    init(rule: PricingRule, viewModel: InvoiceViewModel) {
        self.rule = rule
        self.viewModel = viewModel
        _name = State(initialValue: rule.name)
        _selectedType = State(initialValue: rule.pricingType)
        _basePrice = State(initialValue: String(format: "%.2f", rule.basePrice))
        _pricePerUnit = State(initialValue: String(format: "%.2f", rule.pricePerUnit))
        _minimumWeight = State(initialValue: String(format: "%.0f", rule.minimumWeight))
        _maximumWeight = State(initialValue: String(format: "%.0f", rule.maximumWeight))
        _isActive = State(initialValue: rule.isActive)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Edit Pricing Rule")
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

                    Toggle("Active", isOn: $isActive)
                }

                Section("Pricing") {
                    HStack {
                        Text("Base Price ($):")
                        TextField("10", text: $basePrice)
                            .textFieldStyle(.roundedBorder)
                    }

                    if selectedType != .flatRate {
                        HStack {
                            Text("Price per \(selectedType == .perKg ? "kg" : "km") ($):")
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

                Button("Save Changes") {
                    saveChanges()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.isEmpty)
            }
        }
        .padding()
        .frame(width: 450, height: 450)
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }

    private func saveChanges() {
        guard !name.isEmpty else {
            errorMessage = "Rule name is required"
            showingError = true
            return
        }

        do {
            try viewModel.updatePricingRule(
                rule,
                name: name,
                pricingType: selectedType,
                basePrice: Double(basePrice) ?? 0,
                pricePerUnit: Double(pricePerUnit) ?? 0,
                minimumWeight: Double(minimumWeight) ?? 0,
                maximumWeight: Double(maximumWeight) ?? 100,
                isActive: isActive
            )
            dismiss()
        } catch {
            errorMessage = "Failed to save changes: \(error.localizedDescription)"
            showingError = true
        }
    }
}

#Preview {
    PricingRuleEditView(
        rule: PricingRule(name: "Standard", pricingType: .perKg, basePrice: 10, pricePerUnit: 2),
        viewModel: InvoiceViewModel()
    )
}
