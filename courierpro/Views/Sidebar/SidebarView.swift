import SwiftUI

enum NavigationItem: String, CaseIterable, Identifiable {
    case dashboard
    case parcels
    case customers
    case drivers
    case driverSchedule
    case invoices
    case recurringInvoices
    case pricing
    case reports
    case map
    case settings

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .parcels: return "Parcels"
        case .customers: return "Customers"
        case .drivers: return "Drivers"
        case .driverSchedule: return "Driver Schedule"
        case .invoices: return "Invoices"
        case .recurringInvoices: return "Recurring Invoices"
        case .pricing: return "Pricing"
        case .reports: return "Reports"
        case .map: return "Delivery Map"
        case .settings: return "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .dashboard: return "chart.bar.fill"
        case .parcels: return "shippingbox.fill"
        case .customers: return "person.2.fill"
        case .drivers: return "car.fill"
        case .driverSchedule: return "calendar"
        case .invoices: return "doc.text.fill"
        case .recurringInvoices: return "arrow.clockwise"
        case .pricing: return "dollarsign.circle.fill"
        case .reports: return "chart.pie.fill"
        case .map: return "map.fill"
        case .settings: return "gear"
        }
    }

    var section: SidebarSection {
        switch self {
        case .dashboard: return .main
        case .parcels, .customers, .drivers, .driverSchedule: return .operations
        case .invoices, .recurringInvoices, .pricing: return .billing
        case .reports, .map: return .analytics
        case .settings: return .system
        }
    }
}

enum SidebarSection: String, CaseIterable {
    case main = "MAIN"
    case operations = "OPERATIONS"
    case billing = "BILLING"
    case analytics = "ANALYTICS"
    case system = "SYSTEM"
}

struct SidebarView: View {
    @Binding var selectedItem: NavigationItem?

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                sidebarHeader
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 20)

                ForEach(SidebarSection.allCases, id: \.self) { section in
                    sectionView(section)
                }
            }
            .padding(.bottom, 16)
        }
    }

    private var sidebarHeader: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32)

                Image(systemName: "shippingbox.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text("CourierPro")
                    .font(.system(.headline, design: .rounded))
                Text("v1.0")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }

    private func sectionView(_ section: SidebarSection) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(section.rawValue)
                .font(.system(.caption2, weight: .semibold))
                .foregroundColor(.secondary.opacity(0.6))
                .tracking(0.8)
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 6)

            ForEach(NavigationItem.allCases.filter { $0.section == section }) { item in
                sidebarRow(item)
            }
        }
    }

    private func sidebarRow(_ item: NavigationItem) -> some View {
        Button(action: { selectedItem = item }) {
            HStack(spacing: 10) {
                Image(systemName: item.systemImage)
                    .font(.system(size: 14))
                    .frame(width: 20)
                    .foregroundColor(selectedItem == item ? .accentColor : .secondary)

                Text(item.displayName)
                    .font(.system(.subheadline, weight: selectedItem == item ? .semibold : .regular))
                    .foregroundColor(selectedItem == item ? .primary : .secondary)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(selectedItem == item ? Color.accentColor.opacity(0.1) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 8)
    }
}

#Preview {
    SidebarView(selectedItem: .constant(.dashboard))
        .frame(width: 220)
}
