import Foundation
import SwiftUI
import Combine

struct AppSettings: Codable {
    var businessName: String = "CourierPro"
    var businessAddress: String = ""
    var businessPhone: String = ""
    var businessEmail: String = ""
    var currencyCode: String = "INR"
    var currencySymbol: String = "₹"
    var taxRate: Double = 18.0
    var defaultNotes: String = "Thank you for your business!"
    var trackingPrefix: String = "CP"

    static let shared = AppSettings.load()

    static func load() -> AppSettings {
        if let data = UserDefaults.standard.data(forKey: "appSettings"),
           let settings = try? JSONDecoder().decode(AppSettings.self, from: data) {
            return settings
        }
        return AppSettings()
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: "appSettings")
        }
    }
}

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var settings: AppSettings
    @Published var errorMessage: String?
    @Published var showError = false

    init() {
        self.settings = AppSettings.load()
    }

    func save() {
        settings.save()
    }

    func resetToDefaults() {
        settings = AppSettings()
        settings.save()
    }

    static let currencies: [(code: String, symbol: String, name: String)] = [
        ("INR", "₹", "Indian Rupee"),
        ("USD", "$", "US Dollar"),
        ("EUR", "€", "Euro"),
        ("GBP", "£", "British Pound"),
        ("JPY", "¥", "Japanese Yen"),
        ("CAD", "C$", "Canadian Dollar"),
        ("AUD", "A$", "Australian Dollar"),
        ("CHF", "CHF", "Swiss Franc"),
        ("CNY", "¥", "Chinese Yuan"),
        ("BRL", "R$", "Brazilian Real"),
    ]
}
