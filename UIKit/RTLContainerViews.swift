//
//  RTLContainerViews.swift
//  ios-arabic-rtl-guide
//
//  Created by Hamza Khalid on 26/04/2026.
//

import UIKit

// MARK: - RTL Setup for Container Views
//
// Covers UIStackView, UITableView, UICollectionView, UIScrollView.
// Containers are where most RTL bugs appear — they control child layout order.

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - UIStackView
// ─────────────────────────────────────────────────────────────────────────────
//
// UIStackView reverses horizontal item order in RTL automatically —
// BUT only if semanticContentAttribute is set on the stack itself.
// The stack does NOT inherit the attribute from its superview automatically.

extension UIStackView {

    /// Configures the stack and all arranged subviews for the current language.
    func configureForCurrentLanguage() {
        semanticContentAttribute = LocalizationManager.shared.layoutDirection
        arrangedSubviews.forEach {
            $0.semanticContentAttribute = LocalizationManager.shared.layoutDirection
        }
    }
}

// RTL-Aware Stack Factory

func makeHorizontalStack(
    arrangedSubviews: [UIView],
    spacing: CGFloat = 8,
    alignment: UIStackView.Alignment = .center
) -> UIStackView {
    let stack = UIStackView(arrangedSubviews: arrangedSubviews)
    stack.axis      = .horizontal
    stack.spacing   = spacing
    stack.alignment = alignment
    // Critical: set on the stack so item order reverses in RTL
    stack.semanticContentAttribute = LocalizationManager.shared.layoutDirection
    return stack
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - UITableView + UITableViewCell
// ─────────────────────────────────────────────────────────────────────────────

class RTLTableView: UITableView {

    override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
        configureForCurrentLanguage()
        observeLanguageChanges()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureForCurrentLanguage()
        observeLanguageChanges()
    }

    func configureForCurrentLanguage() {
        semanticContentAttribute = LocalizationManager.shared.layoutDirection
    }

    private func observeLanguageChanges() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(languageChanged),
            name: .languageDidChange,
            object: nil
        )
    }

    @objc private func languageChanged() {
        configureForCurrentLanguage()
        // Reload to re-render cells with updated direction
        reloadData()
    }

    deinit { NotificationCenter.default.removeObserver(self) }
}

// RTL-Aware Table Cell

class RTLTableViewCell: UITableViewCell {

    static let reuseIdentifier = "RTLTableViewCell"

    // MARK: - Swipe Actions Direction
    //
    // In LTR: destructive actions appear on the trailing (right) edge
    // In RTL: trailing = left edge — same conceptual position, iOS handles this
    // You define swipe actions by edge (.leading / .trailing) — they flip automatically.
    // See: tableView(_:leadingSwipeActionsConfigurationForRowAt:)
    //      tableView(_:trailingSwipeActionsConfigurationForRowAt:)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureForCurrentLanguage()
        observeLanguageChanges()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureForCurrentLanguage()
        observeLanguageChanges()
    }

    func configureForCurrentLanguage() {
        semanticContentAttribute    = LocalizationManager.shared.layoutDirection
        textLabel?.textAlignment    = .natural
        detailTextLabel?.textAlignment = .natural
        // Accessory: chevron.right flips to chevron.left in RTL automatically
    }

    private func observeLanguageChanges() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(languageChanged),
            name: .languageDidChange,
            object: nil
        )
    }

    @objc private func languageChanged() {
        configureForCurrentLanguage()
    }

    deinit { NotificationCenter.default.removeObserver(self) }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - UICollectionView + UICollectionViewFlowLayout
// ─────────────────────────────────────────────────────────────────────────────
//
// UICollectionViewFlowLayout does NOT automatically reverse scroll direction in RTL.
// You must subclass the layout and override the item ordering.

class RTLFlowLayout: UICollectionViewFlowLayout {

    override var flipsHorizontallyInOppositeLayoutDirection: Bool {
        return true  // Tells the collection view to flip item positions in RTL
    }

    override var developmentLayoutDirection: UIUserInterfaceLayoutDirection {
        return .leftToRight  // Your design was done in LTR — let the system flip it
    }
}

// RTL-Aware Collection View

class RTLCollectionView: UICollectionView {

    init(frame: CGRect) {
        let layout = RTLFlowLayout()
        layout.scrollDirection = .horizontal
        super.init(frame: frame, collectionViewLayout: layout)
        semanticContentAttribute = LocalizationManager.shared.layoutDirection
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        semanticContentAttribute = LocalizationManager.shared.layoutDirection
    }
}

// RTL-Aware Collection Cell

class RTLCollectionViewCell: UICollectionViewCell {

    static let reuseIdentifier = "RTLCollectionViewCell"

    override init(frame: CGRect) {
        super.init(frame: frame)
        semanticContentAttribute = LocalizationManager.shared.layoutDirection
        contentView.semanticContentAttribute = LocalizationManager.shared.layoutDirection
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        semanticContentAttribute = LocalizationManager.shared.layoutDirection
        contentView.semanticContentAttribute = LocalizationManager.shared.layoutDirection
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - UIScrollView — Horizontal Scroll Direction
// ─────────────────────────────────────────────────────────────────────────────
//
// Horizontal scroll views: content should start from the leading edge.
// In LTR: start at x=0 (left edge).
// In RTL: start at contentSize.width - bounds.width (right edge).

class RTLHorizontalScrollView: UIScrollView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        semanticContentAttribute = LocalizationManager.shared.layoutDirection
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        semanticContentAttribute = LocalizationManager.shared.layoutDirection
    }

    /// Call after setting contentSize to scroll to the leading edge in the current language.
    func scrollToLeadingEdge(animated: Bool = false) {
        if LocalizationManager.shared.isRTL {
            let maxOffsetX = contentSize.width - bounds.width
            setContentOffset(CGPoint(x: max(maxOffsetX, 0), y: 0), animated: animated)
        } else {
            setContentOffset(.zero, animated: animated)
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Auto Layout — Leading/Trailing vs Left/Right
// ─────────────────────────────────────────────────────────────────────────────
//
// Summary of correct anchors:
//
//   ✅ Use: leadingAnchor, trailingAnchor   → flip in RTL
//   ❌ Avoid: leftAnchor, rightAnchor       → absolute, never flip
//
//   ✅ Use: NSDirectionalEdgeInsets         → leading/trailing flip
//   ❌ Avoid: UIEdgeInsets                  → left/right are absolute
//
//   ✅ Use: directionalLayoutMargins        → flips
//   ❌ Avoid: layoutMargins                 → does not flip

class RTLConstrainedView: UIView {

    private let iconView    = UIImageView()
    private let titleLabel  = UILabel()
    private let valueLabel  = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayout()
    }

    private func setupLayout() {
        [iconView, titleLabel, valueLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        titleLabel.textAlignment = .natural
        valueLabel.textAlignment = .natural

        NSLayoutConstraint.activate([
            // ✅ leadingAnchor — flips to right side in RTL
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 36),
            iconView.heightAnchor.constraint(equalToConstant: 36),

            // ✅ leadingAnchor of next view relative to trailing of icon
            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            // ✅ trailingAnchor — flips to left side in RTL
            valueLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            valueLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])

        // ✅ NSDirectionalEdgeInsets for padding
        directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 12, leading: 16, bottom: 12, trailing: 16
        )
    }
}
