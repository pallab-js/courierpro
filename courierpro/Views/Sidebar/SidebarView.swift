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
        List(selection: $selectedItem) {
            Section {
                Label("Dashboard", systemImage: "chart.bar.fill")
                    .tag(NavigationItem.dashboard)
            }

            Section("Operations") {
                Label("Parcels", systemImage: "shippingbox.fill")
                    .tag(NavigationItem.parcels)
                Label("Customers", systemImage: "person.2.fill")
                    .tag(NavigationItem.customers)
                Label("Drivers", systemImage: "car.fill")
                    .tag(NavigationItem.drivers)
                Label("Driver Schedule", systemImage: "calendar")
                    .tag(NavigationItem.driverSchedule)
            }

            Section("Billing") {
                Label("Invoices", systemImage: "doc.text.fill")
                    .tag(NavigationItem.invoices)
                Label("Recurring Invoices", systemImage: "arrow.clockwise")
                    .tag(NavigationItem.recurringInvoices)
                Label("Pricing", systemImage: "dollarsign.circle.fill")
                    .tag(NavigationItem.pricing)
            }

            Section("Analytics") {
                Label("Reports", systemImage: "chart.pie.fill")
                    .tag(NavigationItem.reports)
                Label("Delivery Map", systemImage: "map.fill")
                    .tag(NavigationItem.map)
            }

            Section("System") {
                Label("Settings", systemImage: "gear")
                    .tag(NavigationItem.settings)
            }
        }
        .navigationTitle("CourierPro")
        .listStyle(.sidebar)
    }
}

#Preview {
    SidebarView(selectedItem: .constant(.dashboard))
        .frame(width: 220)
}
