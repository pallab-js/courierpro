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
}

struct SidebarView: View {
    @Binding var selectedItem: NavigationItem?

    var body: some View {
        List(NavigationItem.allCases, selection: $selectedItem) { item in
            Label(item.displayName, systemImage: item.systemImage)
                .tag(item)
        }
        .navigationTitle("CourierPro")
    }
}

#Preview {
    SidebarView(selectedItem: .constant(.dashboard))
        .frame(width: 200)
}
