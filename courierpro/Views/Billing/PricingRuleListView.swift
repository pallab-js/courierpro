import SwiftUI

struct PricingRuleListView: View {
    @StateObject private var viewModel = InvoiceViewModel()
    @State private var showingCreateSheet = false
    @State private var editingRule: PricingRule?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Pricing Rules")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Spacer()
                Button(action: { showingCreateSheet = true }) {
                    Label("New Rule", systemImage: "plus")
                }
            }
            .padding()

            Divider()

            if viewModel.pricingRules.isEmpty {
                VStack {
                    Image(systemName: "dollarsign.circle")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No pricing rules")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text("Create your first pricing rule to get started")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(viewModel.pricingRules) { rule in
                        PricingRuleRow(rule: rule) {
                            editingRule = rule
                        }
                        .contextMenu {
                            Button("Edit") {
                                editingRule = rule
                            }
                            Button(rule.isActive ? "Deactivate" : "Activate") {
                                try? viewModel.updatePricingRule(
                                    rule,
                                    name: rule.name,
                                    pricingType: rule.pricingType,
                                    basePrice: rule.basePrice,
                                    pricePerUnit: rule.pricePerUnit,
                                    minimumWeight: rule.minimumWeight,
                                    maximumWeight: rule.maximumWeight,
                                    isActive: !rule.isActive
                                )
                            }
                            Divider()
                            Button("Delete", role: .destructive) {
                                try? viewModel.deletePricingRule(rule)
                            }
                        }
                    }
                }
            }
        }
        .task {
            try? viewModel.loadPricingRules()
        }
        .sheet(isPresented: $showingCreateSheet) {
            PricingRuleFormView(viewModel: viewModel)
        }
        .sheet(item: $editingRule) { rule in
            PricingRuleEditView(rule: rule, viewModel: viewModel)
        }
    }
}

struct PricingRuleRow: View {
    let rule: PricingRule
    let onSelect: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(rule.isActive ? Color.green : Color.gray)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(rule.name)
                    .font(.body)
                    .fontWeight(.medium)
                Text(rule.pricingType.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                if rule.pricingType == .flatRate {
                    Text("\(AppSettings.shared.currencySymbol)\(String(format: "%.2f", rule.basePrice))")
                        .font(.body)
                        .fontWeight(.medium)
                } else {
                    Text("\(AppSettings.shared.currencySymbol)\(String(format: "%.2f", rule.basePrice)) + \(AppSettings.shared.currencySymbol)\(String(format: "%.2f", rule.pricePerUnit))/\(rule.pricingType == .perKg ? "kg" : "km")")
                        .font(.body)
                        .fontWeight(.medium)
                }
                Text("Weight: \(Int(rule.minimumWeight))-\(Int(rule.maximumWeight)) kg")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
    }
}

#Preview {
    PricingRuleListView()
        .frame(width: 700, height: 500)
}
