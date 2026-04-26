//
//  RTLExamples.swift
//  ios-arabic-rtl-guide
//
//  Created by Hamza Khalid on 26/04/2026.
//

import SwiftUI

// MARK: - RTL in SwiftUI
//
// SwiftUI respects the device language by default — but banking and government apps
// need explicit control, especially when supporting runtime language switching.
//
// Key principle: never hardcode .leading / .trailing for language-sensitive layouts.
// Use .layoutDirectionAware extensions and let the environment drive direction.

// MARK: - 1. Driving RTL from the Environment
//
// Wrap your root view to inject layout direction from LocalizationManager.
// All child views inherit this automatically.

struct RootView: View {
    @StateObject private var languageState = LanguageState()

    var body: some View {
        ContentView()
            .environment(\.layoutDirection, languageState.direction)
            .environment(\.locale, languageState.locale)
    }
}

final class LanguageState: ObservableObject {
    @Published var direction: LayoutDirection = LocalizationManager.shared.swiftUILayoutDirection
    @Published var locale: Locale = Locale(identifier: LocalizationManager.shared.currentLanguage.rawValue)

    private var cancellable: Any?

    init() {
        cancellable = NotificationCenter.default.addObserver(
            forName: .languageDidChange,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let language = notification.object as? AppLanguage else { return }
            self?.direction = language.isRTL ? .rightToLeft : .leftToRight
            self?.locale = Locale(identifier: language.rawValue)
        }
    }
}

// MARK: - 2. HStack Ordering
//
// HStack automatically reverses item order in RTL — but only if you use
// the environment's direction rather than hardcoded values.

struct BankTransactionRow: View {
    let icon: String
    let title: String
    let amount: String
    let isDebit: Bool

    var body: some View {
        // HStack order: in LTR → [icon] [title]        [amount]
        //               in RTL → [amount]        [title] [icon]
        // This flips automatically. No manual handling needed.
        HStack {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .frame(width: 36, height: 36)

            VStack(alignment: .leading) {
                Text(title)
                    .font(.body)
                Text("Today")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(amount)
                .foregroundColor(isDebit ? .red : .green)
                .fontWeight(.semibold)
        }
        .padding()
    }
}

// MARK: - 3. Text Alignment
//
// Use .leading alignment — it maps to right in RTL, left in LTR.
// Never use .trailing for body text — it becomes left-aligned in RTL, which looks wrong.

struct FormFieldView: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {  // .leading = language-aware
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(value)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)  // Not .left
        }
    }
}

// MARK: - 4. Images and SF Symbols
//
// SF Symbols with directional variants flip automatically.
// For custom icons, use .flipsForRightToLeftLayoutDirection(true) if the icon
// has a direction (e.g. arrows, chevrons, back button icons).
// Do NOT flip logos, flags, or icons with no inherent direction.

struct NavigationBackButton: View {
    @Environment(\.layoutDirection) var layoutDirection

    var body: some View {
        Image(systemName: "chevron.left")
            // SF Symbols handle this automatically for most directional symbols.
            // For custom assets: .flipsForRightToLeftLayoutDirection(true)
            .flipsForRightToLeftLayoutDirection(true)
            .imageScale(.large)
    }
}

// MARK: - 5. Bidirectional Text (Arabic + English mixed content)
//
// Government forms and banking statements often mix Arabic labels with
// English values (account numbers, amounts in English digits, dates).
// Use .environment(\.layoutDirection) to read direction and apply
// natural alignment per text type.

struct BiDirectionalFormRow: View {
    let arabicLabel: String   // e.g. "رقم الحساب"
    let englishValue: String  // e.g. "AE123456789012345678"

    @Environment(\.layoutDirection) var direction

    var body: some View {
        HStack {
            if direction == .rightToLeft {
                // RTL: Arabic label on the right, value flows left
                Spacer()
                Text(englishValue)
                    .font(.monospacedDigit(.body)())
                    .environment(\.layoutDirection, .leftToRight)  // Force LTR for account numbers

                Text(arabicLabel)
                    .font(.body)
            } else {
                Text(arabicLabel)
                    .font(.body)
                Text(englishValue)
                    .font(.monospacedDigit(.body)())
                Spacer()
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - 6. Progress / Step Indicators
//
// Progress bars and step indicators must flip in RTL.
// A "step 1 → step 2 → step 3" flow reads right-to-left in Arabic.

struct RTLProgressBar: View {
    let progress: Double  // 0.0 to 1.0
    @Environment(\.layoutDirection) var direction

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: direction == .rightToLeft ? .trailing : .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.secondary.opacity(0.2))
                    .frame(height: 8)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.accentColor)
                    .frame(width: geometry.size.width * progress, height: 8)
            }
        }
        .frame(height: 8)
    }
}

// MARK: - 7. RTL-Aware Padding Helper
//
// When you need asymmetric padding that should flip (e.g. indent a list item
// on the leading side), use this helper instead of hardcoding left/right.

extension View {
    func leadingPadding(_ amount: CGFloat) -> some View {
        self.padding(.leading, amount)  // .leading is already direction-aware
    }

    func trailingPadding(_ amount: CGFloat) -> some View {
        self.padding(.trailing, amount)
    }
}

// MARK: - 8. Runtime Language Switcher UI
//
// A simple toggle for use in Settings screens in banking / government apps.

struct LanguageSwitcherView: View {
    @State private var selectedLanguage = LocalizationManager.shared.currentLanguage

    var body: some View {
        Picker("Language", selection: $selectedLanguage) {
            ForEach(AppLanguage.allCases, id: \.self) { language in
                Text(language.displayName).tag(language)
            }
        }
        .pickerStyle(.segmented)
        .onChange(of: selectedLanguage) { newValue in
            LocalizationManager.shared.setLanguage(newValue)
        }
    }
}
