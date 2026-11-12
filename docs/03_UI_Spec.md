# 03 — UI & Design System Specification: ResaleRoute

## 1. Aesthetic Direction
**ResaleRoute** implements a **Dark-First Editorial Vault** aesthetic designed for high-density operational clarity in boutique backrooms and high-trust luxury presentation for resale shoppers, with full Light Mode support.

---

## 2. Color Palette Tokens

| Token Name | Dark Theme Hex | Light Theme Hex | Semantic Usage |
| :--- | :--- | :--- | :--- |
| `bg.canvas` | `#0B0D10` | `#F8F9FA` | Primary application scaffold background |
| `bg.surface` | `#13171D` | `#FFFFFF` | Cards, modals, bottom sheets, and ledger rows |
| `bg.elevated` | `#1C222B` | `#F1F3F5` | Hover states, active steppers, and text inputs |
| `text.primary` | `#F3F4F6` | `#111827` | Headings, primary copy, and prices |
| `text.secondary` | `#9CA3AF` | `#4B5563` | Subtitles, metadata labels, and timestamps |
| `accent.primary` | `#10B981` | `#059669` | Primary CTAs, verified badges, sustainability metrics |
| `accent.luxury` | `#D4AF37` | `#B48A1E` | Provenance certificates and Mint Grade badges |
| `status.warning` | `#F59E0B` | `#D97706` | Pending authentication and aging stock alerts |
| `status.danger` | `#EF4444` | `#DC2626` | Counterfeit rejection, disputes, and destructive actions |
| `border.subtle` | `#262E3B` | `#E5E7EB` | $1\text{px}$ structural dividers and card outlines |

---

## 3. Typography Scale
* **Heading Font:** `Plus Jakarta Sans` (SemiBold 600, Bold 700)
* **Body Font:** `Inter` (Regular 400, Medium 500, SemiBold 600)
* **Monospace Font:** `JetBrains Mono` (Medium 500) — mandatory for SKUs, currency amounts, basis-point splits, and cryptographic provenance hashes.

| Token | Font Family | Size / Line Height | Weight | Letter Spacing |
| :--- | :--- | :--- | :--- | :--- |
| `display.lg` | Plus Jakarta Sans | $28\text{px} / 36\text{px}$ | 700 | $-0.5\text{px}$ |
| `heading.md` | Plus Jakarta Sans | $20\text{px} / 28\text{px}$ | 600 | $-0.3\text{px}$ |
| `title.sm` | Plus Jakarta Sans | $16\text{px} / 24\text{px}$ | 600 | $0\text{px}$ |
| `body.md` | Inter | $14\text{px} / 20\text{px}$ | 400 | $0\text{px}$ |
| `label.sm` | Inter | $12\text{px} / 16\text{px}$ | 500 | $+0.2\text{px}$ |
| `mono.data` | JetBrains Mono | $13\text{px} / 18\text{px}$ | 500 | $0\text{px}$ |

---

## 4. Spacing, Layout Grid & Theme Rules
* **Spacing Scale:** Strict $4\text{px}$ base unit ($4, 8, 12, 16, 24, 32, 48\text{px}$). Horizontal screen padding is $16\text{px}$ on mobile viewports ($< 600\text{px}$) and $32\text{px}$ on tablet/desktop viewports ($\ge 600\text{px}$).
* **Border Radius:** $12\text{px}$ for cards and modals, $8\text{px}$ for buttons and input fields, $999\text{px}$ for status pills.
* **Dark/Light Surface Separation:** Dark mode is the default theme (`ThemeMode.dark`). In Dark Mode, drop shadows are strictly forbidden; separate surfaces using $1\text{px}$ solid `#262E3B` borders and background luminance shifts. In Light Mode, combine $1\text{px}$ solid `#E5E7EB` borders with a subtle elevation shadow (`0 2px 8px rgba(0,0,0,0.04)`).

---

## 5. Core Component States

### 5.1 Primary Action Button (`ResaleButton`)
* **Default:** Background `#10B981`, Text `#0B0D10` (Bold 600), height $48\text{px}$, radius $8\text{px}$.
* **Pressed / Focused:** Background `#059669`, $2\text{px}$ outer focus ring `#34D399`.
* **Disabled:** Background `#1C222B`, Text `#4B5563`, pointer events disabled.
* **Loading:** Replaces text label with a $20\text{px}$ circular progress indicator (`#0B0D10`, stroke width $2.5\text{px}$) and blocks duplicate taps.

### 5.2 Condition Grade Badge (`GradeBadge`)
* **Mint (`mint`):** Border `#D4AF37`, background `#D4AF37` at $15\%$ opacity, label `#D4AF37`.
* **Excellent / Very Good (`excellent`, `very_good`):** Border `#10B981`, background `#10B981` at $15\%$ opacity, label `#10B981`.
* **Good / Fair (`good`, `fair`):** Border `#F59E0B`, background `#F59E0B` at $15\%$ opacity, label `#F59E0B`.

### 5.3 Consignor Split Ledger Row (`LedgerSplitRow`)
* Renders a dual-segment horizontal bar visualizing Consignor Share vs. Boutique Commission alongside `JetBrains Mono` formatted currency figures and a semantic state pill (`ESCROW`, `AVAILABLE`, `PAID`, `FROZEN`).