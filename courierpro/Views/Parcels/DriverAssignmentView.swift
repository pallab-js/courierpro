import SwiftUI
import SwiftData

struct DriverAssignmentView: View {
    let parcel: Parcel
    @Environment(\.dismiss) private var dismiss

    @State private var availableDrivers: [Driver] = []
    @State private var selectedDriver: Driver?
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Assign Driver")
                .font(.title2)
                .fontWeight(.bold)

            Text(parcel.trackingNumber)
                .font(.subheadline)
                .fontDesign(.monospaced)
                .foregroundColor(.secondary)

            Form {
                Section("Current Assignment") {
                    if let currentDriver = parcel.driver {
                        HStack {
                            Image(systemName: "person.fill")
                                .foregroundColor(.accentColor)
                            Text(currentDriver.name)
                            Spacer()
                            Button("Unassign") {
                                unassignDriver()
                            }
                            .foregroundColor(.red)
                        }
                    } else {
                        HStack {
                            Image(systemName: "person.badge.plus")
                                .foregroundColor(.secondary)
                            Text("No driver assigned")
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section("Available Drivers") {
                    if availableDrivers.isEmpty {
                        Text("No available drivers")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(availableDrivers) { driver in
                            HStack {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 8, height: 8)
                                VStack(alignment: .leading) {
                                    Text(driver.name)
                                        .font(.body)
                                    Text("License: \(driver.licenseNumber)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if selectedDriver?.id == driver.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedDriver = driver
                            }
                        }
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

                Button("Assign Driver") {
                    assignDriver()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(selectedDriver == nil)
            }
        }
        .padding()
        .frame(width: 450, height: 400)
        .task {
            loadAvailableDrivers()
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }

    private func loadAvailableDrivers() {
        let descriptor = FetchDescriptor<Driver>()
        if let drivers = try? PersistenceService.shared.fetch(descriptor) {
            availableDrivers = drivers.filter { $0.isAvailable }
        }
    }

    private func assignDriver() {
        guard let driver = selectedDriver else {
            errorMessage = "Please select a driver"
            showingError = true
            return
        }

        parcel.driver = driver
        parcel.updatedAt = Date()

        do {
            try PersistenceService.shared.save()
            dismiss()
        } catch {
            errorMessage = "Failed to assign driver: \(error.localizedDescription)"
            showingError = true
        }
    }

    private func unassignDriver() {
        parcel.driver = nil
        parcel.updatedAt = Date()

        do {
            try PersistenceService.shared.save()
            dismiss()
        } catch {
            errorMessage = "Failed to unassign driver: \(error.localizedDescription)"
            showingError = true
        }
    }
}

#Preview {
    DriverAssignmentView(parcel: Parcel(trackingNumber: "CP-123456"))
}
