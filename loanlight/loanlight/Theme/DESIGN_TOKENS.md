# LoanPath Design Tokens

## Colors

### Primary Palette

| Name         | Swift                | Hex       | Usage                                         |
|--------------|----------------------|-----------|-----------------------------------------------|
| Ink black    | `.lpInk`             | `#0f0e17` | Backgrounds (dark), hero sections, primary text |
| Paper        | `.lpPaper`           | `#fafaf8` | Main screen background — warm off-white        |
| Sage green   | `.lpSage`            | `#3d6b5e` | Primary CTAs, action buttons, active states    |
| Sage tint    | `.lpSageTint`        | `#e8f1ee` | Chip/pill backgrounds, selected card fill      |
| Antique gold | `.lpGold`            | `#c9a84c` | Logo, CTA on dark screens, highlights          |
| Gold wash    | `.lpGoldWash`        | `#f9f3e3` | Insight cards, warning backgrounds             |

### Supporting Palette

| Name         | Swift                | Hex       | Usage                                         |
|--------------|----------------------|-----------|-----------------------------------------------|
| Blue-grey mist | `.lpMist`          | `#8e9aaa` | Secondary text, labels, subtext, axis labels   |
| Warm grey    | `.lpBorder`          | `#e0e0e0` | Borders, dividers, card strokes                |
| Light grey   | `.lpSurface`         | `#ebebeb` | Subtle backgrounds, input fills, skeletons     |
| Confirm green | `.lpSuccess`        | `#27ae60` | Success states, extracted data badges          |
| Alert red    | `.lpDanger`          | `#c0392b` | Error states — used subtly                     |

### Semantic Aliases (prefer these in views)

| Alias            | Maps to       | Use for                         |
|------------------|---------------|---------------------------------|
| `.primaryText`   | `.lpInk`      | All primary body text           |
| `.secondaryText` | `.lpMist`     | Subtitles, labels, placeholders |
| `.screenBg`      | `.lpPaper`    | Screen/page backgrounds         |
| `.cardBg`        | `.white`      | Card interiors                  |
| `.subtleBg`      | `.lpSurface`  | Input fields, skeleton loaders  |
| `.divider`       | `.lpBorder`   | Lines between sections          |
| `.primary`       | `.lpSage`     | Primary action color            |
| `.primaryTint`   | `.lpSageTint` | Tinted backgrounds near primary |
| `.accent`        | `.lpGold`     | Gold highlights                 |
| `.accentTint`    | `.lpGoldWash` | Soft gold backgrounds           |
| `.success`       | `.lpSuccess`  | Success / confirmation          |
| `.danger`        | `.lpDanger`   | Errors / alerts                 |

---

## Typography

### Font Families
- **Georgia** (serif) → screen titles, hero numbers, freedom date, key metrics
- **SF Pro** (system) → all body copy, labels, buttons, captions

### Scale

| Style            | Swift                  | Size | Weight    | Use                              |
|------------------|------------------------|------|-----------|----------------------------------|
| Serif large      | `AppFont.serif(26)`    | 26   | —         | Freedom date, hero metric value  |
| Serif medium     | `AppFont.serif(20)`    | 20   | —         | Result card values               |
| Serif small      | `AppFont.serif(17)`    | 17   | —         | Card headings, section titles    |
| Screen title     | `AppFont.serif(24)`    | 24   | —         | Page header ("Your Plan")        |
| Section label    | `AppFont.sectionLabel` | 10   | Bold      | Section headers — all caps       |
| Body semibold    | `AppFont.bodySemibold` | 14   | Semibold  | Card labels, row titles          |
| Body             | `AppFont.body`         | 14   | Regular   | Descriptions, paragraphs         |
| Caption          | `AppFont.caption`      | 12   | Regular   | Subtitles, secondary info        |
| Caption bold     | `AppFont.captionBold`  | 12   | Semibold  | Delta labels, status text        |
| Tag / micro      | `AppFont.tag`          | 10   | Semibold  | Badges, tags, axis labels        |
| Chip             | `AppFont.chip`         | 11   | Semibold  | Filter chips, toggle pills       |
| CTA button       | `AppFont.ctaButton`    | 15   | Bold      | Primary action buttons           |

### Letter Spacing
```swift
Text("SECTION LABEL").tracked(.wide)   // 1.0 — section headers
Text("TAG BADGE").tracked(.wider)      // 1.5 — badges, tags
```

---

## Component Patterns

### Cards
- Background: `.cardBg` (white)
- Corner radius: `16` (result cards), `20` (main content cards)
- Border: `1pt` stroke, `.cardBorder`
- Padding: `16pt` inside

### Buttons
- Primary (CTA): `.lpSage` fill, white text, `16pt` radius, `17pt` vertical padding
- Primary on dark: `.lpGold` fill, `.lpInk` text
- Selected pill: `.lpSageTint` bg, `.lpSage` text, `1.5pt` sage border
- Unselected pill: white bg, `.lpMist` text, `1.5pt` border color

### Section Labels
```swift
Text("SECTION NAME")
    .font(AppFont.sectionLabel)
    .tracked(.wide)
    .textCase(.uppercase)
    .foregroundColor(.secondaryText)
```

### Gradient Cards (results)
- Sage: `#3d6b5e → #2d5248` (topLeading → bottomTrailing)
- Gold: `#b8893a → #8a6520` (topLeading → bottomTrailing)
- Text on gradients: white at full opacity (values), white at 65% (labels), white at 55% (deltas)
