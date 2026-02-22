import SwiftUI

// MARK: - LoanPath Brand Colors
//
// Every color in the app should come from here.
// Never hardcode hex values in views — always use these names.

extension Color {

    // ── Primary Palette ───────────────────────────────────────────

    /// #0f0e17 — Deep ink black. Backgrounds, hero sections, primary text.
    static let ink = Color(hex: "#0f0e17")

    /// #fafaf8 — Warm off-white / paper. Main screen background.
    /// Not pure white — has a slight cream warmth.
    static let paper = Color(hex: "#fafaf8")

    /// #3d6b5e — Sage green. Primary action color, CTAs, accents.
    static let sage = Color(hex: "#3d6b5e")

    /// #e8f1ee — Sage tint / mist green. Chip backgrounds, light accents.
    static let sagetint = Color(hex: "#e8f1ee")

    /// #c9a84c — Antique gold. Logo, primary CTA on dark screens, highlights.
    static let gold = Color(hex: "#c9a84c")

    /// #f9f3e3 — Gold wash. Insight card backgrounds, soft golden tint.
    static let goldwash = Color(hex: "#f9f3e3")

    // ── Supporting Palette ────────────────────────────────────────

    /// #8e9aaa — Blue-grey mist. Secondary text, labels, subtext.
    static let mist = Color(hex: "#8e9aaa")

    /// #e0e0e0 — Warm light grey. Borders, dividers.
    static let border = Color(hex: "#e0e0e0")

    /// #ebebeb — Slightly lighter warm grey. Subtle backgrounds, input fills.
    static let surface = Color(hex: "#ebebeb")

    /// #27ae60 — Confirmation green. Success states, extracted badges.
    static let success = Color(hex: "#27ae60")

    /// #c0392b — Alert red. Error states — defined but used subtly.
    static let danger = Color(hex: "#c0392b")

    // ── Derived / Computed ────────────────────────────────────────
    // These aren't new colors — they're the primary palette at reduced
    // opacity, given semantic names so views stay readable.

    /// Sage green at low opacity — used for selected card backgrounds.
    static let sagemist = Color(hex: "#3d6b5e").opacity(0.07)

    /// Gold at low opacity — used behind warnings, insight highlights.
    static let goldmist = Color(hex: "#c9a84c").opacity(0.10)

    // ── Hex initialiser ───────────────────────────────────────────

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double(int & 0xFF)          / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Semantic Aliases
//
// Views should use these names rather than the raw lp* names wherever possible.
// This makes it easy to retheme later without touching every view.

extension Color {

    // Text
    static var primaryText:   Color { .ink }
    static var secondaryText: Color { .mist }

    // Backgrounds
    static var screenBg:   Color { .paper }
    static var cardBg:     Color { .white }
    static var subtleBg:   Color { .surface }

    // Borders
    static var divider:    Color { .border }
    static var cardBorder: Color { .border }

    // Actions
    static var primary:    Color { .sage }
    static var primaryTint: Color { .sagetint }
    static var accent:     Color { .gold }
    static var accentTint: Color { .goldwash }

    // States
    static var success1:    Color { .success }
    static var danger1:     Color { .danger }
}
