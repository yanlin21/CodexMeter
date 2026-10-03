import Foundation

enum UsageFormatting {
    static func percent(_ value: Double) -> String {
        "\(Int(value.rounded()))%"
    }

    static func planDisplayName(_ rawValue: String?) -> String? {
        guard let rawValue, !rawValue.isEmpty else { return nil }
        let normalized = rawValue.lowercased()
        let label: String
        switch normalized {
        case "free": label = "Free"
        case "go": label = "Go"
        case "plus": label = "Plus"
        case "pro", "prolite": label = "Pro"
        case "team", "business", "self_serve_business_prolite", "self_serve_business_usage_based":
            label = "Business"
        case "ent26", "enterprise_cbp_automation", "enterprise_cbp_usage_based", "enterprise":
            label = "Enterprise"
        case "edu", "edu_plus", "edu_pro": label = "Edu"
        case "unknown": return "ChatGPT"
        default:
            if normalized.hasPrefix("chatgpt ") { return rawValue }
            return rawValue
        }
        return "ChatGPT \(label)"
    }

    static func planBadge(_ planName: String?) -> String? {
        guard let planName, !planName.isEmpty else { return nil }
        let value = planName.replacingOccurrences(of: "ChatGPT", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return (value.isEmpty ? "CHATGPT" : value).uppercased()
    }

    static func resetDescription(_ date: Date?, compact: Bool = false, now: Date = Date()) -> String? {
        guard let date else { return nil }
        let calendar = Calendar.current
        let time = DateFormatter()
        time.locale = .current
        time.setLocalizedDateFormatFromTemplate("HHmm")

        if calendar.isDate(date, inSameDayAs: now) {
            return compact ? time.string(from: date) : "Today \(time.string(from: date))"
        }
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now),
           calendar.isDate(date, inSameDayAs: tomorrow) {
            return compact ? "Tomorrow" : "Tomorrow \(time.string(from: date))"
        }

        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.setLocalizedDateFormatFromTemplate(compact ? "MMMd" : "MMMdHHmm")
        return formatter.string(from: date)
    }

    static func updatedDescription(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }

    static func credits(_ info: CreditInfo) -> String {
        if info.isUnlimited { return "Unlimited" }
        guard let balance = info.balance else { return "Available" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = info.currency ?? "USD"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: balance)) ?? String(format: "$%.2f", balance)
    }
}

