import SwiftUI

struct PricingRuleListView: View {
    @StateObject private var viewModel = InvoiceViewModel()
    @State private var showingCreateSheet = false
    @State private var editingRule: PricingRule?
    @State private var deleteConfirmation: PricingRule?

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

            if viewModel.isLoadingPricingRules {
                LoadingView()
            } else if viewModel.pricingRules.isEmpty {
                EmptyStateView(
                    icon: "dollarsign.circle",
                    title: "No Pricing Rules",
                    message: "Create your first pricing rule to get started",
                    actionTitle: "Create Rule",
                    action: { showingCreateSheet = true }
                )
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
                                viewModel.updatePricingRule(
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
                                deleteConfirmation = rule
                            }
                        }
                    }
                }
            }
        }
        .task {
            viewModel.loadPricingRules()
        }
        .sheet(isPresented: $showingCreateSheet) {
            PricingRuleFormView(viewModel: viewModel)
        }
        .sheet(item: $editingRule) { rule in
            PricingRuleEditView(rule: rule, viewModel: viewModel)
        }
        .alert("Delete Pricing Rule", isPresented: Binding(
            get: { deleteConfirmation != nil },
            set: { if !$0 { deleteConfirmation = nil } }
        )) {
            Button("Cancel", role: .cancel) { deleteConfirmation = nil }
            Button("Delete", role: .destructive) {
                if let rule = deleteConfirmation {
                    viewModel.deletePricingRule(rule)
                    deleteConfirmation = nil
                }
            }
        } message: {
            if let rule = deleteConfirmation {
                Text("Are you sure you want to delete pricing rule \"\(rule.name)\"? This action cannot be undone.")
            }
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(rule.name), \(rule.pricingType.displayName), \(AppSettings.shared.currencySymbol)\(String(format: "%.2f", rule.basePrice)), \(rule.isActive ? "Active" : "Inactive")")
        .accessibilityHint("Double tap to edit")
    }
}

#Preview {
    PricingRuleListView()
        .frame(width: 700, height: 500)
}
