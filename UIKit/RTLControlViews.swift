//
//  RTLControlViews.swift
//  ios-arabic-rtl-guide
//
//  Created by Hamza Khalid on 26/04/2026.
//

import UIKit

// MARK: - RTL Setup for UIKit Control Views
//
// Covers: UISlider, UISegmentedControl, UIProgressView, UIPageControl,
//         UIDatePicker, UISwitch, UIStepper, UIPickerView.
//
// Controls are the trickiest category — each one has unique RTL behaviour.
// Some flip automatically, some need explicit transforms, some have no flip behaviour at all.

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - UISlider
// ─────────────────────────────────────────────────────────────────────────────
//
// UISlider does NOT flip automatically in RTL.
// In Arabic: a slider representing a value from min (right) to max (left) requires
// a horizontal flip via transform.

extension UISlider {

    /// Flips the slider horizontally in RTL so the track fills from the correct edge.
    func configureForCurrentLanguage() {
        if LocalizationManager.shared.isRTL {
            transform = CGAffineTransform(scaleX: -1, y: 1)
            // Note: value callbacks still work correctly after the transform flip.
            // Thumb moves right-to-left as value increases — correct for Arabic UX.
        } else {
            transform = .identity
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - UISegmentedControl
// ─────────────────────────────────────────────────────────────────────────────
//
// UISegmentedControl reverses segment order in RTL when semanticContentAttribute is set.
// Segment 0 (index 0) appears on the right in RTL.
// This means your first segment is always on the leading edge — correct behaviour.

extension UISegmentedControl {

    func configureForCurrentLanguage() {
        semanticContentAttribute = LocalizationManager.shared.layoutDirection
        // Segment titles use .natural alignment automatically
    }
}

// If you need the segment order to remain the same visually (not flip):

extension UISegmentedControl {

    func configureFixedOrderForCurrentLanguage() {
        // Do NOT set semanticContentAttribute if you want the order unchanged.
        // Use this for language selectors (English | العربية) where order is intentional.
        semanticContentAttribute = .unspecified
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - UIProgressView
// ─────────────────────────────────────────────────────────────────────────────
//
// UIProgressView fills left-to-right always. It does NOT flip automatically.
// In RTL, a progress bar filling from right to left requires a horizontal flip.

extension UIProgressView {

    func configureForCurrentLanguage() {
        if LocalizationManager.shared.isRTL {
            transform = CGAffineTransform(scaleX: -1, y: 1)
        } else {
            transform = .identity
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - UIPageControl
// ─────────────────────────────────────────────────────────────────────────────
//
// UIPageControl dot order does NOT flip in RTL automatically.
// The current page indicator (the filled dot) stays left-aligned.
// For RTL, you need to flip it so dot 0 is on the right.

extension UIPageControl {

    func configureForCurrentLanguage() {
        if LocalizationManager.shared.isRTL {
            transform = CGAffineTransform(scaleX: -1, y: 1)
            // After flip: dot 0 is on the right, current page moves left as pages advance
        } else {
            transform = .identity
        }

        // Ensure the page number reported by currentPage still maps to the correct
        // visual position — no change needed, the transform handles the visuals.
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - UIDatePicker
// ─────────────────────────────────────────────────────────────────────────────
//
// UIDatePicker respects the locale — setting the locale to "ar" displays
// Arabic month names and right-to-left ordering automatically.
// No additional setup needed beyond locale.

extension UIDatePicker {

    func configureForCurrentLanguage() {
        locale = LocalizationManager.shared.currentLanguage.locale
        semanticContentAttribute = LocalizationManager.shared.layoutDirection

        // For Arabic locale, the picker automatically shows:
        // - Arabic month names: يناير، فبراير، مارس...
        // - Day/Month/Year in GCC date order
        // - Arabic numerals if locale is "ar" (device setting dependent)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - UISwitch
// ─────────────────────────────────────────────────────────────────────────────
//
// UISwitch does NOT flip in RTL — ON is always on the right, OFF on the left.
// This is intentional: the on/off semantic is universal.
// However, the switch's POSITION in its container (leading/trailing edge) should flip.

extension UISwitch {

    func configureForCurrentLanguage() {
        // UISwitch itself: no flip needed
        // Ensure its container (UIStackView / layout) handles the position
        semanticContentAttribute = .unspecified  // Let container decide position
    }
}

// Example: Switch in a settings row

class SettingsToggleCell: UITableViewCell {

    private let titleLabel = UILabel()
    private let toggle = UISwitch()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        // Stack: [label] [spacer] [switch]
        // In RTL: [switch] [spacer] [label] — switch ends up on the left (trailing edge)
        let stack = UIStackView(arrangedSubviews: [titleLabel, UIView(), toggle])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.semanticContentAttribute = LocalizationManager.shared.layoutDirection
        contentView.addSubview(stack)

        titleLabel.textAlignment = .natural

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - UIStepper
// ─────────────────────────────────────────────────────────────────────────────
//
// UIStepper has + and − buttons. In RTL, the + (increment) button should be
// on the left side (leading edge in RTL). Apply a horizontal flip.

extension UIStepper {

    func configureForCurrentLanguage() {
        if LocalizationManager.shared.isRTL {
            // Flip so + is on the right (leading) and − is on the left (trailing) in RTL
            // After flip: + appears on the leading (right) edge in RTL — correct for Arabic
            transform = CGAffineTransform(scaleX: -1, y: 1)
        } else {
            transform = .identity
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - UIPickerView
// ─────────────────────────────────────────────────────────────────────────────
//
// UIPickerView displays column content — the text alignment in cells must be .natural.
// For multi-column pickers (e.g. day | month | year), column order may need to reverse.

extension UIPickerView {

    func configureForCurrentLanguage() {
        semanticContentAttribute = LocalizationManager.shared.layoutDirection
    }
}

// RTL-aware picker view delegate helper for date components

class RTLDatePickerView: UIPickerView, UIPickerViewDataSource, UIPickerViewDelegate {

    private let isRTL = LocalizationManager.shared.isRTL

    // Columns in LTR: Day | Month | Year
    // Columns in RTL: Year | Month | Day (reversed)
    private var ltrComponents = ["Day", "Month", "Year"]

    var components: [String] {
        isRTL ? ltrComponents.reversed() : ltrComponents
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        dataSource = self
        delegate = self
        semanticContentAttribute = LocalizationManager.shared.layoutDirection
    }

    required init?(coder: NSCoder) { fatalError() }

    func numberOfComponents(in pickerView: UIPickerView) -> Int { 3 }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int { 30 }

    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label = (view as? UILabel) ?? UILabel()
        label.text = "\(row + 1)"
        label.textAlignment = .center  // Centered in picker — no direction concern
        return label
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - RTLControlsViewController — Summary Example
// ─────────────────────────────────────────────────────────────────────────────
//
// A view controller that wires all controls together and
// responds correctly to runtime language changes.

class RTLControlsViewController: UIViewController {

    private let slider       = UISlider()
    private let segmented    = UISegmentedControl(items: ["Arabic", "English"])
    private let progress     = UIProgressView(progressViewStyle: .default)
    private let pageControl  = UIPageControl()

    override func viewDidLoad() {
        super.viewDidLoad()
        configureAllControls()
        observeLanguageChanges()
    }

    private func configureAllControls() {
        slider.configureForCurrentLanguage()
        segmented.configureForCurrentLanguage()
        progress.configureForCurrentLanguage()
        pageControl.configureForCurrentLanguage()
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
        UIView.animate(withDuration: 0.3) {
            self.configureAllControls()
        }
    }

    deinit { NotificationCenter.default.removeObserver(self) }
}
