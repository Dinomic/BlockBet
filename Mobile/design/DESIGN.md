# BlockBet Mobile – Auth Design Spec

Mockup: `auth-mockup.html` (same folder). Scope: Login, Sign-up, Home placeholder. Material 3 (`useMaterial3: true`), seed-free: set the ColorScheme explicitly.

## Color tokens (gold theme)

| Token | Light | Dark | M3 `ColorScheme` |
|---|---|---|---|
| bg | `#FAF8F3` | `#0E0C08` | `surface` / scaffoldBackgroundColor |
| surface | `#FFFFFF` | `#181510` | `surfaceContainerHighest` (fields, cards) |
| ink | `#14110A` | `#F3EEE3` | `onSurface` |
| muted | `#6B6454` | `#A39A85` | `onSurfaceVariant` |
| outline (input borders, ≥3:1) | `#8C8369` | `#776C55` | `outline` |
| outline-variant (cards, dividers) | `#D6CDB8` | `#3B3425` | `outlineVariant` |
| primary (gold, button fill, logo) | `#D4A017` | `#F5C542` | `primary` |
| on-primary (dark text on gold) | `#1A1405` | `#1A1405` | `onPrimary` |
| primary-text (links, ghost button text; gold fill is too light for text on white) | `#8A6100` | `#F5C542` | `tertiary` (use for TextButton / OutlinedButton foreground) |
| primary-soft | `#FBF1D4` | `#2E2510` | `primaryContainer` (focus ring) |
| error | `#C62828` | `#FF8A80` | `error` |
| error-bg | `#FDECEC` | `#3A1618` | `errorContainer` |
| ok (connected dot) | `#0F9D6B` | `#3DDC97` | custom / `secondary` |

Also set `onErrorContainer` = ink, `onPrimaryContainer` = ink, `outlineVariant` = outline.

**Status: design approved by the user. Logo chosen: Linked blocks.**

## Chosen logo: Linked blocks

SVG, 32×32 viewBox, two rounded squares (radius 5) overlapping:
```svg
<svg viewBox="0 0 32 32" fill="none">
  <rect x="3" y="3" width="17" height="17" rx="5" stroke="PRIMARY" stroke-width="3.4"/>
  <rect x="12" y="12" width="17" height="17" rx="5" fill="PRIMARY"/>
</svg>
```
`PRIMARY` = theme primary (`#D4A017` light / `#F5C542` dark). Wordmark "BlockBet" (Space Grotesk 700, 20) beside it with a 10 gap. Launcher icon: same mark, gold on `#0E0C08`. The other options below are kept for reference only.

## Logo options (pick one in the mockup)

All are 32×32 viewBox SVGs drawn with `primary` and `on-primary`, so they follow the theme. Shown next to the "BlockBet" wordmark (Space Grotesk 700, 20).
1. **Hexagon block** (default) – hexagon with an inner hexagon cut-out and a center dot.
2. **Monogram B** – rounded square (radius 9) with a bold "B".
3. **Linked blocks** – two interlocked rounded squares, one outlined, one filled.
4. **Coin** – gold coin with a ring and a diamond.
5. **Linked blocks variants** (same idea as 3): outlined pair, three-block chain, chain links, linked blocks with a center dot, and linked blocks inside a gold app tile.
The chosen one is exported to Flutter as an SVG asset (`flutter_svg`) and as the launcher icon (gold on dark `#0E0C08`).

6. **Betting cards + chain link** (B on each card, link = chain): *overlapped* (one filled and one outlined tilted card, overlapping like two links), *link bar* (two upright cards joined by a link), *diagonal chain* (stepped cards, link in the middle), *leaning pair* (cards lean together, link on top). The "B" is Space Grotesk 700, converted to paths for the SVG asset. The link is a stadium outline filled with the background color.

## Typography

- Display / headings: **Space Grotesk** 700 (`google_fonts` or bundled asset)
- Body / UI: **Inter** 400/500/600

| Role | Size / height | Weight | M3 TextTheme |
|---|---|---|---|
| Screen title | 28 / 1.15, letter-spacing -0.02em | 700 Space Grotesk | `headlineMedium` |
| Brand wordmark | 20 | 700 Space Grotesk | `titleLarge` |
| Body / lead | 14 / 1.5 | 400 | `bodyMedium` |
| Input text | 15 | 400 | `bodyLarge` |
| Button | 15 | 600 | `labelLarge` |
| Field label, helper, error | 12 | 500 / 400 | `labelMedium` / `bodySmall` |

## Spacing and shape

- 4-pt grid. Screen padding 20. Field gap 16. Label-to-field 6. Title block bottom 24. Brand block bottom 28.
- Radius: fields 14, buttons 14, banner 12, cards 20, chips 999.
- Field height 52, button height 52 (min touch target 48 satisfied).
- Outline width 1.5; focus: primary border + 3px `primaryContainer` ring.

## Components

1. **Text field** – outlined, filled with `surface`; label above the field (12/500, muted), not floating. States: default, focused, error (error border + 12px error text with icon below), disabled (while loading). Password variant has trailing eye / eye-off `IconButton` (44×44) toggling obscureText; tooltip "Show password" / "Hide password". Helper text under sign-up password: "Use 8+ characters with a number."
   - Flutter: `InputDecorationTheme(filled: true, fillColor: surface, border/enabledBorder: OutlineInputBorder(radius 14, outline 1.5), focusedBorder: primary, errorBorder: error, contentPadding: h14)`.
2. **Primary button** – full width, `FilledButton`, height 52, radius 14. Loading: disabled, 18px `CircularProgressIndicator(strokeWidth: 2.5)` + label ("Logging in…", "Creating account…"). Ghost variant (Log out): `OutlinedButton`, primary text, outline border.
3. **Error banner** – shown above the form for server/network errors (not field errors). `errorContainer` bg, 1px `error` border, radius 12, padding 12, error icon + bold title + body in `onSurface`. Role: alert/semantics liveRegion.
4. **Text link button** – `TextButton`, primary, 14/600 ("Create account", "Log in").
5. **Network chip** – pill, `primaryContainer` bg, green dot, "Private network" (Home only).
6. **Placeholder card** – 1.5px dashed outline, radius 16, title 600 + muted 13px body (Home).

## Screens and copy

- **Login**: brand, "Welcome back" / "Log in to place and track your bets.", Email, Password (eye), "Log in", footer "New to BlockBet? Create account".
- **Sign-up**: "Create account" / "One account for every market on the network.", Email, Password, Confirm password, "Create account", footer "Already have an account? Log in".
- **Home**: brand + network chip, "You're in", signed-in email card, two placeholder cards, "Log out".

## Validation and error messages

Validate on submit; clear a field's error as the user edits it.
- Email empty: "Enter your email." Invalid: "Enter a valid email address."
- Login password empty: "Enter your password."
- Sign-up password: "Use at least 8 characters with a number."; confirm empty: "Confirm your password."; mismatch: "Passwords do not match."
- Banners: login 401 → "Email or password is incorrect. Check them and try again."; sign-up 409 → "An account with this email already exists. Log in instead."; network/5xx → "Can't reach the server. Check your connection and try again." (title adapts: "Couldn't log you in" / "Couldn't create your account").

## Behavior

Keep the form values on error. Disable all inputs and the button while loading. Show/hide applies to both password fields on sign-up together. Keyboard: email → next, password → done submits. Success → Home (replace route); Log out → Login.
