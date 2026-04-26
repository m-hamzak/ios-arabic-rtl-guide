//
//  LocalizationManager.swift
//  ios-arabic-rtl-guide
//
//  Created by Hamza Khalid on 26/04/2026.
//

import UIKit
import SwiftUI

// MARK: - LocalizationManager
//
// Handles runtime Arabic ↔ English language switching without requiring an app restart.
//
// In GCC banking apps and Qatar government portals, users must switch language from
// within the app's Settings screen — restarting the app is not acceptable UX.
//
// This manager:
//   1. Persists the selected language in UserDefaults
//   2. Overrides the app bundle's language at runtime
//   3. Broadcasts .languageDidChange so all active screens can re-render
//   4. Applies semanticContentAttribute globally via UIView.appearance()
//   5. Provides SwiftUI LayoutDirection for environment injection
//
// ─────────────────────────────────────────────────────────────────────────────
// USAGE
// ─────────────────────────────────────────────────────────────────────────────
//
// AppDelegate / App struct (call once at startup):
//   LocalizationManager.shared.setup()
//
// Switch language (e.g. from Settings screen):
//   LocalizationManager.shared.setLanguage(.arabic)
//
// Observe changes in UIViewController:
//   NotificationCenter.default.addObserver(self,
//       selector: #selector(languageDidChange),
//       name: .languageDidChange, object: nil)
//
// Observe changes in SwiftUI:
//   See RTLEnvironmentSetup.swift → LanguageState

// MARK: - Notification Name

extension Notification.Name {
    /// Fired on the main thread after a language change is applied.
    /// object: AppLanguage — the newly selected language.
    static let languageDidChange = Notification.Name("LocalizationManager.languageDidChange")
}

// MARK: - App Language

enum AppLanguage: String, CaseIterable, Identifiable {
    case arabic  = "ar"
    case english = "en"

    var id: String { rawValue }

    /// Display name in the language itself — used in language picker UI.
    var displayName: String {
        switch self {
        case .arabic:  return "العربية"
        case .english: return "English"
        }
    }

    /// Whether this language is right-to-left.
    var isRTL: Bool { self == .arabic }

    /// UIKit semantic content attribute for this language.
    var semanticContentAttribute: UISemanticContentAttribute {
        isRTL ? .forceRightToLeft : .forceLeftToRight
    }

    /// SwiftUI layout direction for this language.
    var layoutDirection: LayoutDirection {
        isRTL ? .rightToLeft : .leftToRight
    }

    /// Locale for number/date formatting.
    var locale: Locale {
        Locale(identifier: rawValue)
    }
}

// MARK: - LocalizationManager

final class LocalizationManager {

    // MARK: - Singleton

    static let shared = LocalizationManager()
    private init() {}

    // MARK: - Constants

    private let languageKey       = "AppSelectedLanguage"
    private let appleLanguagesKey = "AppleLanguages"

    // MARK: - Current Language

    /// The currently active language. Falls back to device language if none stored.
    var currentLanguage: AppLanguage {
        if let raw = UserDefaults.standard.string(forKey: languageKey),
           let language = AppLanguage(rawValue: raw) {
            return language
        }
        // Use the first preferred device language that matches a supported language
        for preferred in Locale.preferredLanguages {
            let code = String(preferred.prefix(2))
            if let match = AppLanguage(rawValue: code) {
                return match
            }
        }
        return .english
    }

    var isRTL: Bool { currentLanguage.isRTL }

    // MARK: - Setup (call once from AppDelegate / @main App struct)

    func setup() {
        applyGlobalDirection(for: currentLanguage)
    }

    // MARK: - Language Switch

    /// Switches the app language at runtime. Safe to call from any thread.
    /// All observers of .languageDidChange will receive the new AppLanguage.
    func setLanguage(_ language: AppLanguage) {
        guard language != currentLanguage else { return }

        // Persist selection
        UserDefaults.standard.set(language.rawValue, forKey: languageKey)
        // Override system language for NSLocalizedString resolution
        UserDefaults.standard.set([language.rawValue], forKey: appleLanguagesKey)
        UserDefaults.standard.synchronize()

        // Apply UIKit appearance globally
        applyGlobalDirection(for: language)

        // Notify observers on main thread
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .languageDidChange,
                object: language
            )
        }
    }

    // MARK: - Global Direction (UIKit)

    /// Sets semanticContentAttribute on UIView, UINavigationBar, and UITabBar globally.
    /// Called on setup and on every language switch.
    private func applyGlobalDirection(for language: AppLanguage) {
        let attribute = language.semanticContentAttribute
        UIView.appearance().semanticContentAttribute           = attribute
        UINavigationBar.appearance().semanticContentAttribute  = attribute
        UITabBar.appearance().semanticContentAttribute         = attribute
        UIToolbar.appearance().semanticContentAttribute        = attribute
        UISearchBar.appearance().semanticContentAttribute      = attribute
    }

    // MARK: - SwiftUI Direction

    var swiftUILayoutDirection: LayoutDirection {
        currentLanguage.layoutDirection
    }

    // MARK: - Localised String

    /// Returns the localised string for the current language.
    /// Falls back gracefully if the Arabic .lproj is incomplete — common during development.
    func string(for key: String, comment: String = "") -> String {
        let languageCode = currentLanguage.rawValue
        if let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return NSLocalizedString(key, bundle: bundle, comment: comment)
        }
        return NSLocalizedString(key, comment: comment)
    }
}

// MARK: - String Extension

extension String {
    /// Shorthand for LocalizationManager.shared.string(for: self)
    var localized: String {
        LocalizationManager.shared.string(for: self)
    }
}

// MARK: - View Extension (SwiftUI)

extension View {
    /// Injects the current language direction into the SwiftUI environment.
    /// Apply to the root view so all children inherit the correct layout direction.
    func applyAppLanguageDirection() -> some View {
        self.environment(
            \.layoutDirection,
            LocalizationManager.shared.swiftUILayoutDirection
        )
    }
}
