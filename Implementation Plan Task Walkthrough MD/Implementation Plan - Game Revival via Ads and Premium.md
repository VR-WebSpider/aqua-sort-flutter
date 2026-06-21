# Implementation Plan - Game Revival via Ads and Premium

This plan details the implementation of a revival option when the game timer runs out (or moves are depleted) via watching ads or upgrading to Premium. It also integrates the simulated Premium purchase flow across the game over screen and undo gate.

## User Review Required

> [!IMPORTANT]
> - **Game Over Options**: When time is up (or moves are depleted):
>   - **Non-Premium Users** will see two options:
>     1. **Watch Ad**: Watch a rewarded ad to get +30s (+5 moves) and resume the game.
>     2. **Go Premium**: Opens a Premium Purchase Dialog to buy Premium and instantly revive.
>   - **Premium Users** will see an **Instant Premium Revive** button that instantly resumes the game with +30s (+5 moves) without showing any ads.
> - **Premium Purchase Dialog**: A sleek, cyberpunk-styled dialog presenting the premium benefits (unlimited undos, instant ad-free revivals, ad-free play). Clicking "Upgrade" instantly grants Premium status and triggers confirmation feedback.
> - **Undo Gate Premium Support**: Tapping "Go Premium" on the undo gate now opens the Premium Purchase Dialog and grants an instant undo upon purchase.

## Proposed Changes

---

### 1. UI Components & Dialogs

#### [NEW] [premium_purchase_dialog.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/profile/widgets/premium_purchase_dialog.dart)
- Implement `PremiumPurchaseDialog` as a `ConsumerWidget` with a Scale & Fade entrance animation.
- Detail benefits (Unlimited Undos, Instant ad-free Revivals, Ad-free play, Cyber themes).
- Provide a simulated upgrade path invoking `ref.read(premiumProvider.notifier).setPremium(true)`.

---

### 2. Game Screen & Overlays

#### [MODIFY] [game_screen.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/game/screens/game_screen.dart)
- Import `premium_provider.dart` and `premium_purchase_dialog.dart`.
- Listen to `ref.watch(premiumProvider)`.
- Update `_buildGameOverOverlay` to conditionally render:
  - If player is Premium: A single "Premium Revive" button.
  - If player is NOT Premium: A "Watch Ad" button and a "Go Premium" button.
- Make the "Go Premium" button launch `PremiumPurchaseDialog` and revive upon successful purchase.

---

### 3. Game Providers & Logic

#### [MODIFY] [game_provider.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/game/providers/game_provider.dart)
- Import `premium_purchase_dialog.dart`.
- Pass `isPremium` from `premiumProvider` into the `UndoGateSheet` creation instead of hardcoded `false`.
- Complete the `UndoGateResult.goPremium` switch case to launch `PremiumPurchaseDialog.show(context)` and perform the undo if purchased.

---

## Verification Plan

### Automated Tests
- Verify static analysis and compile correctness:
  ```powershell
  f:\.gemini\antigravity\scratch\flutter\bin\flutter.bat analyze
  ```

### Manual Verification
1. Play the game and let the level timer run out.
2. Verify the game over overlay displays:
   - For regular users: "Watch Ad for +30s" and "Go Premium".
3. Click "Go Premium":
   - Verify the Premium Purchase Dialog opens with smooth scaling/fade animations.
   - Click "Upgrade for $2.99": verify you get Premium status, BGM continues, a success sound plays, the dialog closes, and the game instantly resumes with +30s.
4. Let the timer run out again (with Premium now active):
   - Verify that the game over overlay now shows a "Premium Revive (+30s)" button.
   - Tap "Premium Revive": verify it instantly revives you without ads.
5. Test the Undo Gate:
   - Make enough moves to exhaust free undos.
   - Verify that tapping "Go Premium" launches the Premium Purchase Dialog and grants an undo upon upgrade.
