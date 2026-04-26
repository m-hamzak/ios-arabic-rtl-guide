//
//  RTLAnimations.swift
//  ios-arabic-rtl-guide
//
//  Created by Hamza Khalid on 26/04/2026.
//

import SwiftUI

// MARK: - RTL-Aware Animations & Transitions
//
// SwiftUI transitions have hardcoded directions by default.
// .slide always slides from the left edge regardless of layout direction.
// For RTL apps, slides, pushes, and reveals must come from the correct side.
//
// This file provides direction-aware transition helpers.

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - 1. Direction-Aware Slide Transition
// ─────────────────────────────────────────────────────────────────────────────

extension AnyTransition {

    /// Slides in from the trailing edge — correct for push navigation in both LTR and RTL.
    /// In LTR: slides from the right. In RTL: slides from the left.
    static func slideFromTrailing(direction: LayoutDirection) -> AnyTransition {
        let insertionEdge: Edge = direction == .rightToLeft ? .leading : .trailing
        let removalEdge: Edge   = direction == .rightToLeft ? .trailing : .leading

        return .asymmetric(
            insertion: .move(edge: insertionEdge),
            removal:   .move(edge: removalEdge)
        )
    }

    /// Slides in from the leading edge — correct for back navigation / dismiss.
    /// In LTR: slides from the left. In RTL: slides from the right.
    static func slideFromLeading(direction: LayoutDirection) -> AnyTransition {
        let insertionEdge: Edge = direction == .rightToLeft ? .trailing : .leading
        let removalEdge: Edge   = direction == .rightToLeft ? .leading : .trailing

        return .asymmetric(
            insertion: .move(edge: insertionEdge),
            removal:   .move(edge: removalEdge)
        )
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - 2. RTLSlideModifier — View Modifier for Directional Slides
// ─────────────────────────────────────────────────────────────────────────────

struct RTLSlideTransitionView: View {
    @State private var showDetail = false
    @Environment(\.layoutDirection) var direction

    var body: some View {
        ZStack {
            if !showDetail {
                mainView
                    .transition(.slideFromTrailing(direction: direction))
            } else {
                detailView
                    .transition(.slideFromTrailing(direction: direction))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showDetail)
    }

    var mainView: some View {
        Button("Open Detail") { showDetail = true }
    }

    var detailView: some View {
        VStack {
            Text("Detail View")
            Button("Back") { showDetail = false }
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - 3. Drawer / Side Panel — Direction-Aware
// ─────────────────────────────────────────────────────────────────────────────
//
// Side drawers open from the leading edge (left in LTR, right in RTL).

struct RTLDrawerExample: View {
    @State private var isDrawerOpen = false
    @Environment(\.layoutDirection) var direction

    var body: some View {
        ZStack(alignment: direction == .rightToLeft ? .trailing : .leading) {
            // Main content
            Color(.systemBackground)
                .overlay(
                    Button(direction == .rightToLeft ? "☰" : "☰") {
                        withAnimation(.spring()) { isDrawerOpen.toggle() }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding()
                )

            // Drawer panel — slides from leading edge
            if isDrawerOpen {
                HStack(spacing: 0) {
                    if direction == .leftToRight {
                        drawerContent
                        Spacer()
                    } else {
                        Spacer()
                        drawerContent
                    }
                }
                .transition(
                    .move(edge: direction == .rightToLeft ? .trailing : .leading)
                )
            }
        }
        .ignoresSafeArea()
        .onTapGesture {
            if isDrawerOpen { withAnimation { isDrawerOpen = false } }
        }
    }

    var drawerContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Menu")
                .font(.title2.bold())
                .padding(.top, 60)
            Text("Home")
            Text("Accounts")
            Text("Settings")
            Spacer()
        }
        .frame(width: 260)
        .padding(.horizontal)
        .background(Color(.secondarySystemBackground))
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - 4. Page / Onboarding Transition
// ─────────────────────────────────────────────────────────────────────────────
//
// Onboarding flows: "Next" moves forward (trailing direction).
// In LTR: next page comes from the right.
// In RTL: next page comes from the left.

struct OnboardingFlow: View {
    @State private var currentPage = 0
    @Environment(\.layoutDirection) var direction

    let pages = ["Welcome", "Security", "Ready"]

    var body: some View {
        VStack {
            // Page content with direction-aware transition
            ZStack {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    if index == currentPage {
                        Text(page)
                            .font(.largeTitle)
                            .transition(.slideFromTrailing(direction: direction))
                    }
                }
            }
            .animation(.easeInOut, value: currentPage)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Navigation
            HStack {
                // Back button — leading edge
                if currentPage > 0 {
                    Button("Back") {
                        withAnimation { currentPage -= 1 }
                    }
                }

                Spacer()

                // Page indicator
                HStack(spacing: 8) {
                    ForEach(pages.indices, id: \.self) { i in
                        Circle()
                            .fill(i == currentPage ? Color.accentColor : Color.secondary.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                // Dot order flips in RTL — first dot on the right = first page
                .environment(\.layoutDirection, direction)

                Spacer()

                // Next button — trailing edge
                if currentPage < pages.count - 1 {
                    Button("Next") {
                        withAnimation { currentPage += 1 }
                    }
                }
            }
            .padding()
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - 5. Bottom Sheet Pull Direction
// ─────────────────────────────────────────────────────────────────────────────
//
// Bottom sheets don't have a direction concern — they always slide up.
// Content inside the sheet does follow RTL rules.

struct RTLBottomSheetExample: View {
    @State private var showSheet = false

    var body: some View {
        Button("Show Transfer Sheet") { showSheet = true }
            .sheet(isPresented: $showSheet) {
                // Content inside the sheet follows the parent environment direction
                // No additional setup needed — environment propagates into sheets
                VStack(alignment: .leading, spacing: 16) {
                    Text("Transfer Money")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack {
                        Text("To:")
                        Spacer()
                        Text("Ahmed Al-Rashidi")
                    }

                    HStack {
                        Text("Amount:")
                        Spacer()
                        Text("BHD 100.000")
                            .environment(\.layoutDirection, .leftToRight)
                    }
                }
                .padding()
                .presentationDetents([.medium])
            }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - 6. Loading / Shimmer Animation Direction
// ─────────────────────────────────────────────────────────────────────────────
//
// Shimmer/skeleton animations should sweep in the reading direction:
// Left-to-right in English, right-to-left in Arabic.

struct ShimmerView: View {
    @State private var animating = false
    @Environment(\.layoutDirection) var direction

    var body: some View {
        GeometryReader { geo in
            let startX = direction == .rightToLeft ? geo.size.width : -geo.size.width

            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray5))
                .overlay(
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.6), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .offset(x: animating ? geo.size.width : startX)
                )
                .clipped()
                .onAppear {
                    withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                        animating = true
                    }
                }
        }
    }
}
