import SwiftUI
import MapKit

struct DriverScheduleView: View {
    @StateObject private var viewModel = DriverScheduleViewModel()
    @State private var selectedDriver: Driver?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Driver Schedules")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Spacer()
                DatePicker("Date", selection: $viewModel.selectedDate, displayedComponents: .date)
                    .labelsHidden()
                Button(action: { viewModel.loadSchedules() }) {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
            }
            .padding()

            Divider()

            if viewModel.isLoading {
                LoadingView()
            } else if viewModel.schedules.isEmpty {
                EmptyStateView(
                    icon: "car.fill",
                    title: "No Driver Schedules",
                    message: "Add drivers and assign parcels to see optimized routes"
                )
            } else {
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 350, maximum: .infinity))
                    ], spacing: 16) {
                        ForEach(viewModel.schedules) { schedule in
                            DriverScheduleCard(schedule: schedule) { parcel in
                                viewModel.unassignParcel(parcel)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .task {
            viewModel.loadSchedules()
        }
        .errorAlert(isPresented: $viewModel.showError, message: viewModel.errorMessage)
    }
}

struct DriverScheduleCard: View {
    let schedule: DriverSchedule
    let onUnassign: (Parcel) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(!schedule.driver.isAvailable ? Color.red : (schedule.driver.isBusy ? Color.orange : Color.green))
                    .frame(width: 12, height: 12)
                Text(schedule.driver.name)
                    .font(.headline)
                Spacer()
                Text(!schedule.driver.isAvailable ? "Unavailable" : (schedule.driver.isBusy ? "Busy" : "Available"))
                    .font(.caption)
                    .foregroundColor(!schedule.driver.isAvailable ? .red : (schedule.driver.isBusy ? .orange : .green))
            }

            if !schedule.assignedParcels.isEmpty {
                Divider()

                Text("Optimized Route")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)

                VStack(spacing: 8) {
                    ForEach(schedule.assignedParcels) { parcel in
                        HStack {
                            Image(systemName: parcel.status.systemImage)
                                .foregroundColor(parcel.status.color)
                            VStack(alignment: .leading) {
                                Text(parcel.trackingNumber)
                                    .font(.system(.body, design: .monospaced))
                                if let receiver = parcel.receiver {
                                    Text("To: \(receiver.name) (\(receiver.shortAddress))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            Button {
                                onUnassign(parcel)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                                    .font(.caption)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Divider()

                HStack {
                    Label("\(schedule.assignedParcels.count) stops", systemImage: "mappin.and.ellipse")
                    Spacer()
                    Label(String(format: "%.1f km", schedule.totalDistance), systemImage: "ruler")
                    Spacer()
                    Label(formatTime(schedule.estimatedTime), systemImage: "clock")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            } else {
                VStack(spacing: 4) {
                    Image(systemName: "shippingbox")
                        .font(.system(size: 24))
                        .foregroundColor(.secondary)
                    Text("No Parcels Assigned")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text("Assign parcels to this driver")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 80)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }

    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) % 3600 / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}

#Preview {
    DriverScheduleView()
        .frame(width: 800, height: 600)
}
