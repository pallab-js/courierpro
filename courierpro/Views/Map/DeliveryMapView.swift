import SwiftUI
import MapKit
import SwiftData

struct DeliveryMapView: View {
    @Query private var allParcels: [Parcel]
    @State private var position: MapCameraPosition = .automatic
    @State private var showDelivered = false

    private var parcels: [Parcel] {
        showDelivered ? allParcels : allParcels.filter { $0.status != .delivered }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Delivery Map")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Toggle("Show Delivered", isOn: $showDelivered)
                    .toggleStyle(.switch)
                Text("\(parcels.count) parcels")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Map(position: $position) {
                ForEach(parcels) { parcel in
                    if let sender = parcel.sender, sender.hasCoordinates {
                        Annotation("Sender: \(sender.name)", coordinate: sender.coordinate) {
                            VStack {
                                Image(systemName: "arrow.up.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.title2)
                                Text(parcel.trackingNumber)
                                    .font(.caption2)
                                    .padding(2)
                                    .background(.ultraThinMaterial)
                                    .cornerRadius(4)
                            }
                        }
                    }

                    if let receiver = parcel.receiver, receiver.hasCoordinates {
                        Annotation("Receiver: \(receiver.name)", coordinate: receiver.coordinate) {
                            VStack {
                                Image(systemName: "arrow.down.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.title2)
                                Text(parcel.trackingNumber)
                                    .font(.caption2)
                                    .padding(2)
                                    .background(.ultraThinMaterial)
                                    .cornerRadius(4)
                            }
                        }
                    }

                    if let sender = parcel.sender, let receiver = parcel.receiver,
                       sender.hasCoordinates, receiver.hasCoordinates {
                        MapPolyline(
                            coordinates: [sender.coordinate, receiver.coordinate]
                        )
                        .stroke(statusColor(parcel.status), lineWidth: 2)
                    }
                }
            }
            .cornerRadius(10)
        }
        .padding()
    }

    private func statusColor(_ status: DeliveryStatus) -> Color {
        switch status {
        case .created: return .blue
        case .pickedUp: return .orange
        case .inTransit: return .purple
        case .outForDelivery: return .yellow
        case .delivered: return .green
        case .failed: return .red
        }
    }
}
