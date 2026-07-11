import Foundation

@MainActor
struct CSVExporter {
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()

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
            ].map { escapeCSV($0) }.joined(separator: ",")
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

    private static func formatDate(_ date: Date) -> String {
        dateFormatter.string(from: date)
    }
}

struct CSVImporter {
    private static let maxFileSize = 10_000_000 // 10MB
    private static let maxFieldNameLength = 200

    static func importCustomers(from csv: String) -> [Customer] {
        guard csv.count <= maxFileSize else { return [] }
        let lines = csv.components(separatedBy: .newlines).filter { !$0.isEmpty }
        guard lines.count > 1 else { return [] }

        var customers: [Customer] = []
        for line in lines.dropFirst() {
            let fields = parseCSVLine(line)
            guard fields.count >= 6 else { continue }

            let name = String(fields[0].prefix(maxFieldNameLength)).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { continue }

            let customer = Customer(
                name: name,
                email: String(fields[1].prefix(maxFieldNameLength)).trimmingCharacters(in: .whitespacesAndNewlines),
                phone: String(fields[2].prefix(20)).filter { $0.isNumber || $0 == "+" },
                address: String(fields[3].prefix(maxFieldNameLength)).trimmingCharacters(in: .whitespacesAndNewlines),
                city: String(fields[4].prefix(100)).trimmingCharacters(in: .whitespacesAndNewlines),
                postalCode: String(fields[5].prefix(10)).filter { $0.isNumber }
            )
            customers.append(customer)
        }
        return customers
    }

    static func importDrivers(from csv: String) -> [Driver] {
        guard csv.count <= maxFileSize else { return [] }
        let lines = csv.components(separatedBy: .newlines).filter { !$0.isEmpty }
        guard lines.count > 1 else { return [] }

        var drivers: [Driver] = []
        for line in lines.dropFirst() {
            let fields = parseCSVLine(line)
            guard fields.count >= 4 else { continue }

            let name = String(fields[0].prefix(maxFieldNameLength)).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { continue }

            let driver = Driver(
                name: name,
                phone: String(fields[1].prefix(20)).filter { $0.isNumber || $0 == "+" },
                licenseNumber: String(fields[2].prefix(50)).trimmingCharacters(in: .whitespacesAndNewlines),
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
        var chars = line.makeIterator()

        while let char = chars.next() {
            if char == "\"" {
                if inQuotes {
                    if let next = chars.next() {
                        if next == "\"" {
                            current.append("\"")
                        } else if next == "," {
                            fields.append(current.trimmingCharacters(in: .whitespacesAndNewlines))
                            current = ""
                        } else {
                            inQuotes = false
                            current.append(next)
                        }
                    } else {
                        inQuotes = false
                    }
                } else {
                    inQuotes = true
                }
            } else if char == "," && !inQuotes {
                fields.append(current.trimmingCharacters(in: .whitespacesAndNewlines))
                current = ""
            } else {
                current.append(char)
            }
        }
        fields.append(current.trimmingCharacters(in: .whitespacesAndNewlines))
        return fields
    }
}
