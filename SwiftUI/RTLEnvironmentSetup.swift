//
//  RTLEnvironmentSetup.swift
//  ios-arabic-rtl-guide
//
//  Created by Hamza Khalid on 26/04/2026.
//

import SwiftUI

// MARK: - RTL Environment Setup
//
// SwiftUI inherits layout direction from the environment.
// Inject it once at the root and every child view gets it automatically.
//
// This file covers:
//   1. LanguageState — ObservableObject that drives direction changes app-wide
//   2. RootAppView — how to wire everything together at the App struct level
//   3. RTLPreviewHelper — convenience for Xcode previews in both languages

// MARK: - 1. LanguageState
//
// Central observable state that holds the current language.
// Inject this into the environment at the top of the view hierarchy.
// All views that depend on language use @EnvironmentObject to access it.

final class LanguageState: ObservableObject {
    @Published var language: AppLanguage = LocalizationManager.shared.currentLanguage
    @Published var layoutDirection: LayoutDirection = LocalizationManager.shared.swiftUILayoutDirection
    @Published var locale: Locale = LocalizationManager.shared.currentLanguage.locale

    private var observer: Any?

    init() {
        observer = NotificationCenter.default.addObserver(
            forName: .languageDidChange,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let newLanguage = notification.object as? AppLanguage else { return }
            self?.language        = newLanguage
            self?.layoutDirection = newLanguage.layoutDirection
            self?.locale          = newLanguage.locale
        }
    }

    deinit {
        if let observer { NotificationCenter.default.removeObserver(observer) }
    }

    func switchLanguage() {
        let next: AppLanguage = language == .arabic ? .english : .arabic
        LocalizationManager.shared.setLanguage(next)
    }
}

// MARK: - 2. Root App View
//
// Wire LanguageState into the environment at the App level.
// The .environment(\.layoutDirection) call is the critical one —
// it propagates direction to every SwiftUI view in the tree.
//
// Also inject .locale so that Text views using format styles
// (e.g. Text(date, style: .date)) pick up the correct locale.

struct RootAppView: View {
    @StateObject private var languageState = LanguageState()

    var body: some View {
        ContentPlaceholderView()
            // Direction: makes HStack, leading/trailing, text alignment language-aware
            .environment(\.layoutDirection, languageState.layoutDirection)
            // Locale: affects Text format styles, DatePicker display, etc.
            .environment(\.locale, languageState.locale)
            // Share LanguageState with any descendant that needs it
            .environmentObject(languageState)
    }
}

// Placeholder — replace with your real root view
struct ContentPlaceholderView: View {
    var body: some View { Text("App Root") }
}

// MARK: - 3. Accessing Language in Child Views

struct ExampleChildView: View {
    @EnvironmentObject var languageState: LanguageState
    @Environment(\.layoutDirection) var direction

    var body: some View {
        VStack(alignment: .leading) {
            Text(languageState.language == .arabic ? "مرحباً" : "Hello")
                .font(.title)

            Text(direction == .rightToLeft ? "RTL Active" : "LTR Active")
                .font(.caption)
                .foregroundColor(.secondary)

            // React to language changes — language switch updates all views automatically
            // because LanguageState is @Published and injected as @EnvironmentObject
        }
    }
}

// MARK: - 4. RTLPreviewHelper
//
// Use this in Xcode previews to see your view in both Arabic and English
// without changing device settings.

struct RTLPreviewHelper<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        HStack(spacing: 0) {
            // English / LTR
            content
                .environment(\.layoutDirection, .leftToRight)
                .environment(\.locale, Locale(identifier: "en"))
                .frame(maxWidth: .infinity)
                .background(Color(.systemBackground))
                .previewDisplayName("English LTR")

            Divider()

            // Arabic / RTL
            content
                .environment(\.layoutDirection, .rightToLeft)
                .environment(\.locale, Locale(identifier: "ar"))
                .frame(maxWidth: .infinity)
                .background(Color(.systemBackground))
                .previewDisplayName("Arabic RTL")
        }
    }
}

// MARK: - 5. Preview Usage Example

#if DEBUG
struct ExampleView_Previews: PreviewProvider {
    static var previews: some View {
        RTLPreviewHelper {
            HStack {
                Image(systemName: "person.circle.fill")
                VStack(alignment: .leading) {
                    Text("Account Holder")
                    Text("secondary info")
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text("BHD 500.000")
            }
            .padding()
        }
    }
}
#endif

// MARK: - 6. UIKit Integration Bridge
//
// If your app has a UIKit root (AppDelegate / UIHostingController),
// call this from application(_:didFinishLaunchingWithOptions:):
//
//   LocalizationManager.shared.setup()
//
// And when hosting SwiftUI inside UIKit:

import UIKit

class RTLHostingController<Content: View>: UIHostingController<AnyView> {
    private let languageState = LanguageState()

    init(rootView: Content) {
        let wrappedView = AnyView(
            rootView
                .environment(\.layoutDirection, LocalizationManager.shared.swiftUILayoutDirection)
                .environment(\.locale, LocalizationManager.shared.currentLanguage.locale)
                .environmentObject(LanguageState())
        )
        super.init(rootView: wrappedView)
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
