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
                    .fill(schedule.isAvailable ? Color.green : Color.orange)
                    .frame(width: 12, height: 12)
                Text(schedule.driver.name)
                    .font(.headline)
                Spacer()
                Text(schedule.isAvailable ? "Available" : "Busy")
                    .font(.caption)
                    .foregroundColor(schedule.isAvailable ? .green : .orange)
            }

            if !schedule.assignedParcels.isEmpty {
                Divider()

                Text("Optimized Route")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)

                ForEach(Array(schedule.assignedParcels.enumerated()), id: \.element.id) { index, parcel in
                    HStack(alignment: .top, spacing: 8) {
                        VStack {
                            Circle()
                                .fill(index == 0 ? Color.blue : (index == schedule.assignedParcels.count - 1 ? Color.green : Color.purple))
                                .frame(width: 8, height: 8)
                            if index < schedule.assignedParcels.count - 1 {
                                Rectangle()
                                    .fill(Color.secondary.opacity(0.3))
                                    .frame(width: 2, height: 20)
                            }
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(parcel.trackingNumber)
                                .font(.caption)
                                .fontWeight(.medium)
                                .fontDesign(.monospaced)
                            Text("\(parcel.senderName) → \(parcel.receiverName)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        StatusBadge(status: parcel.status)
                            .scaleEffect(0.8)

                        Button(action: { onUnassign(parcel) }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                        .buttonStyle(.plain)
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
                EmptyStateView(
                    icon: "shippingbox",
                    title: "No Parcels Assigned",
                    message: "Assign parcels to this driver",
                    actionTitle: nil,
                    action: nil
                )
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
