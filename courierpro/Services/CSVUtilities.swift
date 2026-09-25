import Foundation

enum CSVUtilities {
    static func escapeCSV(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        // Strip C0 control characters only. `asciiValue` is nil for everything outside
        // ASCII, so non-ASCII text (accented letters, ₹, CJK) must be kept as-is.
        let cleaned = trimmed.filter { char in
            if char == "\t" || char == "\n" || char == "\r" { return true }
            guard let ascii = char.asciiValue else { return true }
            return ascii >= 0x20 && ascii != 0x7F
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
