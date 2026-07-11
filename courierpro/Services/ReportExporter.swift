import Foundation
import SwiftUI

struct ReportExporter {
    private static func escapeCSV(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let formulaPrefixes: [Character] = ["=", "+", "-", "@", "\t", "\r"]
        let escaped: String
        if let first = trimmed.first, formulaPrefixes.contains(first) {
            escaped = "'" + trimmed
        } else {
            escaped = trimmed
        }
        if escaped.contains(",") || escaped.contains("\"") || escaped.contains("\n") {
            return "\"\(escaped.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return escaped
    }

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
            csv += "\(escapeCSV(status.displayName)),\(count)\n"
        }
        csv += "\n"

        csv += "Parcels\n"
        csv += "Tracking Number,Status,Weight,Sender,Receiver,Driver,Created\n"
        for parcel in parcels {
            csv += "\(escapeCSV(parcel.trackingNumber)),\(escapeCSV(parcel.statusDisplayName)),\(String(format: "%.1f", parcel.weight)),\(escapeCSV(parcel.senderName)),\(escapeCSV(parcel.receiverName)),\(escapeCSV(parcel.driverName)),\(parcel.createdAt.formatted(date: .abbreviated, time: .omitted))\n"
        }
        csv += "\n"

        csv += "Invoices\n"
        csv += "Invoice Number,Status,Total,Balance Due,Customer,Created\n"
        for invoice in invoices {
            csv += "\(escapeCSV(invoice.invoiceNumber)),\(escapeCSV(invoice.status.displayName)),\(String(format: "$%.2f", invoice.totalAmount)),\(String(format: "$%.2f", invoice.balanceDue)),\(escapeCSV(invoice.customer?.name ?? "N/A")),\(invoice.createdAt.formatted(date: .abbreviated, time: .omitted))\n"
        }
        csv += "\n"

        csv += "Drivers\n"
        csv += "Name,Phone,License,Available,Assigned Parcels\n"
        for driver in drivers {
            csv += "\(escapeCSV(driver.name)),\(escapeCSV(driver.phone)),\(escapeCSV(driver.licenseNumber)),\(driver.isAvailable ? "Yes" : "No"),\(driver.assignedParcels?.count ?? 0)\n"
        }

        return csv
    }

    static func saveCSV(_ content: String, filename: String) -> URL? {
        guard !filename.contains("/") && !filename.contains("..") && !filename.contains("\0") else {
            return nil
        }
        guard let downloads = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first else {
            return nil
        }
        let url = downloads.appendingPathComponent("\(filename).csv")
        do {
            try content.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }
}
