<h1 align="center">iOS Arabic & RTL Guide</h1>

<p align="center">
  <a href="https://swift.org"><img src="https://img.shields.io/badge/Swift-5.9-F54A2A?style=flat&logo=swift&logoColor=white"/></a>
  <a href="https://developer.apple.com/ios/"><img src="https://img.shields.io/badge/iOS-15%2B-lightgrey?style=flat&logo=apple&logoColor=white"/></a>
  <img src="https://img.shields.io/badge/SwiftUI%20%2B%20UIKit-Both-6A0DAD?style=flat"/>
  <img src="https://img.shields.io/badge/GCC%20Banking%20%2B%20Government-Production-blue?style=flat"/>
  <img src="https://img.shields.io/badge/License-MIT-green?style=flat"/>
</p>

<p align="center">
  The most comprehensive iOS Arabic/RTL reference on GitHub.<br/>
  Runtime language switching, every UIKit view, every SwiftUI container, NSAttributedString, animations, GCC currency formatting, 12 documented pitfalls, and a full QA checklist.<br/>
  Built from production experience across GCC banking apps and Qatar government projects.
</p>

---

## Why this repo?

Arabic localisation in iOS goes far beyond flipping a layout. Most guides show the basics. Production apps hit the edge cases:

- Runtime language switching without an app restart
- IBAN and account numbers that must stay left-to-right inside an Arabic screen
- UISlider, UIProgressView, and UIPageControl that don't flip automatically
- Tab bar order that must reverse in RTL
- NSAttributedString with mixed Arabic and English runs
- Arabic typography — kerning that breaks letter connections, line height that clips diacritics
- Animations that slide from the wrong direction

This repo documents what actually happens in large Arabic-language apps — both SwiftUI and UIKit — with code you can copy directly.

---

## Real-world context

These patterns come from production work on:

- **5 mobile banking applications across the GCC** (Khaleeji Commercial Bank, Bank of Bahrain & Kuwait, Habib Metro Bank, Summit Bank, Faysal Bank) — fully bilingual Arabic/English apps where RTL correctness was a release requirement, not a nice-to-have
- **Government document systems in Doha, Qatar** — Arabic-primary apps with complex form layouts, legal contract rendering, bidirectional field values, and strict accessibility standards

---

## Structure

```
ios-arabic-rtl-guide/
├── Localization/
│   ├── LocalizationManager.swift        → Runtime Arabic ↔ English switching (no restart)
│   └── ArabicFormatters.swift           → Number, date, currency formatting for GCC (BHD, SAR, QAR, AED, KWD)
├── SwiftUI/
│   ├── RTLEnvironmentSetup.swift        → Root injection, LanguageState, UIKit bridge, Preview helper
│   ├── RTLViewExamples.swift            → Text, HStack, VStack, List, Form, NavigationStack, TabView, Grid, ScrollView
│   ├── RTLAnimations.swift              → Direction-aware slide transitions, drawers, onboarding, shimmer
│   └── RTLCustomComponents.swift        → ProgressBar, StepIndicator, BiDirectionalTextField, CurrencyAmountView, LanguageSwitcher
├── UIKit/
│   ├── RTLBasicViews.swift              → UILabel, UIButton, UITextField, UITextView, UIImageView
│   ├── RTLContainerViews.swift          → UIStackView, UITableView, UICollectionView, UIScrollView, Auto Layout
│   ├── RTLNavigationAndTabBar.swift     → UINavigationController, UITabBarController, UISearchBar, UIToolbar, push transitions
│   ├── RTLControlViews.swift            → UISlider, UISegmentedControl, UIProgressView, UIPageControl, UIDatePicker, UISwitch, UIStepper, UIPickerView
│   └── RTLTextAttributes.swift          → NSAttributedString, NSWritingDirection, paragraph styles, bidi text, Arabic typography
├── CommonPitfalls/
│   └── RTLPitfalls.swift                → 12 real pitfalls — ❌ wrong / ✅ correct with explanations
└── Testing/
    └── RTLTestingGuide.swift            → Simulator args, Xcode Previews, XCTest examples, manual QA checklist
```

---

## Localization

### `LocalizationManager.swift`
Runtime Arabic ↔ English switching without restarting the app.

- `AppLanguage` enum — `.arabic` / `.english` with display names, locale, layout direction
- `setLanguage(_:)` — switches bundle, UserDefaults, fires `.languageDidChange` on the main thread
- `applyGlobalDirection(for:)` — sets `UIView.appearance().semanticContentAttribute` for UIView, UINavigationBar, UITabBar, UIToolbar, UISearchBar
- `swiftUILayoutDirection` — returns SwiftUI `LayoutDirection` for `.environment()` injection
- `String.localized` — shorthand for `LocalizationManager.shared.string(for:)`
- `View.applyAppLanguageDirection()` — convenience modifier for root views

### `ArabicFormatters.swift`
Number, currency, and date formatting for GCC markets.

- **Currencies**: BHD (3dp), SAR (2dp), QAR (2dp), AED (2dp), KWD (3dp) — correct decimal places per currency
- `formatNumber(_:fractionDigits:)` — Western Arabic numerals (0–9) for financial values
- `formatNumberEasternArabic(_:)` — Eastern Arabic-Indic numerals (٠١٢٣٤٥٦٧٨٩) for Arabic text
- `formatCurrency(_:currency:showCode:)` — locale-aware currency display
- `currencyComponents(_:currency:)` — amount and code separately, for custom layout in RTL screens
- `formatDateGCC(_:)` — `dd/MM/yyyy`, standard in GCC banking
- `formatIBAN(_:)` — groups IBAN into blocks of 4 (always LTR)
- `maskAccountNumber(_:visibleDigits:)` — `**** 1234` masking for account display
- `ArabicPluralForm` — Arabic has 6 plural forms; this maps count → correct form (zero/one/two/few/many/other)

---

## SwiftUI

### `RTLEnvironmentSetup.swift`
Root setup — inject once, all children inherit.

- `LanguageState` — `ObservableObject` that publishes `language`, `layoutDirection`, and `locale`; observes `.languageDidChange`
- `RootAppView` — shows how to wire `.environment(\.layoutDirection)` + `.environment(\.locale)` + `.environmentObject(languageState)` at the App level
- `RTLPreviewHelper` — renders your view side-by-side in LTR and RTL for Xcode previews
- `RTLHostingController` — wraps a SwiftUI view inside UIKit with correct direction injection

### `RTLViewExamples.swift`
Covers every major SwiftUI view type with annotated RTL examples:

| View | RTL Behaviour |
|---|---|
| Text | Use `.leading` alignment — maps to right in RTL |
| HStack | Item order reverses automatically in RTL |
| VStack | Use `.leading` alignment on VStack itself |
| List | Swipe actions, separators, accessories flip automatically |
| Form / TextField | Natural alignment; force LTR on IBAN and amount fields |
| NavigationStack | Back button flips; push animation slides from correct side |
| TabView | Tab order reverses; directional icons flip |
| LazyVGrid | Item fill order reverses (right-to-left in RTL) |
| ScrollView (horizontal) | Content starts from the right edge in RTL |

### `RTLAnimations.swift`
Direction-aware transitions and animations.

- `AnyTransition.slideFromTrailing(direction:)` — correct push animation (right in LTR, left in RTL)
- `AnyTransition.slideFromLeading(direction:)` — correct back/dismiss animation
- `RTLDrawerExample` — side drawer that opens from the leading edge in both directions
- `OnboardingFlow` — page transitions that go the correct way in RTL
- `ShimmerView` — loading shimmer that sweeps in the reading direction

### `RTLCustomComponents.swift`
Reusable components ready for banking and government apps.

- `RTLProgressBar` — fills from leading edge (right in RTL, left in LTR)
- `StepIndicator` — multi-step flow; step 1 on the right in RTL
- `BiDirectionalTextField` — auto-selects direction based on content type (name/alphanumeric/numeric/password)
- `LanguageSwitcherView` — segmented control for Settings screens
- `CurrencyAmountView` — amount stays LTR, currency code position adapts to direction
- `InfoRowView` — label + value pair with optional LTR override for the value
- `ShimmerView` — RTL-aware loading placeholder
- `TransactionBadge` — incoming/outgoing arrow badges (vertical arrows never flip)

---

## UIKit

### `RTLBasicViews.swift`
- `UILabel.configureForCurrentLanguage()` — natural alignment + semantic attribute
- `UILabel.configureForcedLTR()` — for IBANs, codes, account numbers
- `UIButton.configureForCurrentLanguage()` — title + image position via semantic attribute; `UIButton.Configuration` for iOS 15+
- `RTLTextField` — subclass with `ContentKind` (name/alphanumeric/numeric/password), Arabic placeholder support, language change observer
- `RTLTextView` — subclass that sets `defaultTextAttributes` writing direction and `typingAttributes` so the cursor starts on the correct side
- `UIImageView.configureRTLFlipping(isDirectional:)` — applies `scaleX: -1` transform for directional icons only
- `UIView.applyCurrentLanguageDirection()` — recursive direction application to all subviews
- `UIView.autoApplyLanguageDirection()` — self-registering observer pattern

### `RTLContainerViews.swift`
- `UIStackView.configureForCurrentLanguage()` — sets attribute on stack and all arranged subviews
- `RTLTableView` — reloads on language change
- `RTLTableViewCell` — accessory chevron, swipe action edges, natural label alignment
- `RTLFlowLayout` — `UICollectionViewFlowLayout` subclass with `flipsHorizontallyInOppositeLayoutDirection = true`
- `RTLCollectionView` — collection view using RTLFlowLayout
- `RTLHorizontalScrollView` — `scrollToLeadingEdge()` starts at the right in RTL
- `RTLConstrainedView` — full example using `leadingAnchor`/`trailingAnchor` and `NSDirectionalEdgeInsets` throughout

### `RTLNavigationAndTabBar.swift`
- `RTLNavigationController` — applies direction to nav bar and all VCs in stack; observes language change
- `UIViewController.makeRTLBackButton(action:)` — chevron.right in RTL, chevron.left in LTR
- `RTLPushTransition` — custom `UIViewControllerAnimatedTransitioning` for direction-correct push animation
- `RTLTabBarController` — stores LTR order, reverses for RTL; observes language change
- `UISearchBar.configureForCurrentLanguage()` — semantic attribute + internal text field direction
- `UIToolbar.configureForCurrentLanguage()` — item order flips with semantic attribute

### `RTLControlViews.swift`

| Control | RTL Behaviour | Fix |
|---|---|---|
| UISlider | Does NOT flip automatically | Apply `transform = CGAffineTransform(scaleX: -1, y: 1)` |
| UIProgressView | Does NOT flip automatically | Apply `transform = CGAffineTransform(scaleX: -1, y: 1)` |
| UIPageControl | Dots do NOT reverse automatically | Apply transform |
| UISegmentedControl | Segments reverse with `semanticContentAttribute` | Set attribute |
| UIDatePicker | Respects locale — Arabic months auto | Set `locale` |
| UISwitch | Intentionally does NOT flip (on/off is universal) | No flip — position via container |
| UIStepper | Does NOT flip | Apply transform so + is on leading edge |
| UIPickerView | Column text alignment needs `.natural` | Set semantic attribute + configure delegate |

### `RTLTextAttributes.swift`
- `NSAttributedString.forCurrentLanguage(_:)` — correct paragraph style for any language
- `NSAttributedString.arabic(_:)` — forced RTL, for Arabic inside LTR screens
- `NSAttributedString.ltrOnly(_:)` — forced LTR, for IBANs inside RTL screens
- `BidirectionalLabel` — UILabel subclass that renders Arabic label + LTR value inline
- `NSMutableParagraphStyle.rtl()` / `.ltr()` / `.natural()` — convenient paragraph style factory
- `UITextView.configureTypingDirectionForCurrentLanguage()` — sets `defaultTextAttributes` and `typingAttributes` so cursor position is correct
- `NSAttributedString.isolatedLTR(_:)` — wraps text with Unicode LTR isolate characters (U+2066/U+2069) to prevent bidi reordering
- `NSMutableParagraphStyle.arabicBody(lineSpacingMultiplier:)` — line height for Arabic diacritics, kern = 0
- `ArabicStatementView` — UITextView configured for long-form Arabic contract/T&C text

---

## Common Pitfalls

12 real issues with ❌ wrong code and ✅ correct code:

| # | Pitfall | Affected Area |
|---|---|---|
| 1 | Hardcoded `.left` text alignment | UILabel, UITextField |
| 2 | `leftAnchor` / `rightAnchor` in Auto Layout | All UIKit layouts |
| 3 | `UIEdgeInsets` instead of `NSDirectionalEdgeInsets` | Custom padding everywhere |
| 4 | UIStackView missing `semanticContentAttribute` | Custom list cells, header views |
| 5 | Flipping logos, flags, avatars | Icon-heavy screens |
| 6 | IBAN / account number reading RTL | Banking transaction screens |
| 7 | UICollectionView items in wrong order | Card carousels, service grids |
| 8 | UISlider and UIProgressView not flipping | Settings, transfer progress |
| 9 | Custom views not observing `.languageDidChange` | Runtime language switch |
| 10 | SwiftUI `.slide` transition going wrong direction | Navigation, onboarding |
| 11 | Tab bar order not reversing | UITabBarController |
| 12 | Kerning applied to Arabic text | Long-form text, contracts |

---

## Testing

### Simulator — Force Arabic without changing device language
```
Edit Scheme → Run → Arguments Passed On Launch:
  -AppleLanguages (ar)
  -AppleLocale ar_BH
```

### Xcode Previews — Side-by-side LTR and RTL
```swift
RTLPreview {
    MyView()
}
```

### Manual QA Checklist
See `Testing/RTLTestingGuide.swift` — 40-item checklist covering text, layout, controls, animations, and runtime switching.

---

## Key rules at a glance

- `leadingAnchor` / `trailingAnchor` — never `leftAnchor` / `rightAnchor`
- `NSDirectionalEdgeInsets` — never `UIEdgeInsets` for language-sensitive padding
- `.natural` text alignment — never `.left` for body text
- `kern = 0` — never kern Arabic text
- Never flip logos, flags, or avatars — only flip directional icons
- Always force LTR for IBANs, account numbers, card numbers, amounts
- UISlider, UIProgressView, UIPageControl, UIStepper — apply `scaleX: -1` transform
- UICollectionViewFlowLayout — must subclass and set `flipsHorizontallyInOppositeLayoutDirection = true`
- UITabBarController — reverse `viewControllers` array for RTL
- Always observe `.languageDidChange` in custom views — UIView.appearance() does not update them at runtime

---

## Author

**Muhammad Hamza Khalid** — Senior Mobile Engineer · iOS · Swift · SwiftUI · Arabic Localisation · GCC Banking

[GitHub](https://github.com/m-hamzak) · [LinkedIn](https://linkedin.com/in/m-hamzak) · [Medium](https://medium.com/@m-hamzak)
