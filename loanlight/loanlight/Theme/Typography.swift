import SwiftUI

// MARK: - LoanPath Typography
//
// Two font families:
//   • Georgia (serif) — headings, hero numbers, freedom date. Gives the app
//     a premium, editorial feel that contrasts with the clean sans-serif body.
//   • SF Pro (system) — all body copy, labels, buttons, captions.
//
// Never use font sizes or weights ad-hoc in views — always use AppFont.

enum AppFont {

    // ── Serif display ─────────────────────────────────────────────
    // Used for: screen titles, large metric values, freedom date

    static func serif(_ size: CGFloat, italic: Bool = false) -> Font {
        italic
            ? .custom("Georgia-Italic", size: size)
            : .custom("Georgia", size: size)
    }

    // ── Section labels ────────────────────────────────────────────
    // Small, uppercase, tracked — used above each section

    static var sectionLabel: Font {
        .system(size: 10, weight: .bold)
    }

    // ── Body ──────────────────────────────────────────────────────

    static var body:         Font { .system(size: 14) }
    static var bodyMedium:   Font { .system(size: 14, weight: .medium) }
    static var bodySemibold: Font { .system(size: 14, weight: .semibold) }
    static var bodyBold:     Font { .system(size: 14, weight: .bold) }

    // ── Captions / supporting ─────────────────────────────────────

    static var caption:      Font { .system(size: 12) }
    static var captionMedium: Font { .system(size: 12, weight: .medium) }
    static var captionBold:  Font { .system(size: 12, weight: .semibold) }

    // ── Micro labels ─────────────────────────────────────────────
    // For tags, badges, axis labels

    static var micro:        Font { .system(size: 10) }
    static var microBold:    Font { .system(size: 10, weight: .semibold) }
    static var tag:          Font { .system(size: 10, weight: .semibold) }
    static var chip:         Font { .system(size: 11, weight: .semibold) }
    static var pill:         Font { .system(size: 11, weight: .semibold) }

    // ── Buttons ───────────────────────────────────────────────────

    static var ctaButton:    Font { .system(size: 15, weight: .bold) }
    static var smallButton:  Font { .system(size: 13, weight: .semibold) }
}

// MARK: - Letter Spacing Convenience
//
// Usage: Text("SECTION LABEL").tracked(.wide)

extension View {
    func tracked(_ spacing: LetterSpacing) -> some View {
        self.tracking(spacing.value)
    }
}

enum LetterSpacing {
    case tight    // -0.2
    case normal   // 0
    case wide     // 1.0  (section labels)
    case wider    // 1.5  (tags, badges)

    var value: CGFloat {
        switch self {
        case .tight:  return -0.2
        case .normal: return 0
        case .wide:   return 1.0
        case .wider:  return 1.5
        }
    }
}
