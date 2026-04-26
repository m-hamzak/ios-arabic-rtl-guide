//
//  ArabicFormatters.swift
//  ios-arabic-rtl-guide
//
//  Created by Hamza Khalid on 26/04/2026.
//

import Foundation

// MARK: - ArabicFormatters
//
// Number, currency, and date formatting for GCC banking and government apps.
//
// Key considerations:
//   - Arabic uses Eastern Arabic-Indic numerals by default: ٠ ١ ٢ ٣ ٤ ٥ ٦ ٧ ٨ ٩
//   - Most GCC banking apps use Western Arabic numerals (0–9) for financial values
//     because Western numerals are standard in financial systems (SWIFT, IBAN, etc.)
//   - Date formatting must match regional conventions: dd/MM/yyyy in GCC
//   - Currency symbol placement differs by locale: SAR vs ر.س‏
//
// GCC currencies covered:
//   - BHD — Bahraini Dinar (3 decimal places)
//   - SAR — Saudi Riyal (2 decimal places)
//   - QAR — Qatari Riyal (2 decimal places)
//   - AED — UAE Dirham (2 decimal places)
//   - KWD — Kuwaiti Dinar (3 decimal places)

// MARK: - GCC Currency

enum GCCCurrency: String, CaseIterable {
    case bahrainiDinar   = "BHD"
    case saudiRiyal      = "SAR"
    case qatariRiyal     = "QAR"
    case uaeDirham       = "AED"
    case kuwaitiDinar    = "KWD"

    /// Number of fraction digits for this currency.
    var fractionDigits: Int {
        switch self {
        case .bahrainiDinar, .kuwaitiDinar: return 3
        default: return 2
        }
    }

    /// ISO 4217 currency code.
    var code: String { rawValue }

    /// Arabic name of the currency.
    var arabicName: String {
        switch self {
        case .bahrainiDinar:  return "دينار بحريني"
        case .saudiRiyal:     return "ريال سعودي"
        case .qatariRiyal:    return "ريال قطري"
        case .uaeDirham:      return "درهم إماراتي"
        case .kuwaitiDinar:   return "دينار كويتي"
        }
    }
}

// MARK: - ArabicFormatters

final class ArabicFormatters {

    // MARK: - Singleton

    static let shared = ArabicFormatters()
    private init() {}

    // MARK: - Number Formatting

    /// Formats a number using Western Arabic numerals (0–9), current language locale.
    /// Use this for financial values — account balances, transaction amounts.
    func formatNumber(_ value: Double, fractionDigits: Int = 2) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = fractionDigits
        formatter.maximumFractionDigits = fractionDigits
        formatter.locale = LocalizationManager.shared.currentLanguage.locale
        // Force Western digits even in Arabic locale — standard for financial apps
        formatter.usesGroupingSeparator = true
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    /// Formats a number using Eastern Arabic-Indic numerals: ٠١٢٣٤٥٦٧٨٩
    /// Use for non-financial Arabic text where native numerals are preferred.
    func formatNumberEasternArabic(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "ar_AE")
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    // MARK: - Currency Formatting

    /// Formats a currency value for display.
    /// - Parameters:
    ///   - amount: The amount to format.
    ///   - currency: The GCC currency.
    ///   - showCode: If true, shows the ISO code (BHD). If false, shows the symbol.
    func formatCurrency(_ amount: Double, currency: GCCCurrency, showCode: Bool = true) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency.code
        formatter.minimumFractionDigits = currency.fractionDigits
        formatter.maximumFractionDigits = currency.fractionDigits
        formatter.locale = LocalizationManager.shared.currentLanguage.locale

        if showCode {
            formatter.currencySymbol = currency.code
        }

        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount) \(currency.code)"
    }

    /// Returns the currency amount and code as separate strings for custom layout.
    /// Useful when you need the amount LTR and the currency label separately in RTL views.
    func currencyComponents(_ amount: Double, currency: GCCCurrency) -> (amount: String, code: String) {
        let amountStr = formatNumber(amount, fractionDigits: currency.fractionDigits)
        return (amountStr, currency.code)
    }

    // MARK: - Date Formatting

    /// Formats a date in the GCC standard format: dd/MM/yyyy
    func formatDate(_ date: Date, style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.locale = LocalizationManager.shared.currentLanguage.locale
        formatter.dateStyle = style
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    /// Formats a date as dd/MM/yyyy — the standard used in GCC banking apps.
    func formatDateGCC(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        formatter.locale = LocalizationManager.shared.currentLanguage.locale
        return formatter.string(from: date)
    }

    /// Formats a date and time: dd/MM/yyyy HH:mm
    func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy HH:mm"
        formatter.locale = LocalizationManager.shared.currentLanguage.locale
        return formatter.string(from: date)
    }

    /// Formats just the time: HH:mm
    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        formatter.locale = LocalizationManager.shared.currentLanguage.locale
        return formatter.string(from: date)
    }

    /// Returns the day name in the current language: "الأحد" or "Sunday"
    func dayName(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        formatter.locale = LocalizationManager.shared.currentLanguage.locale
        return formatter.string(from: date)
    }

    /// Returns the month name in the current language: "يناير" or "January"
    func monthName(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        formatter.locale = LocalizationManager.shared.currentLanguage.locale
        return formatter.string(from: date)
    }

    // MARK: - IBAN Formatting
    //
    // IBANs must ALWAYS be displayed LTR regardless of app language.
    // Format: AE07 0331 2345 6789 0123 456 (groups of 4)
    // Never split the country code from the check digits.

    func formatIBAN(_ iban: String) -> String {
        let stripped = iban.replacingOccurrences(of: " ", with: "")
        var result = ""
        for (index, char) in stripped.enumerated() {
            if index > 0 && index % 4 == 0 { result += " " }
            result.append(char)
        }
        return result
    }

    // MARK: - Account Number Masking
    //
    // Banking apps often show partial account numbers: **** **** 1234
    // The visible digits must stay LTR.

    func maskAccountNumber(_ number: String, visibleDigits: Int = 4) -> String {
        let digits = number.filter { $0.isNumber }
        guard digits.count > visibleDigits else { return number }
        let masked = String(repeating: "*", count: digits.count - visibleDigits)
        let visible = String(digits.suffix(visibleDigits))
        return masked + visible
    }

    // MARK: - Arabic Pluralisation
    //
    // Arabic has 6 plural forms (unlike English's 2).
    // iOS handles this via .stringsdict files — but here's the manual pattern
    // for cases where you need to construct Arabic plurals in code.
    //
    // Forms: zero, one, two, few (3–10), many (11–99), other (100+)

    enum ArabicPluralForm {
        case zero, one, two, few, many, other

        static func form(for count: Int) -> ArabicPluralForm {
            switch count {
            case 0:       return .zero
            case 1:       return .one
            case 2:       return .two
            case 3...10:  return .few
            case 11...99: return .many
            default:      return .other
            }
        }
    }

    /// Returns the correct Arabic plural form description for a transaction count.
    /// Replace with your own .stringsdict keys in production.
    func transactionCountLabel(_ count: Int) -> String {
        if LocalizationManager.shared.isRTL {
            switch ArabicPluralForm.form(for: count) {
            case .zero:  return "لا توجد معاملات"
            case .one:   return "معاملة واحدة"
            case .two:   return "معاملتان"
            case .few:   return "\(count) معاملات"
            case .many:  return "\(count) معاملة"
            case .other: return "\(count) معاملة"
            }
        } else {
            return count == 1 ? "1 transaction" : "\(count) transactions"
        }
    }
}

// MARK: - Double Extension

extension Double {
    func formatted(as currency: GCCCurrency) -> String {
        ArabicFormatters.shared.formatCurrency(self, currency: currency)
    }

    func formattedNumber(fractionDigits: Int = 2) -> String {
        ArabicFormatters.shared.formatNumber(self, fractionDigits: fractionDigits)
    }
}
