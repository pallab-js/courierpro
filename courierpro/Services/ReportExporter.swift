import Foundation
import SwiftUI

struct ReportExporter {
    static func generateCSV(
        parcels: [Parcel],
        customers: [Customer],
        drivers: [Driver],
        invoices: [Invoice]
    ) -> String {
        var csv = "CourierPro Report\n"
        csv += "Generated: \(Date().formatted(date: .abbreviated, time: .shortened))\n\n"

        csv += "Summary\n"
        csv += "Total Parcels,\(parcels.count)\n"
        csv += "Total Customers,\(customers.count)\n"
        csv += "Total Drivers,\(drivers.count)\n"
        csv += "Total Invoices,\(invoices.count)\n"
        csv += "Total Revenue,$\(String(format: "%.2f", invoices.filter { $0.status == .paid }.reduce(0) { $0 + $1.totalAmount }))\n\n"

        csv += "Parcels by Status\n"
        for status in DeliveryStatus.allCases {
            let count = parcels.filter { $0.status == status }.count
            csv += "\(status.displayName),\(count)\n"
        }
        csv += "\n"

        csv += "Parcels\n"
        csv += "Tracking Number,Status,Weight,Sender,Receiver,Driver,Created\n"
        for parcel in parcels {
            csv += "\(parcel.trackingNumber),\(parcel.statusDisplayName),\(String(format: "%.1f", parcel.weight)),\(parcel.senderName),\(parcel.receiverName),\(parcel.driverName),\(parcel.createdAt.formatted(date: .abbreviated, time: .omitted))\n"
        }
        csv += "\n"

        csv += "Invoices\n"
        csv += "Invoice Number,Status,Total, balance Due,Customer,Created\n"
        for invoice in invoices {
            csv += "\(invoice.invoiceNumber),\(invoice.status.displayName),\(String(format: "$%.2f", invoice.totalAmount)),\(String(format: "$%.2f", invoice.balanceDue)),\(invoice.customer?.name ?? "N/A"),\(invoice.createdAt.formatted(date: .abbreviated, time: .omitted))\n"
        }
        csv += "\n"

        csv += "Drivers\n"
        csv += "Name,Phone,License,Available,Assigned Parcels\n"
        for driver in drivers {
            csv += "\(driver.name),\(driver.phone),\(driver.licenseNumber),\(driver.isAvailable ? "Yes" : "No"),\(driver.assignedParcels?.count ?? 0)\n"
        }

        return csv
    }

    static func saveCSV(_ content: String, filename: String) -> URL? {
        guard let downloads = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first else {
            return nil
        }
        let url = downloads.appendingPathComponent("\(filename).csv")
        try? content.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}
