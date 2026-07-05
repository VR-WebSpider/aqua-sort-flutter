# Ad Monetization Integration — Google Mobile Ads (AdMob)

## Overview

Integrate Google AdMob into Aqua Sort following a **player-first** philosophy: ads must feel natural and never interrupt gameplay. The strategy uses **passive banner ads** in menus, **interstitials triggered only at natural pause points** (level completions, returning to campaign), and **rewarded ads** that are already integrated but currently simulated — these will be wired to real AdMob SDK calls.

After ads are integrated, the app will be upgraded to **version 1.2.0** and submitted to the **Production track** on Google Play Console.

---

## User Review Required

> [!IMPORTANT]
> **AdMob App ID & Unit IDs needed**: Before implementation can complete, you must provide your AdMob App ID and ad unit IDs. These are obtained from your AdMob account at https://admob.google.com. You will need:
> - **AdMob App ID** (Android) — format: `ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX`
> - **Banner Ad Unit ID** — for menu/campaign screens
> - **Interstitial Ad Unit ID** — for between-level transitions
> - **Rewarded Ad Unit ID** — for the existing "Watch Ad" recovery system
> - **Rewarded Interstitial Ad Unit ID** — optional, for daily bonus offers
>
> During development/testing, we will use **AdMob test IDs** so no real traffic is needed right away.

> [!WARNING]
> **Premium users are ad-free**: All ads will be suppressed for users with an active premium subscription. The existing `premiumProvider` already handles this.

> [!NOTE]
> **Google Play Production submission**: After ads are integrated and the build is verified, we will:
> 1. Bump the version from `1.1.0+5` to `1.2.0+6`
> 2. Build a signed App Bundle (AAB)
> 3. Upload to the Production track on Google Play Console

---

## Ad Placement Strategy

The placement strategy is designed so players feel like they're playing a polished game, not being monetized aggressively:

| Ad Type | Where | When | Frequency |
|---|---|---|---|
| **Banner** | Campaign map (bottom) | Always visible | Continuous (hidden for premium) |
| **Banner** | Profile screen (bottom) | Always visible | Continuous (hidden for premium) |
| **Banner** | Leaderboard screen (bottom) | Always visible | Continuous (hidden for premium) |
| **Interstitial** | After level win → return to campaign | Natural pause | Max every 3 levels (not on first run) |
| **Interstitial** | When returning to campaign from lobby | Natural pause | Max once per 5 minutes |
| **Rewarded** | Game over "Watch Ad to Revive" | Player-initiated | Already exists, wire to real SDK |
| **Rewarded** | "Earn Coins" button in currency store | Player-initiated | Max 3 per day |

---

## Proposed Changes

### Component 1: Dependency & Configuration

#### [MODIFY] [pubspec.yaml](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/pubspec.yaml)
- Add `google_mobile_ads: ^5.3.0` dependency
- Bump version from `1.1.0+5` → `1.2.0+6`

#### [MODIFY] [AndroidManifest.xml](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/android/app/src/main/AndroidManifest.xml)
- Add `<meta-data>` tag with AdMob App ID
- Add `<uses-permission>` for `com.google.android.gms.permission.AD_ID` (required by AdMob SDK on Android 13+)

---

### Component 2: Ad Service (Core)

#### [MODIFY] [ad_service.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/core/services/ad_service.dart)
Replace the current simulated-ad stub with a full **Google Mobile Ads** service:
- `initialize()` — called once at app startup, initializes `MobileAds.instance`
- `loadBannerAd(String unitId)` → returns a `BannerAd` (320×50) for embedding
- `loadInterstitial()` — preloads an interstitial ad so it's ready instantly
- `showInterstitialAd()` — shows the preloaded interstitial; respects a 3-level / 5-minute cooldown
- `showRewardedAd(BuildContext context)` — replaces the simulated dialog with a real `RewardedAd`; returns coin reward on completion
- `canShowInterstitial` getter — checks both frequency cap and time cap

#### [NEW] [ad_widgets.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/core/widgets/ad_widgets.dart)
A reusable `AdBannerWidget` that:
- Wraps the `BannerAd` in a `SizedBox` with a subtle separator line (matches the dark theme)
- Hides itself completely when the user is premium
- Gracefully shows nothing if the ad hasn't loaded yet
- Handles ad load failures silently

---

### Component 3: App Initialization

#### [MODIFY] [main.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/main.dart)
- Call `AdService.instance.initialize()` before `runApp()` alongside existing initialization

---

### Component 4: Banner Ad Placements

#### [MODIFY] [campaign_screen.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/lobby/screens/campaign_screen.dart)
- Add `AdBannerWidget` as a `Positioned` element at the bottom of the screen Stack (above the safe area, below the level nodes)
- Hidden for premium users

#### [MODIFY] [profile_screen.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/profile/screens/profile_screen.dart)
- Add `AdBannerWidget` at the bottom of the scrollable column

#### [MODIFY] [leaderboard_screen.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/leaderboard/screens/leaderboard_screen.dart)
- Add `AdBannerWidget` at the bottom

---

### Component 5: Interstitial Ad Placements

#### [MODIFY] [game_screen.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/game/screens/game_screen.dart)
- In the `AwesomeVictoryOverlay.onNext` callback (when player taps "Continue" after winning), call `AdService.instance.showInterstitialAd(context)` before navigating to `/lobby`
- This fires only at the natural "level complete → back to map" moment — NOT during gameplay

---

### Component 6: Rewarded Ad (Existing flow, real SDK)

#### (Part of ad_service.dart above)
The existing "Watch Ad for Revive" button in `game_screen.dart` already calls `AdService.instance.showRewardedAd(context)`. The only change is replacing the simulated dialog body with real `RewardedAd` SDK calls. No UI changes needed.

The existing "Earn Coins" path in the currency exchange overlay will also be wired up.

---

### Component 7: Economy Config Update

#### [MODIFY] [economy_config.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/core/services/economy_config.dart)
- Add `interstitialMinLevels = 3` — minimum levels between interstitial ads
- Add `interstitialMinSeconds = 300` — minimum seconds (5 min) between interstitials
- Add `maxDailyRewardedAds = 3` — cap on "Earn Coins" rewarded ads per day

---

## Verification Plan

### Automated Tests
```bash
flutter analyze
flutter test
```

### Manual Verification
1. Launch app and verify **test banner ads** appear at bottom of Campaign map, Profile, and Leaderboard screens
2. Complete a level and verify an **interstitial** fires when returning to the campaign (not during gameplay)
3. Trigger Game Over and tap "Watch Ad to Revive" — verify **rewarded ad** plays and revive is granted
4. Confirm banner/interstitial/rewarded ads are **completely hidden** for premium users
5. Confirm the interstitial does **not** fire on the 1st, 2nd level completions (only on 3rd+)

### Production Build
```bash
flutter build appbundle --release
```
Then upload to Google Play Console → Production track.

---

## Open Questions

> [!IMPORTANT]
> Please confirm or provide:
> 1. Your **AdMob App ID** and ad unit IDs (or confirm if you want to start with test IDs and wire real ones later)
> 2. Should **guest users** see ads? (Recommended: yes — they are not premium)
> 3. Should the **Lobby screen** (the quick-play screen with Solo/Multiplayer selection) also have a banner? It's a transitional screen so it's less suitable.
