//
//  RTLLayoutHelper.swift
//  ios-arabic-rtl-guide
//
//  Created by Hamza Khalid on 26/04/2026.
//

import UIKit

// MARK: - RTL in UIKit
//
// UIKit does not flip layouts automatically based on device language — it requires
// explicit setup. These patterns cover the three main areas:
//   1. View-level direction (semanticContentAttribute)
//   2. Text alignment (natural vs hardcoded)
//   3. Auto Layout with leading/trailing constraints (not left/right)
//
// All of these were real requirements across GCC banking apps and Arabic
// government document portals in Qatar.

// MARK: - 1. Setting Layout Direction on Individual Views

extension UIView {

    /// Forces this view and all its subviews to display RTL.
    /// Use when you need a specific section of a screen to be RTL
    /// regardless of the system language.
    func forceRTL() {
        semanticContentAttribute = .forceRightToLeft
    }

    /// Forces this view to display LTR — useful for English-only content
    /// (e.g. account numbers, IBAN) inside an otherwise RTL screen.
    func forceLTR() {
        semanticContentAttribute = .forceLeftToRight
    }

    /// Applies RTL or LTR based on the current app language.
    func applyCurrentDirection() {
        semanticContentAttribute = LocalizationManager.shared.layoutDirection
    }
}

// MARK: - 2. UILabel — Natural vs Hardcoded Alignment
//
// Always use .natural — it maps to .right in RTL and .left in LTR.
// Never hardcode .left or .right for body text in a bilingual app.

extension UILabel {

    /// Sets text alignment to .natural — direction-aware, always correct.
    func applyNaturalAlignment() {
        textAlignment = .natural
    }
}

// MARK: - 3. UITextField — RTL Input Behaviour

extension UITextField {

    func configureForCurrentLanguage() {
        // Natural alignment: cursor and text start from the correct side
        textAlignment = .natural

        // Semantic content: flips the clear button and left/right view
        semanticContentAttribute = LocalizationManager.shared.layoutDirection

        // Correct keyboard type for Arabic input — shows Arabic keyboard by default
        if LocalizationManager.shared.isRTL {
            keyboardType = .default  // Arabic keyboard appears automatically on Arabic locale
        }
    }
}

// MARK: - 4. Auto Layout — Leading/Trailing vs Left/Right
//
// Always use leadingAnchor / trailingAnchor in RTL-aware apps.
// leftAnchor / rightAnchor are absolute — they never flip.
// leadingAnchor = left in LTR, right in RTL.

final class RTLAwareCardView: UIView {

    private let iconView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .systemBlue
        return iv
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textAlignment = .natural  // Direction-aware
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 13)
        label.textColor = .secondaryLabel
        label.textAlignment = .natural
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayout()
    }

    private func setupLayout() {
        addSubview(iconView)
        addSubview(titleLabel)
        addSubview(subtitleLabel)

        // Using leadingAnchor / trailingAnchor — flips automatically in RTL
        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 40),
            iconView.heightAnchor.constraint(equalToConstant: 40),

            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 12),

            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12)
        ])

        // Apply direction to the container — subviews inherit it
        applyCurrentDirection()
    }

    func configure(icon: UIImage?, title: String, subtitle: String) {
        iconView.image = icon
        titleLabel.text = title
        subtitleLabel.text = subtitle
    }
}

// MARK: - 5. UITableViewCell — RTL-Aware Cell

final class RTLTableViewCell: UITableViewCell {

    static let reuseIdentifier = "RTLTableViewCell"

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        applyRTLSetup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        applyRTLSetup()
    }

    private func applyRTLSetup() {
        // Flip the accessory arrow in RTL (chevron.right becomes chevron.left)
        semanticContentAttribute = LocalizationManager.shared.layoutDirection

        // Text labels use natural alignment
        textLabel?.textAlignment = .natural
        detailTextLabel?.textAlignment = .natural
    }
}

// MARK: - 6. UINavigationController — RTL Back Button and Title

extension UINavigationController {

    /// Call once during setup to apply RTL-aware navigation bar configuration.
    func configureForCurrentLanguage() {
        navigationBar.semanticContentAttribute = LocalizationManager.shared.layoutDirection

        // Back button title and chevron flip automatically when semanticContentAttribute is set
        // The back chevron (‹ or ›) swaps direction — no additional code needed
    }
}

// MARK: - 7. Responding to Language Changes in a UIViewController
//
// Observe .languageDidChange and re-apply direction to views that were
// already on screen when the language changed.

class RTLAwareViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(languageDidChange(_:)),
            name: .languageDidChange,
            object: nil
        )
        applyDirection()
    }

    @objc private func languageDidChange(_ notification: Notification) {
        applyDirection()
        // Force a layout pass — required for views with manual frame calculations
        view.setNeedsLayout()
        view.layoutIfNeeded()
    }

    private func applyDirection() {
        view.semanticContentAttribute = LocalizationManager.shared.layoutDirection
        // Walk subviews and apply direction where needed
        view.subviews.forEach { $0.applyCurrentDirection() }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
