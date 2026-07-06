import SwiftUI

enum NavigationItem: String, CaseIterable, Identifiable {
    case dashboard
    case parcels
    case customers
    case drivers
    case invoices
    case pricing
    case reports

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .parcels: return "Parcels"
        case .customers: return "Customers"
        case .drivers: return "Drivers"
        case .invoices: return "Invoices"
        case .pricing: return "Pricing"
        case .reports: return "Reports"
        }
    }

    var systemImage: String {
        switch self {
        case .dashboard: return "chart.bar.fill"
        case .parcels: return "shippingbox.fill"
        case .customers: return "person.2.fill"
        case .drivers: return "car.fill"
        case .invoices: return "doc.text.fill"
        case .pricing: return "dollarsign.circle.fill"
        case .reports: return "chart.pie.fill"
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
