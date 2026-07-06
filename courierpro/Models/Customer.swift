import Foundation
import SwiftData

@Model
final class Customer {
    var id: UUID
    var name: String
    var email: String
    var phone: String
    var address: String
    var city: String
    var postalCode: String
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Parcel.sender)
    var sentParcels: [Parcel]?

    @Relationship(deleteRule: .cascade, inverse: \Parcel.receiver)
    var receivedParcels: [Parcel]?

    init(
        id: UUID = UUID(),
        name: String,
        email: String = "",
        phone: String = "",
        address: String = "",
        city: String = "",
        postalCode: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.phone = phone
        self.address = address
        self.city = city
        self.postalCode = postalCode
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var fullName: String {
        name
    }

    var shortAddress: String {
        if city.isEmpty && postalCode.isEmpty {
            return address
        }
        return "\(city) \(postalCode)".trimmingCharacters(in: .whitespaces)
    }
}
