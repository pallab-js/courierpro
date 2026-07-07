import Foundation
import SwiftData

struct DataBackupService {
    static func createBackup(context: ModelContext) throws -> URL {
        let timestamp = DateFormatter.backupDateFormatter.string(from: Date())
        let filename = "CourierPro_Backup_\(timestamp)"
        guard let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw BackupError.directoryNotFound
        }

        let backupDir = documents.appendingPathComponent("CourierPro_Backups", isDirectory: true)
        try FileManager.default.createDirectory(at: backupDir, withIntermediateDirectories: true)

        let backupFile = backupDir.appendingPathComponent("\(filename).json")

        let parcels = try context.fetch(FetchDescriptor<Parcel>())
        let customers = try context.fetch(FetchDescriptor<Customer>())
        let drivers = try context.fetch(FetchDescriptor<Driver>())
        let invoices = try context.fetch(FetchDescriptor<Invoice>())
        let pricingRules = try context.fetch(FetchDescriptor<PricingRule>())

        let backup = BackupData(
            parcels: parcels.map { BackupParcel(from: $0) },
            customers: customers.map { BackupCustomer(from: $0) },
            drivers: drivers.map { BackupDriver(from: $0) },
            invoices: invoices.map { BackupInvoice(from: $0) },
            pricingRules: pricingRules.map { BackupPricingRule(from: $0) }
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(backup)
        try data.write(to: backupFile)

        return backupFile
    }

    static func restoreBackup(from url: URL, context: ModelContext) throws {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let backup = try decoder.decode(BackupData.self, from: data)

        for customerData in backup.customers {
            let customer = customerData.toCustomer()
            context.insert(customer)
        }

        for driverData in backup.drivers {
            let driver = driverData.toDriver()
            context.insert(driver)
        }

        let allCustomers = try context.fetch(FetchDescriptor<Customer>())
        let allDrivers = try context.fetch(FetchDescriptor<Driver>())

        for parcelData in backup.parcels {
            let parcel = parcelData.toParcel()
            parcel.sender = allCustomers.first { $0.id == parcelData.senderId }
            parcel.receiver = allCustomers.first { $0.id == parcelData.receiverId }
            parcel.driver = allDrivers.first { $0.id == parcelData.driverId }
            context.insert(parcel)
        }

        for ruleData in backup.pricingRules {
            let rule = ruleData.toPricingRule()
            context.insert(rule)
        }

        try context.save()
    }

    static func getBackupList() -> [URL] {
        guard let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return []
        }
        let backupDir = documents.appendingPathComponent("CourierPro_Backups", isDirectory: true)
        guard let files = try? FileManager.default.contentsOfDirectory(at: backupDir, includingPropertiesForKeys: nil) else {
            return []
        }
        return files.filter { $0.pathExtension == "json" }.sorted { $0.lastPathComponent > $1.lastPathComponent }
    }

    static func deleteBackup(at url: URL) throws {
        try FileManager.default.removeItem(at: url)
    }
}

enum BackupError: LocalizedError {
    case directoryNotFound
    case encodingFailed
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .directoryNotFound: return "Could not find backup directory"
        case .encodingFailed: return "Failed to encode backup data"
        case .decodingFailed: return "Failed to decode backup data"
        }
    }
}

struct BackupData: Codable {
    let parcels: [BackupParcel]
    let customers: [BackupCustomer]
    let drivers: [BackupDriver]
    let invoices: [BackupInvoice]
    let pricingRules: [BackupPricingRule]
    let backupDate: Date

    init(parcels: [BackupParcel], customers: [BackupCustomer], drivers: [BackupDriver], invoices: [BackupInvoice], pricingRules: [BackupPricingRule]) {
        self.parcels = parcels
        self.customers = customers
        self.drivers = drivers
        self.invoices = invoices
        self.pricingRules = pricingRules
        self.backupDate = Date()
    }
}

struct BackupParcel: Codable {
    let id: UUID
    let trackingNumber: String
    let statusRaw: Int
    let weight: Double
    let dimensions: String
    let notes: String?
    let createdAt: Date
    let updatedAt: Date
    let deliveredAt: Date?
    let senderId: UUID?
    let receiverId: UUID?
    let driverId: UUID?

    init(from parcel: Parcel) {
        self.id = parcel.id
        self.trackingNumber = parcel.trackingNumber
        self.statusRaw = parcel.statusRaw
        self.weight = parcel.weight
        self.dimensions = parcel.dimensions
        self.notes = parcel.notes
        self.createdAt = parcel.createdAt
        self.updatedAt = parcel.updatedAt
        self.deliveredAt = parcel.deliveredAt
        self.senderId = parcel.sender?.id
        self.receiverId = parcel.receiver?.id
        self.driverId = parcel.driver?.id
    }

    func toParcel() -> Parcel {
        Parcel(
            id: id,
            trackingNumber: trackingNumber,
            status: DeliveryStatus(rawValue: statusRaw) ?? .created,
            weight: weight,
            dimensions: dimensions,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deliveredAt: deliveredAt
        )
    }
}

struct BackupCustomer: Codable {
    let id: UUID
    let name: String
    let email: String
    let phone: String
    let address: String
    let city: String
    let postalCode: String
    let latitude: Double
    let longitude: Double
    let createdAt: Date
    let updatedAt: Date

    init(from customer: Customer) {
        self.id = customer.id
        self.name = customer.name
        self.email = customer.email
        self.phone = customer.phone
        self.address = customer.address
        self.city = customer.city
        self.postalCode = customer.postalCode
        self.latitude = customer.latitude
        self.longitude = customer.longitude
        self.createdAt = customer.createdAt
        self.updatedAt = customer.updatedAt
    }

    func toCustomer() -> Customer {
        Customer(
            id: id,
            name: name,
            email: email,
            phone: phone,
            address: address,
            city: city,
            postalCode: postalCode,
            latitude: latitude,
            longitude: longitude,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

struct BackupDriver: Codable {
    let id: UUID
    let name: String
    let phone: String
    let licenseNumber: String
    let isAvailable: Bool
    let createdAt: Date
    let updatedAt: Date

    init(from driver: Driver) {
        self.id = driver.id
        self.name = driver.name
        self.phone = driver.phone
        self.licenseNumber = driver.licenseNumber
        self.isAvailable = driver.isAvailable
        self.createdAt = driver.createdAt
        self.updatedAt = driver.updatedAt
    }

    func toDriver() -> Driver {
        Driver(
            id: id,
            name: name,
            phone: phone,
            licenseNumber: licenseNumber,
            isAvailable: isAvailable,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

struct BackupInvoice: Codable {
    let id: UUID
    let invoiceNumber: String
    let subtotal: Double
    let taxRate: Double
    let taxAmount: Double
    let totalAmount: Double
    let statusRaw: Int
    let notes: String?
    let createdAt: Date
    let updatedAt: Date
    let dueDate: Date?
    let paidAt: Date?

    init(from invoice: Invoice) {
        self.id = invoice.id
        self.invoiceNumber = invoice.invoiceNumber
        self.subtotal = invoice.subtotal
        self.taxRate = invoice.taxRate
        self.taxAmount = invoice.taxAmount
        self.totalAmount = invoice.totalAmount
        self.statusRaw = invoice.statusRaw
        self.notes = invoice.notes
        self.createdAt = invoice.createdAt
        self.updatedAt = invoice.updatedAt
        self.dueDate = invoice.dueDate
        self.paidAt = invoice.paidAt
    }

    func toInvoice() -> Invoice {
        Invoice(
            id: id,
            invoiceNumber: invoiceNumber,
            status: InvoiceStatus(rawValue: statusRaw) ?? .draft,
            subtotal: subtotal,
            taxRate: taxRate,
            notes: notes,
            dueDate: dueDate ?? Date(),
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

struct BackupPricingRule: Codable {
    let id: UUID
    let name: String
    let pricingTypeRaw: Int
    let basePrice: Double
    let pricePerUnit: Double
    let minimumWeight: Double
    let maximumWeight: Double
    let isActive: Bool
    let createdAt: Date
    let updatedAt: Date

    init(from rule: PricingRule) {
        self.id = rule.id
        self.name = rule.name
        self.pricingTypeRaw = rule.pricingTypeRaw
        self.basePrice = rule.basePrice
        self.pricePerUnit = rule.pricePerUnit
        self.minimumWeight = rule.minimumWeight
        self.maximumWeight = rule.maximumWeight
        self.isActive = rule.isActive
        self.createdAt = rule.createdAt
        self.updatedAt = rule.updatedAt
    }

    func toPricingRule() -> PricingRule {
        PricingRule(
            id: id,
            name: name,
            pricingType: PricingType(rawValue: pricingTypeRaw) ?? .flatRate,
            basePrice: basePrice,
            pricePerUnit: pricePerUnit,
            minimumWeight: minimumWeight,
            maximumWeight: maximumWeight,
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

extension DateFormatter {
    static let backupDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        return formatter
    }()
}
