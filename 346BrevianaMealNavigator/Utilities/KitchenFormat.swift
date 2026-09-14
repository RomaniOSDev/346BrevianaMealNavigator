import Foundation

enum KitchenFormat {
    static func quantity(_ value: Double, unit: String) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        let amount = formatter.string(from: NSNumber(value: value)) ?? String(value)
        let trimmedUnit = unit.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedUnit.isEmpty {
            return amount
        }
        return amount + " " + trimmedUnit
    }

    static func clock(_ seconds: Int) -> String {
        let clamped = max(0, seconds)
        let minutes = clamped / 60
        let remainder = clamped % 60
        let minuteText = minutes < 10 ? "0\(minutes)" : "\(minutes)"
        let secondText = remainder < 10 ? "0\(remainder)" : "\(remainder)"
        return minuteText + ":" + secondText
    }

    static func minutesLabel(_ minutes: Int) -> String {
        if minutes == 1 {
            return "1 min"
        }
        return "\(minutes) min"
    }
}
