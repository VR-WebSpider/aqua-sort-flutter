# Implementation Plan - Universal Spider Coins Economy, Game Pause, and Dynamic Tutorials

This plan details the design and implementation of:
1. **Universal Spider Coins (🕸)**: A premium-lite cross-game currency used to buy undos/pauses. Can be acquired by watching ads or exchanging regular coins.
2. **Game Pause Button**: Enables users to pause the game (which freezes the countdown timer and disables moves). The first 2 pauses per level are free, and subsequent pauses require Spider Coins, watching ads, or going Premium.
3. **Tutorial Panels**:
   - **Undo Tutorial**: Triggers when a user runs out of free undos for the first time.
   - **Special Level Tutorial**: Triggers at the start of the first special level (Level 5).
   - **Timer Synchronization**: The game timer pauses when these tutorials (or any pause overlay) are visible, and resumes when they are dismissed.

---

## Proposed Changes

### 1. Database Schema Extension (Already Completed)
- Added `webspider_coins` column to the Supabase `profiles` table to allow cloud synchronization of Spider Coins.

---

### 2. Core Service & Data Models

#### [MODIFY] [wallet_service.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/core/services/wallet_service.dart)
- Implement `awardWebSpiderCoins` method to credit/deduct Spider Coins in the cloud database for authenticated users.

#### [MODIFY] [auth_provider.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/auth/providers/auth_provider.dart)
- Extend `AuthUser` data class to include `webspiderCoins`.
- Parse the `webspider_coins` column in `_fetchProfile` and update the wallet refresh method to synchronize it.

---

### 3. Game State & Economy

#### [MODIFY] [level_provider.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/lobby/providers/level_provider.dart)
- Extend `LevelProgress` to include:
  - `spiderCoins` balance.
  - `undoTutorialSeen` flag.
  - `specialLevelTutorialSeen` flag.
- Read/write these new values to `SharedPreferences` (providing a local fallback for offline/guest play, which allows other WebSpider Studio games to share the key on the same device).
- Implement methods:
  - `awardSpiderCoins(int amount, String reason)`: Credits or spends Spider Coins locally and in the cloud.
  - `exchangeCoinsForSpiderCoins(int regularCoinsAmount)`: Deducts regular coins (e.g. 50 🪙) and awards Spider Coins (e.g. 10 🕸).
  - `markUndoTutorialSeen()`, `markSpecialLevelTutorialSeen()`.

#### [MODIFY] [game_provider.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/game/providers/game_provider.dart)
- Add `paused` state to the `GameStatus` enum: `enum GameStatus { waiting, starting, playing, paused, finished }`.
- Extend `MultiGameState` to include `pausesUsed`.
- Implement methods in `GameNotifier`:
  - `pauseGame(BuildContext context)`: Sets status to `paused` (stopping the tick timer and blocking interaction). Handles the pause limit:
    - If `pausesUsed < 2` or `isPremium`: Pause is free.
    - If `pausesUsed >= 2` (not Premium): Shows a bottom sheet / dialog asking to spend 5 Spider Coins, watch an ad, or go Premium.
  - `resumeGame()`: Restores status to `playing` (resuming the tick timer).
  - `pauseForTutorial()` and `resumeFromTutorial()` to temporarily halt/resume gameplay.
- Modify `requestUndo`:
  - Check if the user is out of free undos for the first time (`!playerState.canFreeUndo && !isPremium && !progress.undoTutorialSeen`).
  - If so, trigger the Undo Tutorial first, then show the updated `UndoGateSheet` (which charges 5 Spider Coins instead of 30 regular coins).

---

### 4. UI Elements & Widgets

#### [NEW] [spider_coin_pill.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/lobby/widgets/spider_coin_pill.dart)
- Create a reusable, premium-themed purple/violet currency pill widget displaying the 🕸 Spider Coin icon and balance, matching the style of the regular `CurrencyPill`.

#### [NEW] [spider_coin_store_dialog.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/lobby/widgets/spider_coin_store_dialog.dart)
- A modal dialog offering packages/acquisitions of Spider Coins:
  - Watch Ad (+10 🕸)
  - Exchange 50 🪙 ➔ 10 🕸
  - Go Premium (Unlimited/Instant access)

#### [NEW] [game_tutorial_dialogs.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/game/widgets/game_tutorial_dialogs.dart)
- Design beautiful cyberpunk tutorial cards with transparent, blurred backgrounds:
  - **Undo Tutorial Dialog**: Explains free vs premium undo limits, Spider Coins, and Premium benefits.
  - **Special Level Tutorial Dialog**: Explains mystery tubes and hidden color layers.

#### [NEW] [pause_dialogs.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/game/widgets/pause_dialogs.dart)
- **Pause Dialog**: Shown when game is successfully paused. Displays "GAME PAUSED", "Free pauses used: X/2", and a prominent "RESUME" button.
- **Pause Gate Dialog**: Shown when trying to pause after 2 free pauses. Offers options:
  - Pay 5 Spider Coins
  - Watch a sponsored ad to pause
  - Go Premium

#### [MODIFY] [undo_gate_sheet.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/game/widgets/undo_gate_sheet.dart)
- Update the sheet to check and display the **Spider Coins** balance.
- Option 1 becomes: "Use 5 Spider Coins" instead of "Use 30 regular coins". If the user doesn't have enough Spider Coins, display a quick option to exchange regular coins or watch an ad to get some.

#### [MODIFY] [board_widget.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/game/widgets/board_widget.dart)
- Integrate a **Pause Button** in the HUD (next to the Undo Button).
- Tapping the Pause Button invokes `ref.read(gameProvider.notifier).pauseGame(context)`.

#### [MODIFY] [campaign_screen.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/lobby/screens/campaign_screen.dart)
- Add the `SpiderCoinPill` next to the regular `CurrencyPill` in the safe area header so both balances are visible.

#### [MODIFY] [game_screen.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/game/screens/game_screen.dart)
- On build, if the level is a special level (Level 5) and the tutorial hasn't been seen yet, trigger the Special Level Tutorial immediately and pause the game status.
- Support rendering a paused overlay/dialog on top of the board when `state.status == GameStatus.paused`.

---

## Verification Plan

### Automated Checks
- Validate that the project builds correctly after schema & UI modifications:
  ```powershell
  f:\.gemini\antigravity\scratch\flutter\bin\flutter.bat analyze
  ```

### Manual Verification
1. **Lobby & Store**: Verify that both the regular coin pill and the new purple Spider Coin pill appear in the campaign screen. Test exchanging regular coins for Spider Coins.
2. **Game Pause**:
   - Start a level. Tap the Pause button. Verify that the timer halts and you cannot interact with the tubes. Tap Resume to check that it resumes.
   - Pause a second time (should be free).
   - Try to pause a third time. Check that the Pause Gate shows up. Watch an ad or pay 5 Spider Coins to pause again.
3. **Special Level Tutorial**:
   - Advance to or start Level 5 (first special level). Verify that the Special Level Tutorial appears immediately, the game timer is paused in the background, and closing the tutorial resumes it.
4. **Undo Tutorial & Gate**:
   - Make some moves. Perform 2 free undos.
   - Try to perform a 3rd undo. Verify that the Undo Tutorial shows up first. After closing it, verify that the Undo Gate sheet asks for 5 Spider Coins.
