# KiSA — Mobile App UI Design Spec (Flutter)

> Bu hujjat KiSA moliyaviy ilovasining to'liq UI dizaynini tavsiflaydi. Claude Code shu hujjatga qarab Flutter ekranlarini qurishi mumkin (Figma'ga kirish shart emas). Barcha UI matnlari (label, tugma) **o'zbek tilida**, aniq shu ko'rinishda saqlanishi kerak.

**Project context:** Flutter + Provider + Hive (fully offline, no login required). Existing structure: `lib/theme/app_theme.dart`, `lib/screens/*.dart`, `lib/widgets/*.dart`, `lib/services/*`.

**Reference device:** designed at 390×844 (iPhone). Implement responsively — use padding/Expanded/Flexible, not hardcoded 390px widths. Standard screen horizontal padding = **20px**, content max width ≈ 350.

---

## 0. How to use this spec (for Claude Code)

1. First implement the **design tokens** (Section 1) in `lib/theme/app_theme.dart` — colors, gradient, text styles, shadows, radii.
2. Build the **shared components** (Section 2) as reusable widgets in `lib/widgets/`.
3. Implement each **screen** (Sections 3–11) using the tokens + shared widgets.
4. Charts: donut → `fl_chart` (PieChart) or CustomPainter; progress rings → `percent_indicator` (CircularPercentIndicator) or CustomPainter; progress bars → simple `Stack` of two rounded `Container`s.
5. Fonts: add **Inter** (weights 300/400/500/600/700). Use the `google_fonts` package (`GoogleFonts.inter(...)`) or bundle the TTFs in `pubspec.yaml`.

---

## 1. Design Tokens

### 1.1 Colors (Dart)

```dart
import 'package:flutter/material.dart';

class KColors {
  // Surfaces
  static const bg       = Color(0xFFEEF1F6); // app background (light gray)
  static const card     = Color(0xFFFFFFFF); // white cards
  static const dark     = Color(0xFF14161F); // dark card (summary)

  // Text
  static const ink      = Color(0xFF0F172A); // primary
  static const sub      = Color(0xFF6B7280); // secondary
  static const mut      = Color(0xFF9AA1AD); // tertiary / hints
  static const line     = Color(0xFFEDEFF3); // dividers / track

  // KiSA brand
  static const primary  = Color(0xFF1C9D67); // KiSA green accent (buttons, active states)
  static const gradStart = Color(0xFF15737F); // teal  (gradient bottom-left)
  static const gradMid   = Color(0xFF1C8A74);
  static const gradEnd   = Color(0xFF2FA169); // green (gradient top-right)
  static const greenBg   = Color(0xFFE2F4EC); // green tint (icon backgrounds)

  // Semantic / category
  static const danger   = Color(0xFFF2585B); static const dangerBg = Color(0xFFFDECEC);
  static const orange   = Color(0xFFFF8B3D); static const orangeBg = Color(0xFFFFF1E6);
  static const blue     = Color(0xFF4C8DFF); static const blueBg   = Color(0xFFE9F0FF);
  static const purple   = Color(0xFF8B5CF6); static const purpleBg = Color(0xFFEDE9FE);
  static const pink     = Color(0xFFEC4899); static const pinkBg   = Color(0xFFFCE8F3);
  static const indigo   = Color(0xFF6366F1); static const indigoBg = Color(0xFFE8EAFF);
}

// KiSA signature gradient (logo, balance card, primary CTA, FAB)
const kGradient = LinearGradient(
  begin: Alignment.bottomLeft,
  end: Alignment.topRight,
  colors: [Color(0xFF15737F), Color(0xFF1C8A74), Color(0xFF2FA169)],
  stops: [0.0, 0.55, 1.0],
);
```

### 1.2 Typography — Inter

| Role | Size | Weight |
|------|------|--------|
| Logo wordmark (onboarding tile) | 30 | 300 (Light) |
| Screen title (Statistika, Byudjet, Profil…) | 22 | 700 |
| Onboarding name "KiSA" big / headline | 36 / 26 | 700 |
| Big balance amount | 34 | 700 |
| Section header (So'nggi amallar…) | 15–16 | 600 |
| Card title / amount | 17–18 | 600/700 |
| List item title | 14 | 600 |
| Label / body | 13–14 | 500/400 |
| Sub text / meta | 11.5–12.5 | 400/500 |
| Nav label | 10 | 500 (600 active) |

```dart
// Example with google_fonts
TextStyle k(double size, {FontWeight w = FontWeight.w400, Color c = KColors.ink, double? ls}) =>
  GoogleFonts.inter(fontSize: size, fontWeight: w, color: c, letterSpacing: ls);
```

### 1.3 Radii, spacing, shadows

```dart
// Radii
const rCardLg = 24.0;   // big cards
const rCard   = 18.0;   // standard cards / rows
const rBalance= 28.0;   // balance hero card
const rBtn    = 16.0;   // buttons
const rTile   = 14.0;   // icon buttons / inputs
const rIconSq = 9.0;    // small tinted icon squares (settings rows)
// Pills/chips use StadiumBorder or rCard.

// Page padding
const kPad = EdgeInsets.symmetric(horizontal: 20);

// Shadows
const kSoftShadow = [BoxShadow(color: Color(0x0F0F172A), offset: Offset(0,8),  blurRadius: 18)]; // ~6% ink
const kCardShadow = [BoxShadow(color: Color(0x0D0F172A), offset: Offset(0,10), blurRadius: 24)]; // ~5% ink
const kGreenShadow= [BoxShadow(color: Color(0x5915737F), offset: Offset(0,12), blurRadius: 24)]; // brand glow
const kFabShadow  = [BoxShadow(color: Color(0x7315737F), offset: Offset(0,10), blurRadius: 16)];
```

Icon set: thin line icons (Feather / Lucide style), stroke ≈ 2px. Use `lucide_icons` or `flutter_feather_icons` package, or Material rounded icons.

---

## 2. Shared Components

### 2.1 Bottom Navigation + FAB
- White bar, height ~84 (+ safe area). Subtle top hairline / shadow (`Color(0x0D0F172A)`, offset (0,-6)).
- 4 tabs: **Asosiy** (home), **Statistika** (bar-chart), **Byudjet** (wallet/credit-card), **Profil** (user). Icon 24 + label 10.
- Active tab: icon + label in `KColors.primary`, label weight 600, plus a 5px primary dot above the icon.
- Inactive: `KColors.mut`.
- **Center FAB**: 58px circle with `kGradient`, raised ~30px above the bar (overlaps top edge), white "+" icon, `kFabShadow`. Tapping FAB → opens Add-transaction modal (Section 7).

### 2.2 Card
White `Container`, `borderRadius: rCard/rCardLg`, `boxShadow: kSoftShadow`. Internal padding ~16.

### 2.3 Tinted icon tile
Rounded square/circle filled with a category's light tint (e.g. `KColors.orangeBg`) containing the category icon in the strong color (`KColors.orange`). Sizes: 32 (settings rows), 38–44 (list/stat rows).

### 2.4 Progress bar
`Stack`: track = full-width rounded `Container` (height 6–8, `KColors.line`); fill = rounded `Container` width = `track * pct`, colored. Cap at 100% for display; if over-budget use `danger` + show "Limitdan oshgan".

---

## 3. Screen — Onboarding / Xush kelibsiz  (`onboarding_screen.dart`)

Centered vertical layout on `KColors.bg`:
1. **Decorative rings** (top, centered behind logo): 3 concentric stroke circles, diameters ~290/220/152, colors alternating `gradEnd`/`gradStart` at low opacity (.16/.22/.38). A few small accent dots (filled `gradEnd`/`gradStart`). *Optional flourish — can use a Stack with positioned circles or CustomPaint.*
2. **Logo tile**: 104×104, `borderRadius: 30`, fill `kGradient`, `kGreenShadow`. Centered white wordmark **"KiSA"** (size 30, weight 300, letterSpacing 1). This is the app icon.
3. **Headline** (centered, 26/700, ink, 2 lines): `Pul nazorati endi\njuda oson`
4. **Tagline** (centered, 14.5/400, sub, 2 lines): `KiSA bilan hisob, byudjet va\nmaqsadlar — bitta ilovada.`
5. **Page dots**: active = 22×8 pill (`primary`), + 2 grey dots (8px, `Color(0xFFCBD2DC)`).
6. **CTA "Boshlash"**: full-width (350) height 56, `kGradient`, `rBtn`, white text 16/600, `kGreenShadow`.
7. **Link** (centered, 14): `Hisobingiz bormi? ` + **`Kirish`** (in `primary`, weight 600). Tapping → Login screen (or, since app is offline/no-login, this can go straight to dashboard — see note).

> **Offline note:** App is "fully offline, no account required". So onboarding "Boshlash" → main app (Dashboard). The Login screen (Section 4) is optional/cosmetic; you may skip it or keep it as a stub.

---

## 4. Screen — Login / Kirish  (`login_screen.dart`, optional)

On `KColors.bg`:
1. Back button (40px white circle, chevron-left) top-left.
2. Title (26/700 ink): `Xush kelibsiz!`  Subtitle (14/400 sub): `Hisobingizga kirib davom eting`.
3. Field label `Telefon raqam` (13/600 sub) → **input**: white, height 56, `rTile`, **green border (1.5, `primary`)** when focused; leading phone icon (`primary`); value `+998 90 123 45 67`.
4. Field label `Parol` → input: white, height 56, `rTile`, border `line`; leading lock icon (`mut`); obscured dots; trailing eye icon (`mut`).
5. Right-aligned link (13/600 `primary`): `Parolni unutdingizmi?`
6. **"Kirish"** button: full-width 56, `primary` solid, `rBtn`, white 16/600, `kGreenShadow`.
7. Divider with centered `yoki` (two hairlines + label, `mut`).
8. Two side-by-side social buttons (white, `rTile`, 1.5 `line` border): **Google** ("G" mark in `#4285F4`) and **Telegram** (paper-plane in `#229ED9`).
9. Footer (centered, 14): `Hisobingiz yo'qmi? ` + **`Ro'yxatdan o'tish`** (`primary`, 600).

---

## 5. Screen — Dashboard / Asosiy  (`dashboard_screen.dart`)

Scrollable column, `kPad`, on `KColors.bg`. Bottom nav (Asosiy active) + FAB.

1. **Header row**: left = 44–46px avatar circle (`#E2E8F0`, initials "JY" in `#475569`) + column [`Assalomu alaykum` 12/400 sub, `Jaloladdin` 17/600 ink]; right = 46px white rounded-square bell button (`rTile`, `kSoftShadow`) with a small red notification dot (`danger`).
2. **Balance card** (hero): full-width, height ~190, `rBalance`, fill **`kGradient`**, `kGreenShadow`. Contents:
   - Top: `Umumiy balans` (13/500 white@82%) + eye toggle icon (white@85%) at right.
   - Big amount: `12 450 000` (34/700 white) + `so'm` (15/500 white@82%).
   - Chip: white@18% pill with up-right arrow + `8,2%` (12/600 white) + `o'tgan oyga nisbatan` (12/400 white@85%).
   - Masked card number: `••••  ••••  ••••  4821` (13, white@55%, letterSpacing 1.5).
   - Bottom-right: Mastercard mark = two overlapping 22px circles (`#F5A623` + `#EF4444`@85%).
3. **Stat cards row** (two, gap 16): each white, 167×100, `rCard`, `kSoftShadow`.
   - **Kirim**: 38px circle `greenBg` + up-right arrow (`primary`); label `Kirim` (12/500 sub); amount `5 200 000` (17/600 ink) + `so'm`.
   - **Chiqim**: circle `dangerBg` + down-left arrow (`danger`); label `Chiqim`; amount `2 350 000`.
4. **Quick actions** (4, evenly spaced): 56px white rounded-square (`rCard` 18, `kSoftShadow`) + icon + label (11/500 sub) below:
   - `O'tkazma` (transfer icon, `primary`), `To'lov` (zap, `orange`), `Skaner` (scan, `blue`), `Maqsad` (target, `purple`).
5. **Section header**: `So'nggi amallar` (16/600 ink) + right link `Barchasi` (13/600 `primary`) → Transactions history (Section 11).
6. **Transactions card**: white, `rCardLg`, `kSoftShadow`, 3 rows separated by hairlines (`line`). Each row: 40px tinted circle + icon | title (14/600) + meta (11.5/400 mut) | amount (15/600, right). Expenses in `ink`, income in `primary`.
   - `Korzinka` · `Oziq-ovqat · Bugun` · `-185 000` (coffee, orange)
   - `Oylik maosh` · `Daromad · Kecha` · `+5 200 000` (cash, primary)
   - `Yandex Go` · `Transport · Kecha` · `-32 000` (car, blue)

---

## 6. Screen — Statistika  (`statistics_screen.dart`)

`kPad`, bottom nav (Statistika active) + FAB.

1. **Header**: title `Statistika` (22/700) + subtitle `Xarajatlaringiz tahlili` (13/400 sub); right = 44px white calendar icon button.
2. **Segmented control**: full-width track (`#E6E9EF`, `rTile`), 3 segments `Hafta` / `Oy` / `Yil`; active = `Oy` → white pill with shadow, ink 600; others sub 500.
3. **Donut chart card**: white, ~256 tall, `rCardLg`, `kSoftShadow`. Centered donut (outer ~196, inner radius ~70%) with 5 segments, center label `4 850 000` (23/700 ink) + `Jami sarf · so'm` (12/500 sub). Segments:
   - Oziq-ovqat 32% `orange` · Xaridlar 22% `pink` · Transport 18% `blue` · Kommunal 14% `purple` · Ko'ngilochar 14% `primary` (green).
4. **Category breakdown** header `Kategoriya bo'yicha` (15/600), then 5 rows. Each row: colored 13px rounded square + name (13.5/600) | percent (13.5/600, right) ; below: amount `… so'm` (11.5/400 mut) ; then a full-width thin progress bar (6px) filled by % in the category color.
   - Oziq-ovqat 32% `1 552 000` · Xaridlar 22% `1 067 000` · Transport 18% `873 000` · Kommunal 14% `679 000` · Ko'ngilochar 14% `679 000`.

---

## 7. Screen — Add transaction / Amal qo'shish  (`add_transaction_screen.dart`, modal)

Opened from FAB. `KColors.bg`, no bottom nav.

1. **Header**: 40px white close (✕) button left; centered title `Yangi amal` (17/600).
2. **Type toggle**: track (`#E6E9EF`, `rTile`), 2 segments `Chiqim` / `Kirim`; active `Chiqim` = white pill, text `danger` 600; `Kirim` sub. (When Kirim selected, accent flips to `primary`.)
3. **Amount display** (centered): `- 185 000` (40/700 ink) + `so'm` (14/500 mut) below. Hairline divider under it.
4. **Category** label `Kategoriya` (13/600 sub) + horizontal row of 60px chips (rounded 16): icon + label below. Selected (`Oziq-ovqat`) = filled category color + white icon + colored label + soft colored shadow; others = light tint bg + colored icon + mut label. Chips: `Oziq-ovqat`(coffee/orange, selected), `Transport`(car/blue), `Kommunal`(zap/purple), `Xaridlar`(bag/pink).
5. **Detail card** (white, `rCard`): two rows, hairline between:
   - tinted icon | `Hisob` (14/500 ink) | value `•••• 4821` (13/500 sub) + chevron. (wallet/green)
   - tinted icon | `Sana` | value `Bugun, 25 iyun` + chevron. (calendar/blue)
6. **Numeric keypad**: 3×4 grid — `1 2 3 / 4 5 6 / 7 8 9 / . 0 ⌫`. Big numerals (26/500 ink), centered cells, no backgrounds; ⌫ = backspace icon. (Wire to amount state.)
7. **Save button** `Saqlash`: full-width 56, `primary` (or `kGradient`), `rBtn`, white 16/600, `kGreenShadow`.

---

## 8. Screen — Byudjet  (`budget_screen.dart`)

`kPad`, bottom nav (Byudjet active) + FAB.

1. **Header**: title `Byudjet` (22/700) + subtitle `Iyun oyi · 30 kun` (13/400 sub); right = 44px add button (`primary` or `kGradient` filled, white "+").
2. **Hero card**: full-width ~168 tall, `rCardLg`, fill **`kGradient`** (or `primary`), `kGreenShadow`. Contents (white text):
   - translucent white circle + wallet icon (top-right).
   - `Qolgan mablag'` (13/500 white@~85%, use `#D6F5E8`).
   - `2 150 000` (28/700 white) + `so'm`.
   - progress bar: white@28% track + white fill at **69.3%**.
   - footer: `Sarflandi: 4 850 000` (left) · `Limit: 7 000 000` (right) — both 12/500 white@~90% (`#EAFBF3`).
3. **Categories** header `Kategoriyalar` (16/600) + right link `Tahrirlash` (13/600 `primary`).
4. **Budget rows** (5 white cards, `rCard`, height ~70, `kSoftShadow`). Each: 40px tinted icon | name (14/600) + `spent / limit` (12/400 mut) | percent (13/600, right) ; then a progress bar (6px) filled by % in the category color. Over-budget rows: percent + bar + sub-label in `danger`, sub-label text = `Limitdan oshgan`, bar capped at 100%.
   - `Oziq-ovqat` `1 250 000 / 1 500 000` **83%** (coffee/orange)
   - `Transport` `420 000 / 600 000` **70%** (car/blue)
   - `Xaridlar` `980 000 / 800 000` **122% — Limitdan oshgan** (bag/`danger`)
   - `Kommunal` `540 000 / 700 000` **77%** (zap/purple)
   - `Ko'ngilochar` `310 000 / 500 000` **62%** (star/primary green)

---

## 9. Screen — Maqsadlar (Goals)  (`goals_screen.dart`)

`KColors.bg`. Header has back button → so treat as a pushed screen (no bottom nav), OR keep nav if you make it a tab. Header: back (40px white circle, chevron-left) | centered title `Maqsadlar` (17/600) | right add button (`primary`, white "+").

1. **Summary card**: full-width ~100 tall, `rCardLg`, fill `KColors.dark`, `kCardShadow`. translucent circle + target icon (top-right). `Jami jamg'arma` (13/500 `#9AA0AE`) + `36 300 000` (26/700 white) + `so'm` + `4 ta maqsad sari yo'lda` (12/500 in mint `#34D399`).
2. Section `Faol maqsadlar` (15/600).
3. **Goal cards** (4, white, ~130 tall, `rCardLg`, `kSoftShadow`). Layout: **circular progress ring** on the left (≈76px, track `line`, arc in goal color, **category icon in the ring center**), details on the right: name (15/600) | saved amount (18/700 ink) + `so'm` | `<pct>% · <target> so'm maqsad` (11.5/500 mut) | linear progress bar (7px) filled by %.
   - `Yangi avtomobil` — saved `18 000 000`, target `45 000 000`, **40%**, color `blue`, car icon
   - `Sayohat — Dubai` — `6 500 000` / `10 000 000`, **65%**, `orange`, plane icon
   - `Favqulodda jamg'arma` — `9 000 000` / `12 000 000`, **75%**, `primary` green, shield icon
   - `Yangi telefon` — `2 800 000` / `8 000 000`, **35%**, `purple`, phone icon

---

## 10. Screen — Profil  (`settings_screen.dart`)

`kPad`, bottom nav (Profil active) + FAB. Title `Profil` (22/700) top-left.

1. **Profile header card** (white, ~96 tall, `rCardLg`, `kSoftShadow`): 60px avatar (`#E2E8F0`, "JY" in `#475569`) | column [`Jaloladdin Yuldashov` 16/600, `jalol0911j@gmail.com` 12.5/400 sub] | right 34px circle edit button (`greenBg` bg, edit/pencil icon `primary`).
2. **Stats card** (white, ~64 tall, `rCard`): 3 columns with vertical hairline dividers — `12,4 mln`/`Balans`, `2`/`Kartalar`, `3`/`Maqsadlar` (value 16/700 ink, label 11/400 mut).
3. Section label `HISOB` (11/600 mut, letterSpacing ~6%). **Card A** (white, `rCard`), 3 rows w/ hairlines. Each row: 32px tinted square icon + label (14/500 ink) + right element:
   - `Shaxsiy ma'lumotlar` (user/`blue`) → chevron
   - `Kartalarim` (card/`primary`) → `2 ta` (12.5/500 mut) + chevron
   - `Xavfsizlik` (shield/`purple`) → chevron
4. Section label `SOZLAMALAR`. **Card B**, 3 rows:
   - `Bildirishnomalar` (bell/`orange`) → **toggle ON** (track `primary`, knob right)
   - `Til` (globe/`blue`) → value `O'zbek` (13/500 sub) + chevron
   - `Tungi rejim` (moon/`indigo`) → **toggle OFF** (track `#D7DBE3`, knob left)
5. **Logout row** (white card, `rCard`, ~52 tall): 32px `dangerBg` square + logout icon (`danger`) + `Chiqish` (14/600 `danger`).

**Toggle widget:** 44×26 rounded track + 20px white knob (with small shadow); ON = `primary` track + knob right, OFF = `#D7DBE3` track + knob left.

---

## 11. Screen — Transactions history / Tranzaksiyalar tarixi  (`transactions_screen.dart`)

`KColors.bg`, pushed screen (back button), no bottom nav. Header: back | centered title `Tranzaksiyalar` (17/600) | right filter icon button.

1. **Search bar**: white, height 48, `rCard`, `kSoftShadow`, leading search icon + placeholder `Qidirish...` (sub).
2. **Filter chips** (horizontal): `Hammasi` (active = `primary` fill, white text), `Kirim`, `Chiqim`, `Bugun` (inactive = white, `line` border, sub text). Pill shape (height 36).
3. **Grouped list** by date. Each group: small uppercase date label (11/600 mut) + a white card (`rCard`) containing the day's rows (hairlines between). Row = 40px tinted circle + icon | title (14/600) + meta (11.5/400 mut) | amount (15/600, right; income `primary`, expense `ink`).
   - **BUGUN**: `Korzinka` `-185 000` (coffee/orange); `Yandex Go` `-32 000` (car/blue)
   - **KECHA**: `Oylik maosh` `+5 200 000` (cash/primary); `Uzcard to'lov` `-120 000` (card/purple); `Apteka` `-45 000` (cross/danger)
   - **23-IYUN**: `Korzinka` `-210 000` (coffee/orange); `Coffee House` `-28 000` (coffee/orange)

Use the existing `transaction_card.dart` widget for rows where possible.

---

## 12. Implementation notes

- **Numbers** use space as thousands separator (`12 450 000`) — format with `NumberFormat('#,###', ...)` then replace commas with spaces, or a custom formatter. Always append ` so'm` where shown.
- **Offline/Hive**: all sample numbers above are placeholders — bind them to your Hive data via Provider (`AppProvider`). Keep totals consistent (e.g. total monthly spend `4 850 000` is reused across Statistika & Byudjet).
- **Dark card vs gradient**: Dashboard balance card and Byudjet hero use `kGradient`; Maqsadlar summary uses the dark `#14161F`. This contrast is intentional.
- **Status bar** in real app is OS-provided — do not draw the fake "9:41" row; use `SafeArea`.
- **Charts**: donut (Statistika) and rings (Maqsadlar) — recommended packages `fl_chart` and `percent_indicator`. Match the exact colors and percentages above.
- **Consistency**: every primary action / active state / brand accent = `KColors.primary` (#1C9D67) or `kGradient`. Replace any old emerald (#10B981) usage with these.

---
*KiSA UI spec — generated for Flutter implementation. UI copy is in Uzbek and must stay verbatim.*
