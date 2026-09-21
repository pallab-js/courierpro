# CourierPro

A macOS desktop application for courier and logistics management, built with SwiftUI and SwiftData. Fully offline with local SQLite persistence.

![Platform](https://img.shields.io/badge/platform-macOS%2015+-blue)
![Swift](https://img.shields.io/badge/swift-6.0-orange)
![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-purple)
![Tests](https://img.shields.io/badge/tests-80%20passing-brightgreen)
![CI](https://img.shields.io/badge/CI-GitHub%20Actions-success)

## Features

### Core Functionality
- **Parcel Management** - Create, track, and manage parcels with unique tracking numbers
- **Status Tracking** - Full lifecycle: Created → Picked Up → In Transit → Out for Delivery → Delivered / Failed
- **Customer Management** - Maintain customer database with contact info, addresses, and coordinates
- **Driver Management** - Manage drivers, availability tracking, and parcel assignments

### Billing & Invoicing
- **Invoice Generation** - Auto-create invoices from delivered parcels with line items
- **PDF Export** - Export professional PDF invoices via CoreGraphics
- **Payment Tracking** - Record payments via Cash, Credit Card, Bank Transfer, or Check
- **Pricing Rules** - Configurable pricing: flat rate, per kg, or per km
- **Recurring Invoices** - Automatic invoice generation on weekly, monthly, quarterly, or yearly schedules

### Analytics & Reports
- **Dashboard** - KPI cards, status distribution bars, financial overview, recent parcels
- **Revenue Reports** - Track income, pending, and overdue amounts
- **Delivery Performance** - Success rates and status breakdowns
- **Driver Analytics** - Driver assignment and availability stats
- **Date Range Filtering** - Filter reports by custom date ranges
- **CSV Export** - Export reports to CSV format

### Driver Scheduling
- **Route Optimization** - Nearest-neighbor algorithm for efficient delivery routes
- **Schedule View** - Visual route planning with stop count and estimated time
- **Availability Tracking** - Real-time driver availability and busy status

### Data Management
- **CSV Import/Export** - Import and export customers, drivers, and parcels
- **Backup & Restore** - Full JSON backup and restore with relationship mapping
- **Delivery Map** - Interactive MapKit-based delivery visualization

### Polish & UX
- **Empty States** - Helpful empty state views with action buttons
- **Loading Indicators** - Loading spinners for all data operations
- **Error Handling** - Graceful error alerts with user-facing messages throughout
- **Keyboard Shortcuts** - Cmd+1/2/3 for quick navigation
- **CSV Formula Injection Protection** - Sanitizes exported CSV data

## Requirements

- macOS 15.0 or later
- Xcode 16.0 or later
- Swift 6.0

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/pallab-js/courierpro.git
   ```

2. Open in Xcode:
   ```bash
   open courierpro.xcodeproj
   ```

3. Select "My Mac" as the destination and press `Cmd+R`.

Or build from the command line:
```bash
swift build
swift test
```

## Project Structure

```
courierpro/
├── Models/                  # SwiftData @Model classes
│   ├── Parcel.swift
│   ├── Customer.swift
│   ├── Driver.swift
│   ├── Invoice.swift
│   ├── InvoiceItem.swift
│   ├── Payment.swift
│   ├── PricingRule.swift
│   ├── RecurringInvoice.swift
│   └── StatusHistory.swift
├── ViewModels/              # ObservableObject view models
│   ├── ParcelViewModel.swift
│   ├── CustomerViewModel.swift
│   ├── DriverViewModel.swift
│   ├── InvoiceViewModel.swift
│   ├── RecurringInvoiceViewModel.swift
│   └── SettingsViewModel.swift
├── Views/                   # SwiftUI views
│   ├── Billing/
│   ├── Components/
│   ├── Customers/
│   ├── Dashboard/
│   ├── Drivers/
│   ├── Map/
│   ├── Parcels/
│   ├── Reports/
│   ├── Settings/
│   └── Sidebar/
├── Services/                # Business logic & persistence
│   ├── PersistenceService.swift
│   ├── DataSeeder.swift
│   ├── InvoiceExporter.swift
│   ├── CSVService.swift
│   ├── CSVUtilities.swift
│   ├── ReportExporter.swift
│   ├── DataBackupService.swift
│   └── RouteOptimizer.swift
└── courierproTests/         # XCTest unit tests
    ├── Models/
    ├── ViewModels/
    └── Services/
```

## Architecture

- **UI Framework**: SwiftUI
- **Data Persistence**: SwiftData (local SQLite via ORM)
- **Architecture Pattern**: MVVM (Model-View-ViewModel)
- **Testing**: XCTest (80 unit tests)
- **Linting**: SwiftLint with 36 opt-in rules
- **CI/CD**: GitHub Actions (build, test, lint)

## Testing

```bash
swift test
```

The test suite covers:
- Model initialization and computed properties
- ViewModel CRUD operations and business logic
- Service layer: persistence, CSV parsing, route optimization
- Edge cases: CSV injection, CRLF parsing, distance-based pricing

## CI/CD

GitHub Actions workflows:

- **CI** (`.github/workflows/ci.yml`) - Runs on push/PR to `main`:
  - `swift build` + `swift test --parallel`
  - SwiftLint with strict mode
  - Concurrency group cancels stale runs

- **Release** (`.github/workflows/release.yml`) - Runs on `v*` tags:
  - Builds release binary
  - Creates GitHub Release with auto-generated notes

## Sample Data

The app seeds sample data on first launch:
- 5 customers with Indian city coordinates
- 3 drivers with license numbers
- 5 parcels with various statuses

## License

MIT License - see [LICENSE](LICENSE) for details.

## Author

**Pallab Jyoti Sonowal**
- GitHub: [@pallab-js](https://github.com/pallab-js)
