//
//  RTLPitfalls.swift
//  ios-arabic-rtl-guide
//
//  Created by Hamza Khalid on 26/04/2026.
//

import UIKit
import SwiftUI

// MARK: - Common RTL Pitfalls
//
// 12 real issues encountered across GCC banking apps and Qatar government projects.
// Each section: the wrong approach, the correct approach, and why it matters.

// ─────────────────────────────────────────────────────────────────────────────
// PITFALL 1: Hardcoded text alignment (.left instead of .natural)
// ─────────────────────────────────────────────────────────────────────────────

class Pitfall1_TextAlignment {
    func wrong(_ label: UILabel) {
        label.textAlignment = .left  // ❌ Stays left in Arabic. Arabic text reads from wrong side.
    }
    func correct(_ label: UILabel) {
        label.textAlignment = .natural  // ✅ Maps to .right in RTL, .left in LTR automatically.
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// PITFALL 2: Using leftAnchor / rightAnchor in Auto Layout
// ─────────────────────────────────────────────────────────────────────────────

class Pitfall2_AutoLayout {
    func wrong(icon: UIView, container: UIView) {
        // ❌ leftAnchor is absolute — never flips. Icon is stuck on the left in Arabic.
        icon.leftAnchor.constraint(equalTo: container.leftAnchor, constant: 16).isActive = true
    }
    func correct(icon: UIView, container: UIView) {
        // ✅ leadingAnchor flips to the right in RTL.
        icon.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16).isActive = true
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// PITFALL 3: UIEdgeInsets instead of NSDirectionalEdgeInsets
// ─────────────────────────────────────────────────────────────────────────────

class Pitfall3_EdgeInsets {
    func wrong(_ view: UIView) {
        // ❌ UIEdgeInsets.left is absolute — 16pt gap stays on the left in Arabic.
        view.layoutMargins = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 8)
    }
    func correct(_ view: UIView) {
        // ✅ NSDirectionalEdgeInsets.leading flips to the right in RTL.
        view.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 8)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// PITFALL 4: Forgetting semanticContentAttribute on UIStackView
// ─────────────────────────────────────────────────────────────────────────────
//
// UIView.appearance().semanticContentAttribute = .forceRightToLeft sets it globally,
// but UIStackView subclasses do NOT always inherit it at the time of init.
// Always set it explicitly on every stack.

class Pitfall4_StackView {
    func wrong() -> UIStackView {
        let stack = UIStackView()
        stack.axis = .horizontal
        // ❌ No attribute set. Items stay in LTR order even when Arabic is active.
        return stack
    }
    func correct() -> UIStackView {
        let stack = UIStackView()
        stack.axis = .horizontal
        // ✅ Set it on the stack — children inherit the direction.
        stack.semanticContentAttribute = LocalizationManager.shared.layoutDirection
        return stack
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// PITFALL 5: Flipping logos, flags, and avatars
// ─────────────────────────────────────────────────────────────────────────────

struct Pitfall5_ImageFlipping: View {
    var body: some View {
        VStack {
            // ❌ Logo appears mirrored in Arabic. Bank name reads backwards.
            Image("bank-logo").flipsForRightToLeftLayoutDirection(true)

            // ✅ Logos never flip. Direction has no meaning for a logo.
            Image("bank-logo").flipsForRightToLeftLayoutDirection(false)

            // ✅ DO flip directional icons: arrows, chevrons, back buttons.
            Image(systemName: "chevron.right").flipsForRightToLeftLayoutDirection(true)
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// PITFALL 6: IBAN / account numbers reading right-to-left
// ─────────────────────────────────────────────────────────────────────────────
//
// In an RTL screen, "AE07 0331 2345" gets rendered as "5432 1330 70EA"
// because the bidi algorithm treats each character group as its own run.
// You must force LTR for all alphanumeric identifiers.

struct Pitfall6_IBAN: View {
    let iban = "AE070331234567890123456"
    var body: some View {
        VStack {
            // ❌ In Arabic RTL, the IBAN renders in the wrong visual order.
            Text(iban)

            // ✅ Force LTR — IBAN always reads left to right regardless of app language.
            Text(iban).environment(\.layoutDirection, .leftToRight)
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// PITFALL 7: UICollectionView items in the wrong order
// ─────────────────────────────────────────────────────────────────────────────
//
// UICollectionViewFlowLayout does NOT reverse item order in RTL.
// You must use a subclassed layout with flipsHorizontallyInOppositeLayoutDirection = true.

class Pitfall7_CollectionView {
    func wrong() -> UICollectionViewLayout {
        // ❌ Standard flow layout — item 0 always on the left, even in Arabic.
        return UICollectionViewFlowLayout()
    }
    func correct() -> UICollectionViewLayout {
        // ✅ RTLFlowLayout flips item positions for RTL (defined in RTLContainerViews.swift)
        return RTLFlowLayout()
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// PITFALL 8: UISlider and UIProgressView not flipping
// ─────────────────────────────────────────────────────────────────────────────
//
// UISlider and UIProgressView do NOT flip automatically in RTL.
// A progress bar filling from left to right in an Arabic banking app
// implies the wrong direction for a language that reads right to left.

class Pitfall8_SliderProgress {
    func wrong(slider: UISlider, progress: UIProgressView) {
        // ❌ No flip — fills left to right in Arabic. Counter-intuitive.
    }
    func correct(slider: UISlider, progress: UIProgressView) {
        // ✅ Horizontal flip via transform.
        if LocalizationManager.shared.isRTL {
            slider.transform   = CGAffineTransform(scaleX: -1, y: 1)
            progress.transform = CGAffineTransform(scaleX: -1, y: 1)
        } else {
            slider.transform   = .identity
            progress.transform = .identity
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// PITFALL 9: Not observing .languageDidChange in custom views
// ─────────────────────────────────────────────────────────────────────────────
//
// UIView.appearance() sets semanticContentAttribute globally at app startup.
// But custom views already on screen when the user switches language do NOT update.
// They keep the direction they were initialised with.

class Pitfall9_LanguageChangeObserver: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        applyDirection()
        // ❌ Wrong: missing observer — stays in old direction after language switch
    }

    required init?(coder: NSCoder) { super.init(coder: coder) }

    func correct() {
        applyDirection()
        // ✅ Register for the notification
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(languageChanged),
            name: .languageDidChange,
            object: nil
        )
    }

    @objc private func languageChanged() {
        applyDirection()
        setNeedsLayout()
    }

    private func applyDirection() {
        semanticContentAttribute = LocalizationManager.shared.layoutDirection
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// PITFALL 10: SwiftUI transition animation going the wrong direction
// ─────────────────────────────────────────────────────────────────────────────
//
// SwiftUI's .slide transition always slides from the left, regardless of direction.
// In Arabic, a "next page" push should come from the left (since we read right-to-left).

struct Pitfall10_SlideAnimation: View {
    @State private var showNext = false
    @Environment(\.layoutDirection) var direction

    var body: some View {
        ZStack {
            if showNext {
                Text("Next")
                    // ❌ .slide always enters from the left — wrong for Arabic push navigation
                    // .transition(.slide)

                    // ✅ Direction-aware transition (from RTLAnimations.swift)
                    .transition(.slideFromTrailing(direction: direction))
            }
        }
        .animation(.easeInOut, value: showNext)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// PITFALL 11: Tab bar order not reversing in RTL
// ─────────────────────────────────────────────────────────────────────────────
//
// UITabBarController does NOT reverse tab order automatically.
// The leading tab (home) should always be on the leading edge.
// In LTR: leftmost. In RTL: rightmost.

class Pitfall11_TabOrder {
    func wrong(tabBar: UITabBarController, controllers: [UIViewController]) {
        // ❌ Same order in Arabic — "Home" tab ends up on the wrong (left) side.
        tabBar.viewControllers = controllers
    }
    func correct(tabBar: UITabBarController, controllers: [UIViewController]) {
        // ✅ Reverse the array for RTL so Home is on the right (leading) edge.
        tabBar.viewControllers = LocalizationManager.shared.isRTL
            ? controllers.reversed()
            : controllers
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// PITFALL 12: Arabic kerning and line height not adjusted
// ─────────────────────────────────────────────────────────────────────────────
//
// Arabic letters are connected — applying kerning (letter spacing) breaks them.
// Arabic also has marks above and below letters — default line height clips them.

class Pitfall12_ArabicTypography {
    func wrong(_ label: UILabel, text: String) {
        // ❌ System kerning breaks Arabic letter connections. Text looks broken.
        label.attributedText = NSAttributedString(string: text, attributes: [
            .kern: 2.0  // Never kern Arabic
        ])
    }
    func correct(_ label: UILabel, text: String) {
        // ✅ kern = 0, increased line height for Arabic diacritics.
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple   = 1.4
        paragraphStyle.baseWritingDirection = .rightToLeft
        paragraphStyle.alignment            = .right

        label.attributedText = NSAttributedString(string: text, attributes: [
            .kern:           0,    // No letter spacing for Arabic
            .paragraphStyle: paragraphStyle
        ])
    }
}
