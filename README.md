# CourierPro

A macOS-only desktop application for courier management, built with SwiftUI and SwiftData.

![Platform](https://img.shields.io/badge/platform-macOS%2026.5+-blue)
![Swift](https://img.shields.io/badge/swift-5.0-orange)
![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-purple)

## Features

### Core Functionality
- **Parcel Management** - Create, track, and manage parcels with unique tracking numbers
- **Status Tracking** - Track parcel lifecycle: Created → Picked Up → In Transit → Out for Delivery → Delivered
- **Customer Management** - Maintain customer database with contact information
- **Driver Management** - Manage drivers, availability, and assignments

### Billing & Invoicing
- **Invoice Generation** - Automatically create invoices from delivered parcels
- **PDF Export** - Export professional PDF invoices
- **Payment Tracking** - Record payments via Cash, Credit Card, Bank Transfer, or Check
- **Pricing Rules** - Configurable pricing: flat rate, per kg, or per km

### Analytics & Reports
- **Dashboard** - Overview of business metrics
- **Revenue Reports** - Track income, pending, and overdue amounts
- **Delivery Performance** - Success rates and status breakdowns
- **Driver Analytics** - Driver assignment and availability stats

### Additional Features
- **Keyboard Shortcuts** - Cmd+1/2/3 for quick navigation
- **Search & Filter** - Find parcels, customers, and drivers quickly
- **Status History** - Complete audit trail of status changes
- **Driver Assignment** - Assign drivers to parcels with availability tracking

## Requirements

- macOS 26.5 or later
- Xcode 26.6 or later
- Swift 5.0

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/pallab-js/courierpro.git
   ```

2. Open the project in Xcode:
   ```bash
   open courierpro.xcodeproj
   ```

3. Select "My Mac" as the destination

4. Press `Cmd+R` to build and run

## Project Structure

```
CourierPro/
├── Models/
│   ├── Parcel.swift
│   ├── Customer.swift
│   ├── Driver.swift
│   ├── Invoice.swift
│   ├── InvoiceItem.swift
│   ├── Payment.swift
│   ├── PricingRule.swift
│   └── StatusHistory.swift
├── ViewModels/
│   ├── ParcelViewModel.swift
│   ├── CustomerViewModel.swift
│   ├── DriverViewModel.swift
│   └── InvoiceViewModel.swift
├── Views/
│   ├── Dashboard/
│   ├── Parcels/
│   ├── Customers/
│   ├── Drivers/
│   ├── Billing/
│   ├── Reports/
│   └── Sidebar/
├── Services/
│   ├── PersistenceService.swift
│   ├── DataSeeder.swift
│   └── InvoiceExporter.swift
└── Tests/
    ├── Models/
    ├── ViewModels/
    └── Services/
```

## Architecture

- **UI Framework**: SwiftUI
- **Data Persistence**: SwiftData (SQLite)
- **Architecture Pattern**: MVVM
- **Testing**: XCTest (25 unit tests)

## Sample Data

The app includes a data seeder that populates sample data on first launch:
- 5 customers
- 3 drivers
- 5 parcels with various statuses

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Author

**Pallab Jyoti Sonowal**
- GitHub: [@pallab-js](https://github.com/pallab-js)
