import Foundation

enum CSVUtilities {
    static func escapeCSV(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleaned = trimmed.filter { char in
            char == "\t" || char == "\n" || char == "\r" || (char.asciiValue.map { $0 >= 0x20 } ?? false)
        }
        let formulaPrefixes: [Character] = ["=", "+", "-", "@", "\t", "\r", "|"]
        let escaped: String
        if let first = cleaned.first, formulaPrefixes.contains(first) {
            escaped = "'" + cleaned
        } else {
            escaped = cleaned
        }
        if escaped.contains(",") || escaped.contains("\"") || escaped.contains("\n") {
            return "\"\(escaped.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return escaped
    }

    static func validatePhoneNumber(_ phone: String) -> Bool {
        let digitsOnly = phone.filter { $0.isNumber }
        return digitsOnly.count >= 7 && digitsOnly.count <= 15
    }
}
