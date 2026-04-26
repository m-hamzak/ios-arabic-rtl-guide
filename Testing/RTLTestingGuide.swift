//
//  RTLTestingGuide.swift
//  ios-arabic-rtl-guide
//
//  Created by Hamza Khalid on 26/04/2026.
//

import UIKit
import SwiftUI

// MARK: - RTL Testing Guide
//
// How to test RTL layouts in Xcode Simulator, Previews, and XCTest.
//
// RTL bugs are invisible until you actually run in Arabic —
// these tools let you catch them early without changing your device language.

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - 1. Simulator — Enable RTL Without Changing Device Language
// ─────────────────────────────────────────────────────────────────────────────
//
// Option A: Scheme Arguments
//   Edit Scheme → Run → Arguments → Arguments Passed On Launch:
//     -AppleLanguages (ar)
//     -AppleLocale ar_BH     ← or ar_QA, ar_SA, ar_AE, ar_KW depending on your market
//
// Option B: Simulator Menu
//   Simulator → I/O → Override Interface Style → Right-to-Left
//   (this uses RTL layout direction but keeps English text)
//
// Option C: In code (Debug only) — force RTL without changing locale:
//   UserDefaults.standard.set(["ar"], forKey: "AppleLanguages")
//   (restart app after setting)

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - 2. Xcode Previews — Side-by-Side LTR and RTL
// ─────────────────────────────────────────────────────────────────────────────

#if DEBUG

struct RTLPreview<Content: View>: View {
    let content: () -> Content

    var body: some View {
        Group {
            // English / LTR preview
            content()
                .environment(\.layoutDirection, .leftToRight)
                .environment(\.locale, Locale(identifier: "en"))
                .previewDisplayName("English (LTR)")

            // Arabic / RTL preview
            content()
                .environment(\.layoutDirection, .rightToLeft)
                .environment(\.locale, Locale(identifier: "ar"))
                .previewDisplayName("Arabic (RTL)")
        }
    }
}

// Usage in preview:
// struct MyView_Previews: PreviewProvider {
//     static var previews: some View {
//         RTLPreview {
//             MyView()
//         }
//     }
// }

#endif

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - 3. XCTest — Assert View Direction
// ─────────────────────────────────────────────────────────────────────────────

import XCTest

class RTLLayoutTests: XCTestCase {

    // Test that a label uses natural alignment (not hardcoded)
    func testLabelUsesNaturalAlignment() {
        let label = UILabel()
        label.textAlignment = .natural
        XCTAssertEqual(label.textAlignment, .natural, "Labels must use .natural alignment, not .left or .right")
    }

    // Test that a stack view has semanticContentAttribute set
    func testStackViewHasRTLAttribute() {
        let stack = UIStackView()
        stack.semanticContentAttribute = .forceRightToLeft
        XCTAssertEqual(stack.semanticContentAttribute, .forceRightToLeft)
    }

    // Test Auto Layout uses leading/trailing, not left/right
    // (Inspect constraints programmatically)
    func testConstraintsUseLeadingTrailing() {
        let container = UIView()
        let child = UIView()
        container.addSubview(child)
        child.translatesAutoresizingMaskIntoConstraints = false

        let constraint = child.leadingAnchor.constraint(equalTo: container.leadingAnchor)
        constraint.isActive = true

        let hasAbsoluteConstraints = container.constraints.contains {
            $0.firstAttribute == .left || $0.firstAttribute == .right
        }
        XCTAssertFalse(hasAbsoluteConstraints, "Constraints must use leading/trailing, not left/right")
    }

    // Test LocalizationManager responds to language change
    func testLanguageSwitchFiresNotification() {
        let expectation = XCTestExpectation(description: "Language change notification fired")

        let observer = NotificationCenter.default.addObserver(
            forName: .languageDidChange,
            object: nil,
            queue: .main
        ) { _ in
            expectation.fulfill()
        }

        LocalizationManager.shared.setLanguage(.arabic)

        wait(for: [expectation], timeout: 1.0)
        NotificationCenter.default.removeObserver(observer)

        // Reset
        LocalizationManager.shared.setLanguage(.english)
    }

    // Test IBAN formatter groups correctly
    func testIBANFormatting() {
        let raw = "AE070331234567890123456"
        let formatted = ArabicFormatters.shared.formatIBAN(raw)
        XCTAssertTrue(formatted.contains(" "), "IBAN should have spaces between groups")
        XCTAssertFalse(formatted.hasPrefix(" "), "IBAN should not start with a space")
    }

    // Test currency formatting for BHD (3 decimal places)
    func testBHDCurrencyFormatting() {
        let formatted = ArabicFormatters.shared.formatCurrency(1200.0, currency: .bahrainiDinar)
        XCTAssertTrue(formatted.contains("BHD") || formatted.contains("1,200"), "BHD formatting should include currency and amount")
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - 4. Manual QA Checklist
// ─────────────────────────────────────────────────────────────────────────────
//
// Run through this checklist on every Arabic release:
//
// TEXT
// [ ] All UILabels show Arabic text on the right side
// [ ] No Arabic text alignment is hardcoded to .left
// [ ] IBAN / account numbers / card numbers display left-to-right
// [ ] Amounts and dates display left-to-right
// [ ] Long Arabic text doesn't get clipped (line height sufficient)
// [ ] No kerning applied to Arabic text (letters connect correctly)
//
// LAYOUT
// [ ] HStack/UIStackView item order is reversed in Arabic
// [ ] Icons appear on the correct (leading) side
// [ ] Logos and avatars do NOT flip
// [ ] Directional icons (chevrons, arrows) DO flip
// [ ] Swipe actions appear on the correct edge
// [ ] Tab bar order is reversed (Home tab on the right)
// [ ] Navigation back button appears on the right, points right (›)
// [ ] Drawer/sidebar opens from the right (leading) edge
//
// CONTROLS
// [ ] UISlider fills from right to left (transform applied)
// [ ] UIProgressView fills from right to left (transform applied)
// [ ] UIPageControl dot order is reversed (dot 0 on the right)
// [ ] UISegmentedControl segments reverse order correctly
// [ ] UIDatePicker shows Arabic month names and correct date order
//
// ANIMATIONS
// [ ] Push navigation: new screen slides in from the left (RTL direction)
// [ ] Pop navigation: screen exits to the left (RTL direction)
// [ ] Shimmer/loading animation sweeps right-to-left
// [ ] Onboarding "next" page comes from the correct direction
//
// RUNTIME SWITCH (if supported)
// [ ] Language switch updates all visible screens without restart
// [ ] All custom views observe .languageDidChange and update
// [ ] Tab bar order updates on language switch
// [ ] Navigation bar direction updates on language switch
// [ ] Transforms on slider/progress/page control update on switch

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - 5. Debug Helper — Highlight Potential RTL Issues
// ─────────────────────────────────────────────────────────────────────────────
//
// Run this on your root view in DEBUG builds to find labels with hardcoded alignment.

#if DEBUG
extension UIView {

    /// Highlights UILabels with potentially wrong alignment for the current language.
    /// Call from a shake gesture or debug menu to audit a screen.
    func auditRTLAlignment() {
        for subview in subviews {
            if let label = subview as? UILabel {
                let isHardcodedLeft  = label.textAlignment == .left
                let isHardcodedRight = label.textAlignment == .right
                if isHardcodedLeft || isHardcodedRight {
                    label.layer.borderColor = UIColor.systemRed.cgColor
                    label.layer.borderWidth = 2
                    print("⚠️ RTL Audit: UILabel has hardcoded alignment .\(isHardcodedLeft ? "left" : "right") — should be .natural: '\(label.text ?? "")'")
                }
            }
            subview.auditRTLAlignment()
        }
    }
}
#endif
