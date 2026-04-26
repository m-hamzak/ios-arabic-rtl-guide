//
//  RTLCustomComponents.swift
//  ios-arabic-rtl-guide
//
//  Created by Hamza Khalid on 26/04/2026.
//

import SwiftUI

// MARK: - RTL-Aware Custom Components
//
// Reusable components built for both LTR and RTL from the ground up.
// Drop these into any SwiftUI project — they read the environment direction automatically.

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - 1. Progress Bar
// ─────────────────────────────────────────────────────────────────────────────
//
// Standard ProgressView in SwiftUI fills left-to-right always.
// This custom version fills from the leading edge — right in RTL, left in LTR.

struct RTLProgressBar: View {
    let progress: Double  // 0.0 to 1.0
    var color: Color = .accentColor
    var height: CGFloat = 8

    @Environment(\.layoutDirection) var direction

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: direction == .rightToLeft ? .trailing : .leading) {
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(color.opacity(0.2))

                RoundedRectangle(cornerRadius: height / 2)
                    .fill(color)
                    .frame(width: geo.size.width * min(max(progress, 0), 1))
            }
        }
        .frame(height: height)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - 2. Step Indicator
// ─────────────────────────────────────────────────────────────────────────────
//
// Used in multi-step flows: KYC, onboarding, fund transfer wizard.
// In RTL: Step 1 appears on the right, last step on the left.

struct StepIndicator: View {
    let totalSteps: Int
    let currentStep: Int  // 1-based
    var activeColor: Color = .accentColor

    @Environment(\.layoutDirection) var direction

    var body: some View {
        HStack(spacing: 0) {
            // In RTL, reverse the step order so step 1 is on the right
            let steps = direction == .rightToLeft
                ? Array((1...totalSteps).reversed())
                : Array(1...totalSteps)

            ForEach(Array(steps.enumerated()), id: \.element) { index, step in
                // Step circle
                ZStack {
                    Circle()
                        .fill(stepIsComplete(step) ? activeColor : Color(.systemGray4))
                        .frame(width: 28, height: 28)

                    if stepIsComplete(step) {
                        Image(systemName: step < currentStep ? "checkmark" : "\(step).circle.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 12, weight: .bold))
                    } else {
                        Text("\(step)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                }

                // Connector line between steps
                if index < totalSteps - 1 {
                    Rectangle()
                        .fill(step < currentStep ? activeColor : Color(.systemGray4))
                        .frame(height: 2)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private func stepIsComplete(_ step: Int) -> Bool {
        step <= currentStep
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - 3. Bidirectional TextField
// ─────────────────────────────────────────────────────────────────────────────
//
// A TextField that automatically applies the correct direction:
// - Arabic content → RTL cursor, right-aligned, Arabic keyboard
// - Numeric / IBAN content → always LTR regardless of app language
//
// Used for: name fields (RTL in Arabic), IBAN fields (always LTR),
//           amount fields (always LTR), note fields (follows app language).

enum FieldContentType {
    case name          // Follows app language direction
    case alphanumeric  // Always LTR (IBANs, account numbers, codes)
    case numeric       // Always LTR (amounts, phone numbers)
    case note          // Follows app language direction, multiline
}

struct BiDirectionalTextField: View {
    let placeholder: String
    @Binding var text: String
    var contentType: FieldContentType = .name
    var label: String? = nil

    @Environment(\.layoutDirection) var appDirection

    private var fieldDirection: LayoutDirection {
        switch contentType {
        case .alphanumeric, .numeric: return .leftToRight
        case .name, .note:            return appDirection
        }
    }

    private var keyboardType: UIKeyboardType {
        contentType == .numeric ? .decimalPad : .default
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let label {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            TextField(placeholder, text: $text)
                .textFieldStyle(.roundedBorder)
                .environment(\.layoutDirection, fieldDirection)
                .keyboardType(keyboardType)
                .autocorrectionDisabled(contentType == .alphanumeric)
                .textInputAutocapitalization(contentType == .alphanumeric ? .characters : .sentences)
                .multilineTextAlignment(fieldDirection == .rightToLeft ? .trailing : .leading)
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - 4. Language Switcher
// ─────────────────────────────────────────────────────────────────────────────

struct LanguageSwitcherView: View {
    @EnvironmentObject var languageState: LanguageState

    var body: some View {
        Picker("Language", selection: Binding(
            get: { languageState.language },
            set: { LocalizationManager.shared.setLanguage($0) }
        )) {
            ForEach(AppLanguage.allCases) { language in
                Text(language.displayName).tag(language)
            }
        }
        .pickerStyle(.segmented)
        // The switcher itself is always LTR — English on left, Arabic on right
        .environment(\.layoutDirection, .leftToRight)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - 5. Currency Amount Display
// ─────────────────────────────────────────────────────────────────────────────
//
// Amounts must always be LTR. The currency label can be Arabic text.
// Layout: [amount] [currency code] in LTR
//         [currency code] [amount] in RTL  — but both pieces stay LTR

struct CurrencyAmountView: View {
    let amount: Double
    let currency: GCCCurrency
    var font: Font = .title2
    var amountColor: Color = .primary

    @Environment(\.layoutDirection) var direction

    var body: some View {
        let (amountStr, code) = ArabicFormatters.shared.currencyComponents(amount, currency: currency)

        HStack(spacing: 4) {
            if direction == .rightToLeft {
                // RTL: code on right, amount reads left-to-right
                Text(code)
                    .font(font.weight(.regular))
                    .foregroundColor(.secondary)
                Text(amountStr)
                    .font(font.weight(.bold))
                    .foregroundColor(amountColor)
                    .environment(\.layoutDirection, .leftToRight)
            } else {
                // LTR: amount first, then code
                Text(amountStr)
                    .font(font.weight(.bold))
                    .foregroundColor(amountColor)
                Text(code)
                    .font(font.weight(.regular))
                    .foregroundColor(.secondary)
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - 6. Info Row (label + value, used in forms and summaries)
// ─────────────────────────────────────────────────────────────────────────────

struct InfoRowView: View {
    let label: String
    let value: String
    var valueIsLTR: Bool = false  // Set true for IBANs, account numbers, dates

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(value)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .environment(\.layoutDirection, valueIsLTR ? .leftToRight : .rightToLeft)
        }
        .padding(.vertical, 4)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - 7. RTL-Aware Divider with Label
// ─────────────────────────────────────────────────────────────────────────────

struct LabeledDivider: View {
    let label: String

    var body: some View {
        HStack {
            VStack { Divider() }
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize()
            VStack { Divider() }
        }
        // HStack reverses in RTL: [Divider] [label] [Divider] → still correct layout
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - 8. Directional Icon Badge
// ─────────────────────────────────────────────────────────────────────────────
//
// Used in transaction lists: incoming (green, arrow down) / outgoing (red, arrow up)
// Arrow direction flips in RTL — arrow.right.circle becomes arrow.left.circle

struct TransactionBadge: View {
    enum Direction { case incoming, outgoing }
    let direction: Direction

    @Environment(\.layoutDirection) var layoutDirection

    private var iconName: String {
        switch direction {
        case .incoming: return "arrow.down.circle.fill"
        case .outgoing: return "arrow.up.circle.fill"
        }
    }

    var body: some View {
        Image(systemName: iconName)
            .foregroundColor(direction == .incoming ? .green : .red)
            .font(.title2)
            // Up/down arrows do NOT flip — vertical direction has no RTL meaning
            .flipsForRightToLeftLayoutDirection(false)
    }
}
