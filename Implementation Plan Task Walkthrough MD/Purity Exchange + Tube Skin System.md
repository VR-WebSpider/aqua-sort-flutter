# Purity Exchange + Tube Skin System

## Overview

Two interconnected features shown in the screenshots:

1. **Purity Exchange** — A full-featured cosmetics shop where players spend coins to buy tube skins. Supports All / Standard / Premium / Legendary filter tabs, a Daily Resonance Boost streak banner, tier-section headers, skin preview cards with prices, and a purchase flow.

2. **Tube Skin Preview Screen** — A dedicated skin detail/equip screen showing a full-size animated tube preview, skin name, an owned/locked skin carousel at the bottom for quick switching, and home / back navigation.

The existing codebase already has:
- `levelProvider` with `activeSkinId`, `ownedSkinIds`, `purchaseSkin()`, `equipSkin()`
- `coins` balance on `LevelProgress`
- A `/customization` route (currently pointing to a missing `CustomizationScreen`)
- `AppColors` design tokens, `GoogleFonts`, Riverpod

---

## Proposed Changes

### 1. Skin Catalogue Model — `[NEW]`
#### [NEW] `lib/features/profile/models/skin_catalogue.dart`
- `SkinTier` enum: `standard`, `premium`, `legendary`
- `TubeSkin` data class: `id`, `name`, `tier`, `price`, `colors` (List of Color for the tube gradient), `glowColor`
- Static `SkinCatalogue.all` list with 12+ skins:
  - **Standard (500c):** Toxic Slime (green), Solar Flare (orange), Arctic Frost (light blue), Molten Core (red-orange)
  - **Premium (1000c):** Cyber Neon (cyan), Phantom Void (purple-dark), Sakura (pink), Coral Reef (pink-teal)
  - **Legendary (2500c):** Dragon Fire (fire gradient), Aurora (rainbow), Obsidian (dark), Celestial (gold)
  - **Default (0c, always owned):** Classic Glass

---

### 2. Skin Provider — `[NEW]`
#### [NEW] `lib/features/profile/providers/skin_provider.dart`
- `activeSkinProvider` — a derived provider that reads `levelProvider.activeSkinId` and resolves it to a `TubeSkin` object
- `ownedSkinsProvider` — a derived provider listing `TubeSkin` objects the player owns
- `SkinNotifier` with `equip(skinId)` / `purchase(skinId, price)` that delegates to `levelProvider.notifier`

---

### 3. Purity Exchange Screen — `[NEW]`
#### [NEW] `lib/features/profile/screens/purity_exchange_screen.dart`
Full-featured shop screen matching the screenshot:
- Header: "PURITY EXCHANGE" + coin balance badge + close button
- Filter tab row: All / Standard / Premium / Legendary
- **Daily Resonance Boost** banner card with streak count + "VIEW" button
- Section dividers: STANDARD / PREMIUM / LEGENDARY (styled chips)
- `GridView` of `_SkinCard` widgets (2-column grid)
- `_SkinCard` shows: animated tube preview (mini), skin name, tier badge, price pill
- Tap → navigate to `SkinDetailScreen`

---

### 4. Skin Detail / Equip Screen — `[NEW]`
#### [NEW] `lib/features/profile/screens/skin_detail_screen.dart`
Full-screen skin preview matching screenshot 2:
- Dark starfield background
- Large animated tube preview (tall rounded rectangle with liquid animation)
- Skin name in uppercase bold
- Bottom carousel strip: shows all skins (owned = checkmark + "OWNED", locked = padlock icon)
- If owned and not active → "EQUIP" button; if active → "EQUIPPED" badge
- If not owned → "BUY FOR X coins" button (or "NOT ENOUGH COINS" disabled state)
- Purchase confirmation snackbar / dialog

---

### 5. Tube Widget — Apply Active Skin `[MODIFY]`
#### [MODIFY] `lib/features/game/widgets/tube_widget.dart`
- Read `activeSkinProvider` and apply skin's color palette as overlay tint / glow on the tube
- The skin's `glowColor` replaces the default cyan glow border
- The skin's `colors` affect the liquid segment gradient

---

### 6. Router — Wire customization route `[MODIFY]`
#### [MODIFY] `lib/core/router/app_router.dart`
- Change `/customization` to import and use `PurityExchangeScreen`
- Add `/skin-detail` route that accepts a `TubeSkin` via `extra`

---

### 7. Profile Screen — Add Customization entry `[MODIFY]`
#### [MODIFY] `lib/features/profile/screens/profile_screen.dart`
- Add a "Purity Exchange" profile item that routes to `/customization`

---

### 8. Privacy Policy email fix `[MODIFY]`
#### [MODIFY] `lib/features/profile/screens/profile_screen.dart`
- Change `vr.webspider@gmail.com` → `webspiderstudios@gmail.com`

---

## Open Questions

> [!IMPORTANT]
> **Coin currency for skins**: The screenshots show a generic "coin" icon. Should skin purchases use the regular `coins` balance, or one of the Spider Coin types (Gold, Copper, etc.)?
> _Defaulting to regular `coins` unless told otherwise._

> [!NOTE]
> The daily resonance boost "VIEW" button on the Purity Exchange can navigate to an existing daily-reward sheet or be a stub for now — I'll open the existing daily reward flow.

## Verification Plan

### Automated
- `flutter analyze` — no errors
- `flutter build apk --debug` — successful compilation

### Manual
- Navigate Profile → Purity Exchange → see skin grid
- Tap a skin → see detail screen with preview
- Buy a skin (if enough coins) → owned
- Equip a skin → active skin changes in game
