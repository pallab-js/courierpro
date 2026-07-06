import Foundation

struct CSVExporter {
    static func exportParcels(_ parcels: [Parcel]) -> String {
        var csv = "Tracking Number,Status,Weight (kg),Dimensions,Sender,Receiver,Driver,Created,Delivered\n"
        for parcel in parcels {
            let row = [
                parcel.trackingNumber,
                parcel.statusDisplayName,
                String(format: "%.1f", parcel.weight),
                parcel.dimensions,
                parcel.senderName,
                parcel.receiverName,
                parcel.driverName,
                formatDate(parcel.createdAt),
                parcel.deliveredAt.map(formatDate) ?? ""
            ].joined(separator: ",")
            csv += row + "\n"
        }
        return csv
    }

    static func exportCustomers(_ customers: [Customer]) -> String {
        var csv = "Name,Email,Phone,Address,City,Postal Code\n"
        for customer in customers {
            let row = [
                customer.name,
                customer.email,
                customer.phone,
                customer.address,
                customer.city,
                customer.postalCode
            ].map { escapeCSV($0) }.joined(separator: ",")
            csv += row + "\n"
        }
        return csv
    }

    static func exportDrivers(_ drivers: [Driver]) -> String {
        var csv = "Name,Phone,License Number,Available\n"
        for driver in drivers {
            let row = [
                driver.name,
                driver.phone,
                driver.licenseNumber,
                driver.isAvailable ? "Yes" : "No"
            ].map { escapeCSV($0) }.joined(separator: ",")
            csv += row + "\n"
        }
        return csv
    }

    private static func escapeCSV(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }

    private static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }
}

struct CSVImporter {
    static func importCustomers(from csv: String) -> [Customer] {
        let lines = csv.components(separatedBy: .newlines).filter { !$0.isEmpty }
        guard lines.count > 1 else { return [] }

        var customers: [Customer] = []
        for line in lines.dropFirst() {
            let fields = parseCSVLine(line)
            guard fields.count >= 6 else { continue }

            let customer = Customer(
                name: fields[0],
                email: fields[1],
                phone: fields[2],
                address: fields[3],
                city: fields[4],
                postalCode: fields[5]
            )
            customers.append(customer)
        }
        return customers
    }

    static func importDrivers(from csv: String) -> [Driver] {
        let lines = csv.components(separatedBy: .newlines).filter { !$0.isEmpty }
        guard lines.count > 1 else { return [] }

        var drivers: [Driver] = []
        for line in lines.dropFirst() {
            let fields = parseCSVLine(line)
            guard fields.count >= 4 else { continue }

            let driver = Driver(
                name: fields[0],
                phone: fields[1],
                licenseNumber: fields[2],
                isAvailable: fields[3].lowercased() == "yes" || fields[3] == "1"
            )
            drivers.append(driver)
        }
        return drivers
    }

    private static func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var current = ""
        var inQuotes = false

        for char in line {
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                fields.append(current.trimmingCharacters(in: .whitespaces))
                current = ""
            } else {
                current.append(char)
            }
        }
        fields.append(current.trimmingCharacters(in: .whitespaces))
        return fields
    }
}
