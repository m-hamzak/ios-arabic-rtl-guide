//
//  RTLTextAttributes.swift
//  ios-arabic-rtl-guide
//
//  Created by Hamza Khalid on 26/04/2026.
//

import UIKit

// MARK: - RTL Text Attributes & NSAttributedString
//
// NSAttributedString gives you full control over text direction, paragraph style,
// and writing direction — essential for mixed Arabic/English content in banking
// and government apps (statements, form summaries, contracts).
//
// Key attributes:
//   - .paragraphStyle with .baseWritingDirection
//   - .writingDirection (inline override)
//   - .textAlignment (.natural, .right, .left)

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - 1. Basic RTL Attributed String
// ─────────────────────────────────────────────────────────────────────────────

extension NSAttributedString {

    /// Creates an attributed string with the correct paragraph style for the current language.
    static func forCurrentLanguage(
        _ text: String,
        font: UIFont = .systemFont(ofSize: 16),
        color: UIColor = .label
    ) -> NSAttributedString {
        let isRTL = LocalizationManager.shared.isRTL

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment             = isRTL ? .right : .left
        paragraphStyle.baseWritingDirection  = isRTL ? .rightToLeft : .leftToRight

        return NSAttributedString(string: text, attributes: [
            .font:           font,
            .foregroundColor: color,
            .paragraphStyle: paragraphStyle
        ])
    }

    /// Creates an Arabic-forced attributed string — for Arabic text inside LTR screens.
    static func arabic(
        _ text: String,
        font: UIFont = .systemFont(ofSize: 16),
        color: UIColor = .label
    ) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment            = .right
        paragraphStyle.baseWritingDirection = .rightToLeft

        return NSAttributedString(string: text, attributes: [
            .font:            font,
            .foregroundColor: color,
            .paragraphStyle:  paragraphStyle,
            .writingDirection: [NSWritingDirection.rightToLeft.rawValue | NSWritingDirectionFormatType.override.rawValue]
        ])
    }

    /// Creates a forced LTR attributed string — for IBANs, account numbers, codes in RTL screens.
    static func ltrOnly(
        _ text: String,
        font: UIFont = .systemFont(ofSize: 16),
        color: UIColor = .label
    ) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment            = .left
        paragraphStyle.baseWritingDirection = .leftToRight

        return NSAttributedString(string: text, attributes: [
            .font:            font,
            .foregroundColor: color,
            .paragraphStyle:  paragraphStyle,
            .writingDirection: [NSWritingDirection.leftToRight.rawValue | NSWritingDirectionFormatType.override.rawValue]
        ])
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - 2. Mixed Arabic + English Content (Bidirectional)
// ─────────────────────────────────────────────────────────────────────────────
//
// A common pattern in banking statements:
//   Arabic label: "رقم الحساب"
//   English value: "BHD 1,200.000"
//
// Both appear in the same text block — the label is RTL, the value is LTR.
// Use .writingDirection inline override to switch mid-string.

class BidirectionalLabel: UILabel {

    /// Displays Arabic label text and an LTR value (e.g. an account number or amount) inline.
    func setBidirectionalContent(arabicLabel: String, ltrValue: String) {
        let result = NSMutableAttributedString()

        // Arabic label part
        let arabicParagraph = NSMutableParagraphStyle()
        arabicParagraph.baseWritingDirection = .rightToLeft
        arabicParagraph.alignment            = .right

        let arabicPart = NSAttributedString(
            string: arabicLabel + ": ",
            attributes: [
                .font:            UIFont.systemFont(ofSize: 16),
                .foregroundColor: UIColor.secondaryLabel,
                .paragraphStyle:  arabicParagraph,
                .writingDirection: [NSWritingDirection.rightToLeft.rawValue | NSWritingDirectionFormatType.override.rawValue]
            ]
        )

        // LTR value part — forced left-to-right
        let ltrPart = NSAttributedString(
            string: ltrValue,
            attributes: [
                .font:            UIFont.systemFont(ofSize: 16, weight: .semibold),
                .foregroundColor: UIColor.label,
                .writingDirection: [NSWritingDirection.leftToRight.rawValue | NSWritingDirectionFormatType.override.rawValue]
            ]
        )

        result.append(arabicPart)
        result.append(ltrPart)

        attributedText = result
        textAlignment = .natural
        semanticContentAttribute = .forceRightToLeft
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - 3. NSMutableParagraphStyle Helpers
// ─────────────────────────────────────────────────────────────────────────────

extension NSMutableParagraphStyle {

    static func rtl(alignment: NSTextAlignment = .right) -> NSMutableParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.alignment            = alignment
        style.baseWritingDirection = .rightToLeft
        return style
    }

    static func ltr(alignment: NSTextAlignment = .left) -> NSMutableParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.alignment            = alignment
        style.baseWritingDirection = .leftToRight
        return style
    }

    static func natural() -> NSMutableParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.alignment            = .natural
        style.baseWritingDirection = LocalizationManager.shared.isRTL ? .rightToLeft : .leftToRight
        return style
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - 4. UITextView Writing Direction (typing direction)
// ─────────────────────────────────────────────────────────────────────────────
//
// When a user starts typing in a UITextView, the cursor position and text
// direction are set by defaultTextAttributes and typingAttributes.
// If not set correctly, typing starts from the wrong side.

extension UITextView {

    func configureTypingDirectionForCurrentLanguage() {
        let isRTL = LocalizationManager.shared.isRTL
        let writingDirection: NSWritingDirection = isRTL ? .rightToLeft : .leftToRight

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment            = isRTL ? .right : .left
        paragraphStyle.baseWritingDirection = writingDirection

        defaultTextAttributes = [
            .paragraphStyle:  paragraphStyle,
            .font:            font ?? .systemFont(ofSize: 16),
            .foregroundColor: textColor ?? .label,
            .writingDirection: [writingDirection.rawValue | NSWritingDirectionFormatType.override.rawValue]
        ]

        typingAttributes = defaultTextAttributes

        textAlignment = .natural
        semanticContentAttribute = LocalizationManager.shared.layoutDirection
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - 5. Arabic Number Formatting in Attributed Strings
// ─────────────────────────────────────────────────────────────────────────────
//
// When displaying numbers inline with Arabic text, you may want Eastern Arabic numerals.
// Apply forced LTR override to keep financial values readable regardless.

extension NSAttributedString {

    /// Wraps a number string with LTR isolation so it doesn't get reordered by the bidi algorithm.
    /// Use for amounts, account numbers, and dates inside Arabic paragraphs.
    static func isolatedLTR(_ text: String, font: UIFont = .systemFont(ofSize: 16)) -> NSAttributedString {
        // Unicode LTR isolate characters: U+2066 (start) and U+2069 (end)
        // These are invisible characters that isolate a run of LTR text inside RTL content.
        let isolated = "\u{2066}\(text)\u{2069}"
        return NSAttributedString(string: isolated, attributes: [.font: font])
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - 6. Kerning & Line Spacing for Arabic
// ─────────────────────────────────────────────────────────────────────────────
//
// Arabic text typically needs more line spacing due to the descenders and
// marks above/below letters. Kerning should be 0 — Arabic letters connect
// and arbitrary kerning breaks them apart.

extension NSMutableParagraphStyle {

    static func arabicBody(lineSpacingMultiplier: CGFloat = 1.4) -> NSMutableParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.baseWritingDirection = .rightToLeft
        style.alignment            = .right
        style.lineHeightMultiple   = lineSpacingMultiplier  // More breathing room for Arabic
        return style
    }
}

extension NSAttributedString {

    static func arabicBody(_ text: String, fontSize: CGFloat = 16) -> NSAttributedString {
        NSAttributedString(string: text, attributes: [
            .font:           UIFont.systemFont(ofSize: fontSize),
            .paragraphStyle: NSMutableParagraphStyle.arabicBody(),
            .kern:           0  // Never kern Arabic — it breaks letter connections
        ])
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - 7. Contract / Statement Text (Long-form Arabic content)
// ─────────────────────────────────────────────────────────────────────────────
//
// Government apps and banking T&C screens display long Arabic text.
// Use NSTextStorage / TextKit for best results with justified Arabic text.

class ArabicStatementView: UITextView {

    func loadStatement(_ text: String) {
        let isRTL = LocalizationManager.shared.isRTL

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment            = isRTL ? .right : .left
        paragraphStyle.baseWritingDirection = isRTL ? .rightToLeft : .leftToRight
        paragraphStyle.lineHeightMultiple   = 1.4
        paragraphStyle.hyphenationFactor    = 0  // Arabic doesn't use hyphens

        attributedText = NSAttributedString(string: text, attributes: [
            .font:            UIFont.systemFont(ofSize: 15),
            .foregroundColor: UIColor.label,
            .paragraphStyle:  paragraphStyle,
            .kern:            0
        ])

        textAlignment           = .natural
        semanticContentAttribute = LocalizationManager.shared.layoutDirection
        isEditable               = false
        isScrollEnabled          = true
        textContainerInset       = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
    }
}
