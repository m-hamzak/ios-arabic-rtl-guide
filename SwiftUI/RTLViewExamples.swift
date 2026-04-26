//
//  RTLViewExamples.swift
//  ios-arabic-rtl-guide
//
//  Created by Hamza Khalid on 26/04/2026.
//

import SwiftUI

// MARK: - SwiftUI RTL View Patterns
//
// Covers every major SwiftUI container and view type and how it behaves in RTL.
// Each section is a standalone example — copy the relevant pattern into your project.

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - 1. Text & TextAlignment
// ─────────────────────────────────────────────────────────────────────────────
//
// Never hardcode .leading or .trailing in multilineTextAlignment.
// SwiftUI maps .leading to the correct side based on the layout direction.

struct TextAlignmentExample: View {
    @Environment(\.layoutDirection) var direction

    var body: some View {
        VStack(spacing: 16) {

            // ✅ .leading maps to right in RTL, left in LTR
            Text("هذا مثال على النص العربي الطويل الذي يحتاج إلى محاذاة صحيحة.")
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            // ✅ For mixed content: force a specific direction per text
            Text("IBAN: AE070331234567890123456")
                .multilineTextAlignment(.leading)
                .environment(\.layoutDirection, .leftToRight)  // Always LTR for IBANs

            // ✅ .center is always correct for centered headings — no direction concern
            Text("Account Summary")
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            // ✅ Reading direction detection from string content
            // (SwiftUI does NOT auto-detect — you must set it explicitly)
            Text("مرحباً")
                .environment(\.layoutDirection, .rightToLeft)
        }
        .padding()
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - 2. HStack — Automatic Order Reversal
// ─────────────────────────────────────────────────────────────────────────────
//
// HStack automatically reverses item order in RTL when the environment direction is set.
// LTR: [icon] [label] [Spacer] [value]
// RTL: [value] [Spacer] [label] [icon]

struct TransactionRowView: View {
    let iconName: String
    let label: String
    let amount: String
    let isCredit: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Icon — appears on leading side (left in LTR, right in RTL)
            Image(systemName: iconName)
                .frame(width: 40, height: 40)
                .background(Color.accentColor.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.body)
                Text("Today")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Amount — always force LTR so digits read left-to-right
            Text(amount)
                .foregroundColor(isCredit ? .green : .red)
                .fontWeight(.semibold)
                .environment(\.layoutDirection, .leftToRight)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - 3. VStack Alignment — .leading is direction-aware
// ─────────────────────────────────────────────────────────────────────────────

struct FormSectionView: View {
    let title: String
    let fields: [(String, String)]  // (label, value)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            ForEach(fields, id: \.0) { label, value in
                HStack {
                    Text(label)
                        .foregroundColor(.secondary)
                        .frame(width: 120, alignment: .leading)

                    Text(value)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        // Force LTR for alphanumeric values (account numbers, codes)
                        .environment(\.layoutDirection, isAlphanumeric(value) ? .leftToRight : .rightToLeft)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private func isAlphanumeric(_ str: String) -> Bool {
        str.allSatisfy { $0.isLetter && $0.isASCII || $0.isNumber }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - 4. Image / SF Symbols — When to Flip and When Not To
// ─────────────────────────────────────────────────────────────────────────────

struct ImageDirectionExamples: View {
    var body: some View {
        VStack(spacing: 20) {

            // ✅ Directional SF Symbols — flip automatically via environment
            Image(systemName: "arrow.right")
                .imageScale(.large)
                // No need for .flipsForRightToLeftLayoutDirection — SF Symbols handle it

            // ✅ Custom directional icon (e.g. back arrow asset)
            Image("custom-arrow-right")
                .flipsForRightToLeftLayoutDirection(true)

            // ❌ Do NOT flip: logos, flags, avatars, decorative icons
            Image("bank-logo")
                .flipsForRightToLeftLayoutDirection(false)  // Always

            // ✅ Chevron in navigation — flips automatically
            Image(systemName: "chevron.right")
                .flipsForRightToLeftLayoutDirection(true)

            // ✅ Document / list icons — flip if they imply reading direction
            Image(systemName: "doc.text")
                .flipsForRightToLeftLayoutDirection(true)
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - 5. List & ForEach
// ─────────────────────────────────────────────────────────────────────────────
//
// List inherits the environment direction. Swipe actions, separators, and
// accessories flip automatically. Row content follows HStack rules.

struct TransactionListView: View {
    struct Transaction: Identifiable {
        let id = UUID()
        let title: String
        let amount: String
        let isCredit: Bool
    }

    let transactions: [Transaction] = [
        Transaction(title: "Salary", amount: "BHD 1,200.000", isCredit: true),
        Transaction(title: "Electricity", amount: "BHD 45.000", isCredit: false)
    ]

    var body: some View {
        List(transactions) { tx in
            TransactionRowView(
                iconName: tx.isCredit ? "arrow.down.circle" : "arrow.up.circle",
                label: tx.title,
                amount: tx.amount,
                isCredit: tx.isCredit
            )
            .swipeActions(edge: .trailing) {
                // Swipe actions: in LTR, .trailing = right swipe
                // In RTL, .trailing = left swipe — correct behaviour automatically
                Button("Delete", role: .destructive) {}
            }
        }
        .listStyle(.plain)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - 6. NavigationStack — RTL Back Button & Title
// ─────────────────────────────────────────────────────────────────────────────
//
// NavigationStack respects the environment direction.
// The back chevron flips: ‹ in LTR becomes › in RTL.
// Push/pop animations slide from the correct direction.

struct RTLNavigationExample: View {
    @Environment(\.layoutDirection) var direction

    var body: some View {
        NavigationStack {
            VStack {
                NavigationLink("Go to Detail") {
                    DetailView()
                        // The push animation slides from right in LTR, left in RTL
                        // NavigationStack handles this automatically
                }
            }
            .navigationTitle("Accounts")
            .navigationBarTitleDisplayMode(.large)
            // In RTL: the large title appears right-aligned, back button on the right
        }
    }
}

struct DetailView: View {
    var body: some View {
        Text("Detail Content")
            .navigationTitle("Details")
            // Back button: automatically shows › in RTL, ‹ in LTR
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - 7. TabView
// ─────────────────────────────────────────────────────────────────────────────
//
// Tab order reverses in RTL. The leftmost tab in LTR becomes the rightmost in RTL.
// Tab bar item icons flip if they are directional.

struct RTLTabViewExample: View {
    var body: some View {
        TabView {
            Text("Home")
                .tabItem {
                    Label("Home", systemImage: "house")
                }

            Text("Accounts")
                .tabItem {
                    // This icon does NOT flip — house has no direction
                    Label("Accounts", systemImage: "creditcard")
                }

            Text("Transfers")
                .tabItem {
                    // Arrow icons DO flip — transfer implies direction
                    Label("Transfers", systemImage: "arrow.left.arrow.right")
                }

            Text("Settings")
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        // Tab order in LTR: Home | Accounts | Transfers | Settings
        // Tab order in RTL: Settings | Transfers | Accounts | Home
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - 8. Form / TextField
// ─────────────────────────────────────────────────────────────────────────────

struct RTLFormExample: View {
    @State private var fullName = ""
    @State private var iban = ""
    @State private var notes = ""

    var body: some View {
        Form {
            Section("Personal Information") {
                // ✅ TextField inherits direction — Arabic keyboard appears in RTL locale
                TextField("Full Name", text: $fullName)
                    // .leading alignment maps to right side in RTL
                    .multilineTextAlignment(.leading)
            }

            Section("Bank Details") {
                // ✅ Force LTR for IBAN input — user types left-to-right always
                TextField("IBAN", text: $iban)
                    .environment(\.layoutDirection, .leftToRight)
                    .keyboardType(.asciiCapable)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.characters)
            }

            Section("Notes") {
                // ✅ TextEditor — natural alignment, direction from environment
                TextEditor(text: $notes)
                    .frame(height: 100)
                    .multilineTextAlignment(.leading)
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - 9. LazyVGrid / LazyHGrid
// ─────────────────────────────────────────────────────────────────────────────
//
// Grid item order reverses in RTL just like HStack.
// First item appears on the right in RTL.

struct RTLGridExample: View {
    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    let services = ["Transfer", "Pay Bill", "Top Up", "History", "Cards", "Settings"]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(services, id: \.self) { service in
                VStack {
                    Image(systemName: "square.grid.2x2")
                        .font(.title)
                    Text(service)
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            }
        }
        .padding()
        // In RTL: grid reads right-to-left, items fill right column first
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - 10. ScrollView
// ─────────────────────────────────────────────────────────────────────────────
//
// Horizontal ScrollView starts from the trailing edge in RTL.
// Useful for horizontal card carousels in banking home screens.

struct RTLHorizontalScrollExample: View {
    let accounts = ["Current Account", "Savings Account", "Fixed Deposit"]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 16) {
                ForEach(accounts, id: \.self) { account in
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.accentColor.opacity(0.15))
                        .frame(width: 200, height: 120)
                        .overlay(
                            Text(account)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                        )
                }
            }
            .padding(.horizontal)
        }
        // In RTL: first card appears on the right, scroll starts from right edge
    }
}
