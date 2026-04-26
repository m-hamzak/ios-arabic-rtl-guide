//
//  RTLBasicViews.swift
//  ios-arabic-rtl-guide
//
//  Created by Hamza Khalid on 26/04/2026.
//

import UIKit

// MARK: - RTL Setup for Basic UIKit Views
//
// Covers UILabel, UIButton, UITextField, UITextView, UIImageView.
// Each section documents the correct approach and the common mistake.
//
// The pattern for every view:
//   1. Set semanticContentAttribute (controls child/subview layout direction)
//   2. Set textAlignment = .natural (not .left or .right)
//   3. Respond to .languageDidChange if the view is on a screen that supports runtime switching

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - UILabel
// ─────────────────────────────────────────────────────────────────────────────

extension UILabel {

    /// Applies RTL-correct alignment and direction.
    /// Call after creating any label that displays user-facing text.
    func configureForCurrentLanguage() {
        textAlignment = .natural
        semanticContentAttribute = LocalizationManager.shared.layoutDirection
    }

    /// Forces this label to always display LTR — for IBANs, account numbers, codes.
    func configureForcedLTR() {
        textAlignment = .left  // Absolute left, intentional for LTR-only content
        semanticContentAttribute = .forceLeftToRight
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - UIButton
// ─────────────────────────────────────────────────────────────────────────────
//
// UIButton has two direction-sensitive elements:
//   1. Title label alignment
//   2. Image (leading vs trailing position relative to title)

extension UIButton {

    /// Configures the button for the current language direction.
    func configureForCurrentLanguage() {
        semanticContentAttribute = LocalizationManager.shared.layoutDirection
        titleLabel?.textAlignment = .natural

        // Image position: in LTR, image is on the left of the title.
        // In RTL with semanticContentAttribute set, it flips to the right automatically.
        // For iOS 15+, use UIButton.Configuration for precise control.
    }
}

// UIButton.Configuration (iOS 15+) — precise RTL image control

@available(iOS 15.0, *)
func makeRTLAwareButton(title: String, image: UIImage?) -> UIButton {
    var config = UIButton.Configuration.filled()
    config.title = title
    config.image = image

    // imagePlacement: .leading means image appears on the leading side (left in LTR, right in RTL)
    config.imagePlacement = .leading
    config.imagePadding = 8

    let button = UIButton(configuration: config)
    button.semanticContentAttribute = LocalizationManager.shared.layoutDirection
    return button
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - UITextField
// ─────────────────────────────────────────────────────────────────────────────

class RTLTextField: UITextField {

    enum ContentKind {
        case name          // Follows app language
        case alphanumeric  // Always LTR (IBAN, account number)
        case numeric       // Always LTR (amount, phone)
        case password      // Always LTR (passwords are ASCII)
    }

    var contentKind: ContentKind = .name {
        didSet { applyDirection() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        applyDirection()
        observeLanguageChanges()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        applyDirection()
        observeLanguageChanges()
    }

    private func applyDirection() {
        switch contentKind {
        case .name:
            textAlignment           = .natural
            semanticContentAttribute = LocalizationManager.shared.layoutDirection
            keyboardType            = .default

        case .alphanumeric:
            textAlignment           = .left      // Absolute — always LTR
            semanticContentAttribute = .forceLeftToRight
            keyboardType            = .asciiCapable
            autocorrectionType      = .no
            autocapitalizationType  = .allCharacters

        case .numeric:
            textAlignment           = .left
            semanticContentAttribute = .forceLeftToRight
            keyboardType            = .decimalPad

        case .password:
            textAlignment           = .left
            semanticContentAttribute = .forceLeftToRight
            isSecureTextEntry       = true
            keyboardType            = .default
        }
    }

    // MARK: - Placeholder Direction
    //
    // UITextField's placeholder uses the same textAlignment.
    // For Arabic placeholders in a .natural-aligned field, this is correct automatically.
    // For LTR-forced fields showing Arabic placeholder text, you need NSAttributedString.

    func setArabicPlaceholder(_ text: String, for ltrField: Bool = false) {
        if ltrField {
            // Force RTL just for the placeholder paragraph style
            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .right
            paragraph.baseWritingDirection = .rightToLeft
            attributedPlaceholder = NSAttributedString(
                string: text,
                attributes: [
                    .paragraphStyle: paragraph,
                    .foregroundColor: UIColor.placeholderText
                ]
            )
        } else {
            placeholder = text
        }
    }

    // MARK: - Language Change Observer

    private func observeLanguageChanges() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(languageDidChange),
            name: .languageDidChange,
            object: nil
        )
    }

    @objc private func languageDidChange() {
        applyDirection()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - UITextView
// ─────────────────────────────────────────────────────────────────────────────
//
// UITextView has an additional consideration: writing direction for typed text.
// In RTL, the cursor starts on the right and text flows right-to-left.
// The defaultTextAttributes must include the writing direction.

class RTLTextView: UITextView {

    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        configureForCurrentLanguage()
        observeLanguageChanges()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureForCurrentLanguage()
        observeLanguageChanges()
    }

    func configureForCurrentLanguage() {
        let isRTL = LocalizationManager.shared.isRTL
        semanticContentAttribute = LocalizationManager.shared.layoutDirection
        textAlignment = .natural

        // Set writing direction so cursor appears on correct side
        let writingDirection: NSWritingDirection = isRTL ? .rightToLeft : .leftToRight
        defaultTextAttributes[.writingDirection] = [writingDirection.rawValue | NSWritingDirectionFormatType.override.rawValue]

        // Paragraph style for default text
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = isRTL ? .right : .left
        paragraphStyle.baseWritingDirection = writingDirection
        typingAttributes[.paragraphStyle] = paragraphStyle
    }

    private func observeLanguageChanges() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(languageDidChange),
            name: .languageDidChange,
            object: nil
        )
    }

    @objc private func languageDidChange() {
        configureForCurrentLanguage()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - UIImageView
// ─────────────────────────────────────────────────────────────────────────────

extension UIImageView {

    /// Configures image flipping based on whether the image is directional.
    /// - Parameter isDirectional: True for arrows, chevrons, back buttons. False for logos, flags.
    func configureRTLFlipping(isDirectional: Bool) {
        if isDirectional {
            // Flip the image transform in RTL
            if LocalizationManager.shared.isRTL {
                transform = CGAffineTransform(scaleX: -1, y: 1)
            } else {
                transform = .identity
            }
        } else {
            // Never flip: logos, avatars, flags, decorative images
            transform = .identity
        }
    }

    /// Updates the flip when the language changes.
    func observeRTLFlipping(isDirectional: Bool) {
        NotificationCenter.default.addObserver(
            forName: .languageDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.configureRTLFlipping(isDirectional: isDirectional)
        }
        configureRTLFlipping(isDirectional: isDirectional)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - UIView Base Extension (applies to all views)
// ─────────────────────────────────────────────────────────────────────────────

extension UIView {

    /// Applies the current language direction to this view and all its subviews recursively.
    func applyCurrentLanguageDirection() {
        semanticContentAttribute = LocalizationManager.shared.layoutDirection
        subviews.forEach { $0.applyCurrentLanguageDirection() }
    }

    /// Convenience: force LTR on this view regardless of app language.
    /// Use for IBAN displays, account number labels, amount fields.
    func forceLTR() {
        semanticContentAttribute = .forceLeftToRight
    }

    /// Convenience: force RTL on this view regardless of app language.
    func forceRTL() {
        semanticContentAttribute = .forceRightToLeft
    }

    /// Registers for language change and re-applies direction automatically.
    func autoApplyLanguageDirection() {
        applyCurrentLanguageDirection()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleLanguageChange),
            name: .languageDidChange,
            object: nil
        )
    }

    @objc private func handleLanguageChange() {
        applyCurrentLanguageDirection()
        setNeedsLayout()
        layoutIfNeeded()
    }
}
