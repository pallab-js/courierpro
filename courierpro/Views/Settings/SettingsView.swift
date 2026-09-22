import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showingResetConfirmation = false
    @State private var savedSuccessfully = false
    @State private var taxRateString = ""

    private let fieldWidth: CGFloat = 280

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerBar
                businessInfoSection
                currencySection
                invoiceDefaultsSection
                trackingSection
            }
            .padding(24)
        }
        .background(Color(NSColor.controlBackgroundColor))
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

    // MARK: - Header

    private var headerBar: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Settings")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("Manage your business preferences")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            HStack(spacing: 12) {
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
    }

    // MARK: - Business Info

    private var businessInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Business Information")
                .font(.headline)

            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    formField(label: "Business Name", placeholder: "e.g., Quick Deliver India Pvt Ltd", text: $viewModel.settings.businessName, width: fieldWidth)
                    formField(label: "Address", placeholder: "e.g., Andheri East, Mumbai 400069", text: $viewModel.settings.businessAddress, width: fieldWidth)
                    formField(label: "Phone", placeholder: "9876543210", text: $viewModel.settings.businessPhone, width: fieldWidth)
                    formField(label: "Email", placeholder: "info@yourcompany.in", text: $viewModel.settings.businessEmail, width: fieldWidth)
                }
                .padding(12)
            }
        }
    }

    // MARK: - Currency

    private var currencySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Currency")
                .font(.headline)

            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    LabeledContent("Currency") {
                        Picker("Currency", selection: $viewModel.settings.currencyCode) {
                            ForEach(SettingsViewModel.currencies, id: \.code) { currency in
                                Text("\(currency.symbol) \(currency.name) (\(currency.code))")
                                    .tag(currency.code)
                            }
                        }
                        .frame(maxWidth: fieldWidth)
                        .onChange(of: viewModel.settings.currencyCode) { _, newValue in
                            if let currency = SettingsViewModel.currencies.first(where: { $0.code == newValue }) {
                                viewModel.settings.currencySymbol = currency.symbol
                            }
                        }
                    }

                    formField(label: "Symbol", placeholder: "$", text: $viewModel.settings.currencySymbol, width: 60)
                }
                .padding(12)
            }
        }
    }

    // MARK: - Invoice Defaults

    private var invoiceDefaultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Invoice Defaults")
                .font(.headline)

            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    formField(label: "Default Tax Rate (%)", placeholder: "0.0", text: $taxRateString, width: 100)

                    LabeledContent("Default Notes") {
                        TextEditor(text: $viewModel.settings.defaultNotes)
                            .frame(height: 80)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.secondary.opacity(0.2))
                            )
                    }
                }
                .padding(12)
            }
        }
    }

    // MARK: - Tracking

    private var trackingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tracking")
                .font(.headline)

            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    formField(label: "Tracking Prefix", placeholder: "CP", text: $viewModel.settings.trackingPrefix, width: 80)

                    Text("Example: \(viewModel.settings.trackingPrefix)-\(String(Int(Date().timeIntervalSince1970).description.suffix(6)))-0001")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(12)
            }
        }
    }

    // MARK: - Helpers

    private func formField(label: String, placeholder: String, text: Binding<String>, width: CGFloat) -> some View {
        LabeledContent(label) {
            TextField(placeholder, text: text)
                .textFieldStyle(.roundedBorder)
                .frame(width: width)
        }
    }
}

#Preview {
    SettingsView()
        .frame(width: 600, height: 600)
}
