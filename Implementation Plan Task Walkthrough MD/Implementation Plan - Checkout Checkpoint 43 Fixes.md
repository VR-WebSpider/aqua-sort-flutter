# Implementation Plan - Checkout Checkpoint 43 Fixes

This plan outlines the changes required to address the following 8 user requests and bug fixes:

1. **Fix Overflow on "+ CREATE ROOM" Button**: Add a custom height parameter to `GlowButton` and update the create room button.
2. **Move "Reset Password" Inside Profile Edit Screen Only**: Hide the Change Password option when the profile view is read-only, showing it only when the profile editor sheet enters edit mode.
3. **Restore AdMob Functionality**: Force test ads in all debug/release developer configurations so that ads always load successfully.
4. **Fix In-App Purchase (IAP) Feature**: Connect `IapService` to Riverpod to deliver purchased coins and premium status, and correct the package name mismatch.
5. **Enforce Max 2 Free Undos Limit**: Fix the game engine state propagation so `undosUsed` is preserved when tapping/deselecting tubes, ensuring the 2-undo free limit is respected.
6. **Unified Winner/Loser Screens in Combat Hub**: Redesign the victory/defeat overlays with mode-specific copy (e.g. "PLAYER X WINS!" in split-screen vs "VICTORY!"/"DEFEAT!" in single/online play).
7. **Flip Screen Option in Local Multiplayer**: Add a toggle button to each player's board in split-screen mode to rotate their view 180 degrees.
8. **Coin Reward Flow Animation**: Refine `CoinFlyAnimation` to create a smooth, continuous snake-like flow of coins along a parabolic Bezier path.

---

## Proposed Changes

### 1. Global Widgets & Button Adjustments

#### [MODIFY] [aqua_widgets.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/auth/widgets/aqua_widgets.dart)
- Add optional `final double? height;` parameter to `GlowButton`.
- Dynamically calculate `borderRadius` as `height / 2` to keep it a perfect pill shape.
- Scale down font size, icon size, and spacing if the custom height is `< 45.0`.

#### [MODIFY] [multiplayer_lobby_screen.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/lobby/screens/multiplayer_lobby_screen.dart)
- Pass `height: 38` to the `GlowButton` for `CREATE ROOM` to prevent it from overflowing the parent `SizedBox`.

---

### 2. Profile & Password Reset Security

#### [MODIFY] [profile_editor_overlay.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/profile/widgets/profile_editor_overlay.dart)
- Hide the `SECURITY` section (Change Password button) when `_isEditing` is `false`.
- Show the section only when `_isEditing` is `true`.

---

### 3. AdMob config

#### [MODIFY] [ad_config.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/core/services/ad_config.dart)
- Set `_forceTestIds = true` to ensure test ads load in both debug and release developer builds.

---

### 4. Billing & In-App Purchases (IAP)

#### [MODIFY] [iap_provider.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/core/providers/iap_provider.dart)
- Pass `ref` to the `IapService` constructor so the service can read other Riverpod state providers.

#### [MODIFY] [iap_service.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/core/services/iap_service.dart)
- Accept `Ref ref` in the constructor.
- Correct `packageName` to `'com.webspider.aquasort.mobile'` to match the actual Android `applicationId` in gradle configuration.
- Implement the missing delivery logic in `_deliverProduct`:
  - If the product is premium, call `_ref.read(premiumProvider.notifier).setPremium(true)`.
  - If the product contains coins, parse the coin count from the product ID suffix and call `_ref.read(levelProvider.notifier).awardCoins(amount, 'iap_purchase')`.

---

### 5. Game State Propagation & Undos

#### [MODIFY] [game_provider.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/game/providers/game_provider.dart)
- In `makeMove` (lines 224, 228, 241), pass `undosUsed: playerState.undosUsed` when instantiating `GameState` so the count of used undos is not lost during tube selection, deselection, or invalid target clicks.

---

### 6. Victory/Defeat Screen & Flow

#### [MODIFY] [awesome_victory_overlay.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/game/widgets/awesome_victory_overlay.dart)
- Detect local split-screen mode:
  - If `isSplitScreen` is active: Display "PLAYER 1 WINS!" or "PLAYER 2 WINS!" instead of "AWESOME!"/"DEFEAT". Disable coin rewards. Set the next CTA button to "LOBBY".
  - If it's a standard single/online game: Display "VICTORY!" or "DEFEAT!" depending on the outcome, and preserve standard coin rewards and retry flows.

---

### 7. Split-Screen Screen Flipping

#### [MODIFY] [board_widget.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/game/widgets/board_widget.dart)
- Add a local `_isFlipped` state boolean.
- Wrap the entire return tree in `RotatedBox(quarterTurns: _isFlipped ? 2 : 0, child: ...)`.
- Add a custom `_FlipButton` in the HUD row next to the undo button if `gameState.isSplitScreen` is true.

---

### 8. Coin Reward Flow Animation

#### [MODIFY] [coin_fly_animation.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/core/widgets/coin_fly_animation.dart)
- Re-architect particle generation to use a single arced control point for all coins.
- Increase particle count to 15, and reduce staggered delay to `60ms` to produce a continuous, fluid snake-like flow.
- Add rotation to each coin particle (`Transform.rotate`) during flight.

---

## Verification Plan

### Automated Tests
- Build and run the app locally using Flutter development server.
- Verify Kotlin compile and signed release APK build output.

### Manual Verification
- **Create Room Button**: Verify "+ CREATE ROOM" is visible and height is 38px without clipping text or icon.
- **Change Password Option**: Verify Change Password is hidden when viewing the profile sheet, but appears when clicking "Edit My Profile".
- **AdMob**: Verify banner/interstitial/rewarded ads load correctly with test IDs.
- **IAP**: Verify that purchasing items via sandbox successfully credits coins/premium status.
- **Undos**: Verify that after using 2 undos, subsequent undos require payment/ad/premium and that selecting/deselecting tubes doesn't reset this limit.
- **Victory Overlay**: Verify win/loss messages and options in both online/offline single-player and local split-screen modes.
- **Screen Rotation**: Verify each player in local split screen can individually rotate their screen 180 degrees.
- **Coin Animation**: Verify coin collection triggers a snake-like stream of flying coins arcing gracefully to the target.
