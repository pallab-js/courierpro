import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showingResetConfirmation = false
    @State private var savedSuccessfully = false
    @State private var taxRateString = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Settings")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                businessInfoSection
                currencySection
                invoiceDefaultsSection
                trackingSection

                HStack {
                    Spacer()
                    Button("Reset to Defaults", role: .destructive) {
                        showingResetConfirmation = true
                    }

                    Button("Save Changes") {
                        if let rate = Double(taxRateString), rate.isFinite, rate >= 0, rate <= 100 {
                            viewModel.settings.taxRate = rate
                        }
                        viewModel.settings.trackingPrefix = viewModel.settings.trackingPrefix
                            .filter { $0.isLetter || $0.isNumber }
                            .prefix(10)
                            .description
                        viewModel.save()
                        savedSuccessfully = true
                    }
                    .buttonStyle(.borderedProminent)

                    if savedSuccessfully {
                        Text("Saved!")
                            .foregroundColor(.green)
                            .fontWeight(.medium)
                    }
                }
            }
            .padding()
        }
        .onAppear {
            taxRateString = String(format: "%.1f", viewModel.settings.taxRate)
        }
        .task(id: savedSuccessfully) {
            if savedSuccessfully {
                try? await Task.sleep(for: .seconds(2))
                savedSuccessfully = false
            }
        }
        .alert("Reset Settings", isPresented: $showingResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                viewModel.resetToDefaults()
                taxRateString = String(format: "%.1f", viewModel.settings.taxRate)
            }
        } message: {
            Text("Are you sure you want to reset all settings to defaults? This cannot be undone.")
        }
        .errorAlert(isPresented: $viewModel.showError, message: viewModel.errorMessage)
    }

    private var businessInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Business Information")
                .font(.title2)
                .fontWeight(.semibold)

            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    LabeledContent("Business Name") {
                        TextField("e.g., Quick Deliver India Pvt Ltd", text: $viewModel.settings.businessName)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 300)
                    }

                    LabeledContent("Address") {
                        TextField("e.g., Andheri East, Mumbai 400069", text: $viewModel.settings.businessAddress)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 400)
                    }

                    LabeledContent("Phone") {
                        TextField("9876543210", text: $viewModel.settings.businessPhone)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 200)
                    }

                    LabeledContent("Email") {
                        TextField("info@yourcompany.in", text: $viewModel.settings.businessEmail)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 300)
                    }
                }
                .padding(8)
            }
        }
    }

    private var currencySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Currency")
                .font(.title2)
                .fontWeight(.semibold)

            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    LabeledContent("Currency") {
                        Picker("Currency", selection: $viewModel.settings.currencyCode) {
                            ForEach(SettingsViewModel.currencies, id: \.code) { currency in
                                Text("\(currency.symbol) \(currency.name) (\(currency.code))")
                                    .tag(currency.code)
                            }
                        }
                        .frame(maxWidth: 300)
                        .onChange(of: viewModel.settings.currencyCode) { _, newValue in
                            if let currency = SettingsViewModel.currencies.first(where: { $0.code == newValue }) {
                                viewModel.settings.currencySymbol = currency.symbol
                            }
                        }
                    }

                    LabeledContent("Symbol") {
                        TextField("Currency symbol", text: $viewModel.settings.currencySymbol)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 60)
                    }
                }
                .padding(8)
            }
        }
    }

    private var invoiceDefaultsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Invoice Defaults")
                .font(.title2)
                .fontWeight(.semibold)

            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    LabeledContent("Default Tax Rate (%)") {
                        TextField("0.0", text: $taxRateString)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                    }

                    LabeledContent("Default Notes") {
                        TextEditor(text: $viewModel.settings.defaultNotes)
                            .frame(height: 80)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.secondary.opacity(0.2))
                            )
                    }
                }
                .padding(8)
            }
        }
    }

    private var trackingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tracking")
                .font(.title2)
                .fontWeight(.semibold)

            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    LabeledContent("Tracking Prefix") {
                        TextField("CP", text: $viewModel.settings.trackingPrefix)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                    }

                    Text("Example: \(viewModel.settings.trackingPrefix)-\(String(Int(Date().timeIntervalSince1970).description.suffix(6)))-0001")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(8)
            }
        }
    }
}

#Preview {
    SettingsView()
        .frame(width: 600, height: 600)
}
