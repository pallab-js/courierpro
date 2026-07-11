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
                NavigationLink(value: NavigationItem.dashboard) {
                    Label("Dashboard", systemImage: "chart.bar.fill")
                }
            }

            Section("Operations") {
                NavigationLink(value: NavigationItem.parcels) {
                    Label("Parcels", systemImage: "shippingbox.fill")
                }
                NavigationLink(value: NavigationItem.customers) {
                    Label("Customers", systemImage: "person.2.fill")
                }
                NavigationLink(value: NavigationItem.drivers) {
                    Label("Drivers", systemImage: "car.fill")
                }
                NavigationLink(value: NavigationItem.driverSchedule) {
                    Label("Driver Schedule", systemImage: "calendar")
                }
            }

            Section("Billing") {
                NavigationLink(value: NavigationItem.invoices) {
                    Label("Invoices", systemImage: "doc.text.fill")
                }
                NavigationLink(value: NavigationItem.recurringInvoices) {
                    Label("Recurring Invoices", systemImage: "arrow.clockwise")
                }
                NavigationLink(value: NavigationItem.pricing) {
                    Label("Pricing", systemImage: "dollarsign.circle.fill")
                }
            }

            Section("Analytics") {
                NavigationLink(value: NavigationItem.reports) {
                    Label("Reports", systemImage: "chart.pie.fill")
                }
                NavigationLink(value: NavigationItem.map) {
                    Label("Delivery Map", systemImage: "map.fill")
                }
            }

            Section("System") {
                NavigationLink(value: NavigationItem.settings) {
                    Label("Settings", systemImage: "gear")
                }
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
