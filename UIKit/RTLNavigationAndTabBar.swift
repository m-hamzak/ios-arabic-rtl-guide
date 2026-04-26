//
//  RTLNavigationAndTabBar.swift
//  ios-arabic-rtl-guide
//
//  Created by Hamza Khalid on 26/04/2026.
//

import UIKit

// MARK: - RTL Navigation & Tab Bar
//
// UINavigationController and UITabBarController both respect semanticContentAttribute,
// but require explicit setup — especially for runtime language switching.
//
// When the language changes at runtime:
//   - The back button chevron must flip (‹ ↔ ›)
//   - The push/pop animation slides from the correct direction
//   - The navigation bar title alignment must update
//   - Tab bar item order should reflect the new direction

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - UINavigationController + UINavigationBar
// ─────────────────────────────────────────────────────────────────────────────

class RTLNavigationController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        configureForCurrentLanguage()
        observeLanguageChanges()
    }

    func configureForCurrentLanguage() {
        let attribute = LocalizationManager.shared.layoutDirection

        // Nav bar direction — flips title position, back button side, and bar button order
        navigationBar.semanticContentAttribute = attribute

        // Update all existing view controllers in the stack
        viewControllers.forEach {
            $0.view.semanticContentAttribute = attribute
            $0.navigationItem.leftBarButtonItems?.forEach { $0.customView?.semanticContentAttribute = attribute }
            $0.navigationItem.rightBarButtonItems?.forEach { $0.customView?.semanticContentAttribute = attribute }
        }
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
        // Reload the nav bar to update back button direction
        navigationBar.setNeedsLayout()
        navigationBar.layoutIfNeeded()
    }

    deinit { NotificationCenter.default.removeObserver(self) }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - UIViewController — Navigation Item RTL Setup
// ─────────────────────────────────────────────────────────────────────────────
//
// In a standard UINavigationController, right bar button items appear on the right in LTR.
// In RTL, they appear on the left — which is still the "trailing" side.
// The semantic meaning (primary action) stays on the trailing side. Correct.
//
// If your bar buttons have custom views, you must set semanticContentAttribute on those too.

extension UIViewController {

    /// Applies RTL-aware navigation item setup.
    func configureNavigationItemForCurrentLanguage() {
        view.semanticContentAttribute = LocalizationManager.shared.layoutDirection

        // Custom left/right bar button views
        navigationItem.leftBarButtonItems?.forEach {
            $0.customView?.semanticContentAttribute = LocalizationManager.shared.layoutDirection
        }
        navigationItem.rightBarButtonItems?.forEach {
            $0.customView?.semanticContentAttribute = LocalizationManager.shared.layoutDirection
        }

        // Title view if custom
        navigationItem.titleView?.semanticContentAttribute = LocalizationManager.shared.layoutDirection
    }

    /// Creates a standard back button that works correctly in RTL.
    func makeRTLBackButton(action: Selector) -> UIBarButtonItem {
        let isRTL = LocalizationManager.shared.isRTL
        let imageName = isRTL ? "chevron.right" : "chevron.left"
        let image = UIImage(systemName: imageName)
        return UIBarButtonItem(image: image, style: .plain, target: self, action: action)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Push / Pop Transition Direction
// ─────────────────────────────────────────────────────────────────────────────
//
// UINavigationController push animation:
//   LTR: new screen slides in from the right
//   RTL: new screen slides in from the left
//
// This happens automatically when:
//   1. UINavigationBar.semanticContentAttribute is set
//   2. The view controller's view.semanticContentAttribute is set
//
// If the animation still goes the wrong way, use a custom transition:

class RTLPushTransition: NSObject, UIViewControllerAnimatedTransitioning {
    let isPresenting: Bool
    let direction: UIUserInterfaceLayoutDirection

    init(isPresenting: Bool) {
        self.isPresenting = isPresenting
        self.direction = LocalizationManager.shared.isRTL ? .rightToLeft : .leftToRight
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let toView = transitionContext.view(forKey: .to),
              let fromView = transitionContext.view(forKey: .from) else { return }

        let containerView = transitionContext.containerView
        let width = containerView.bounds.width

        // Direction-aware offset
        let offset: CGFloat
        if direction == .leftToRight {
            offset = isPresenting ? width : -width
        } else {
            offset = isPresenting ? -width : width
        }

        containerView.addSubview(toView)
        toView.transform = CGAffineTransform(translationX: offset, y: 0)

        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            animations: {
                toView.transform = .identity
                fromView.transform = CGAffineTransform(translationX: -offset, y: 0)
            },
            completion: { _ in
                fromView.transform = .identity
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        )
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - UITabBarController
// ─────────────────────────────────────────────────────────────────────────────
//
// Tab order: in RTL, the first tab should appear on the right.
// UITabBarController does NOT reverse tab order automatically.
// You must re-order viewControllers when the language is RTL.
//
// Design recommendation: design for LTR, reverse the array for RTL.
// The "home" tab is always on the leading edge (left in LTR, right in RTL).

class RTLTabBarController: UITabBarController {

    // Store original LTR order
    private var ltrViewControllers: [UIViewController] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        ltrViewControllers = viewControllers ?? []
        tabBar.semanticContentAttribute = LocalizationManager.shared.layoutDirection
        applyTabOrder()
        observeLanguageChanges()
    }

    func setLTRViewControllers(_ controllers: [UIViewController]) {
        ltrViewControllers = controllers
        applyTabOrder()
    }

    private func applyTabOrder() {
        tabBar.semanticContentAttribute = LocalizationManager.shared.layoutDirection
        if LocalizationManager.shared.isRTL {
            viewControllers = ltrViewControllers.reversed()
        } else {
            viewControllers = ltrViewControllers
        }
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
        applyTabOrder()
        tabBar.setNeedsLayout()
        tabBar.layoutIfNeeded()
    }

    deinit { NotificationCenter.default.removeObserver(self) }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - UISearchBar
// ─────────────────────────────────────────────────────────────────────────────

extension UISearchBar {

    func configureForCurrentLanguage() {
        semanticContentAttribute = LocalizationManager.shared.layoutDirection

        // The search icon position flips automatically with semanticContentAttribute.
        // In LTR: 🔍 appears on the left of the placeholder.
        // In RTL: 🔍 appears on the right of the placeholder.

        // Text field inside the search bar also needs direction
        if let textField = value(forKey: "searchField") as? UITextField {
            textField.textAlignment = .natural
            textField.semanticContentAttribute = LocalizationManager.shared.layoutDirection
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - UIToolbar
// ─────────────────────────────────────────────────────────────────────────────
//
// Toolbar items reverse order in RTL when semanticContentAttribute is set.
// The leftmost item in LTR becomes the rightmost in RTL — which is correct:
// the leading action stays on the leading edge.

extension UIToolbar {

    func configureForCurrentLanguage() {
        semanticContentAttribute = LocalizationManager.shared.layoutDirection
        items?.forEach { $0.customView?.semanticContentAttribute = LocalizationManager.shared.layoutDirection }
    }
}
