import SwiftUI

struct ContentView: View {
    @State private var selectedItem: NavigationItem? = .dashboard

    var body: some View {
        NavigationSplitView {
            SidebarView(selectedItem: $selectedItem)
        } detail: {
            switch selectedItem {
            case .dashboard:
                DashboardView()
            case .parcels:
                ParcelListView()
            case .customers:
                CustomerListView()
            case .drivers:
                DriverListView()
            case .invoices:
                InvoiceListView()
            case .pricing:
                PricingRuleListView()
            case .reports:
                ReportsView()
            case .none:
                Text("Select an item from the sidebar")
                    .foregroundColor(.secondary)
            }
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}

#Preview {
    ContentView()
}
