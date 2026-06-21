# Walkthrough - Universal Spider Coins Economy, Game Pause, and Dynamic Tutorials

We have fully implemented the requested feature set, providing a robust game economy, game pause mechanics, and seamless, timer-synchronized tutorial dialogs.

## Features Completed

### 1. Universal Spider Coins (🕸) Economy
- **Database Schema**: Added `webspider_coins` column to the Supabase `profiles` table.
- **Cross-Engine PostgreSQL RPCs**: Created secure database RPC functions (`update_webspider_coins_v1` and `get_webspider_coins_v1`) with transactional row locking to prevent race conditions. Any game client (Unity, Unreal, Flutter, or Web) can transact Spider Coins securely via simple HTTPS POST requests.
- **Currency Exchange**: Users can exchange 50 regular coins for 10 Spider Coins.
- **Store & UI Integration**: Created a beautiful `SpiderCoinPill` widget displaying the purple/violet currency icon, and a `SpiderCoinStoreDialog` where users can buy coins, watch ads (+10 🕸), or go Premium.

### 2. Game Pause Mechanics
- **Pause HUD Button**: Added a dedicated Pause button next to the Undo button in the game HUD.
- **Gameplay Halting**: Tapping pause freezes the game countdown timer, disables board interactions, and applies a premium-feel `BackdropFilter` blur overlay over the board.
- **Economy Gates**:
  - First 2 pauses per level are free.
  - Subsequent pauses require spending 5 Spider Coins, watching a rewarded ad, or Premium status.

### 3. Dynamic Tutorials
- **Undo Tutorial**: Triggers the first time a user runs out of free undos in a level.
- **Special Level Tutorial**: Triggers at the start of the first special level (Level 5/10/etc.) to explain Mystery Tubes and hidden colors.
- **Timer Synchronization**: The countdown timer is correctly paused while tutorial dialogs or pause overlays are visible, and resumes when they are dismissed.

---

## Technical Details & Files Modified

1. **Database & API**:
   - Sped up balance sync and audit logging via PostgreSQL RPCs.
   - [wallet_service.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/core/services/wallet_service.dart): Updated client-side wallet methods to call the RPCs.
   - [auth_provider.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/auth/providers/auth_provider.dart): Added `webspiderCoins` to `AuthUser` and synced it from the database profile.
2. **State & Providers**:
   - [level_provider.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/lobby/providers/level_provider.dart): Tracks Spider Coins, `undoTutorialSeen`, and `specialLevelTutorialSeen` in `SharedPreferences` (with local guest fallback).
   - [game_provider.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/game/providers/game_provider.dart): Implemented `GameStatus.paused`, pause limit verification, tutorial pausing, and Spider Coin deductions.
3. **UI Elements**:
   - [game_screen.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/game/screens/game_screen.dart): Intercepts the start of special levels, shows `SpecialLevelTutorialDialog`, and overlays `BackdropFilter` blur when paused.
   - [spider_coin_pill.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/lobby/widgets/spider_coin_pill.dart): Displays the 🕸 icon and balance pill.
   - [spider_coin_store_dialog.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/lobby/widgets/spider_coin_store_dialog.dart): Provides ad-claiming and regular-coin exchanges.
   - [game_tutorial_dialogs.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/game/widgets/game_tutorial_dialogs.dart): Beautiful tutorial cards.
   - [pause_dialogs.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/game/widgets/pause_dialogs.dart): Pause and Pause Gate dialogs.
   - [undo_gate_sheet.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/game/widgets/undo_gate_sheet.dart): Gated with Spider Coins instead of regular coins.

---

## Verification & Build Status

### 1. Code Quality & Analysis
- Ran `flutter analyze` to ensure there are no compilation errors or structural issues.
- Removed unnecessary and unused imports across modified widgets.

### 2. Successful Compilation (Android)
- Successfully compiled the production release APK using the target Java JDK environment:
  ```powershell
  build\app\outputs\flutter-apk\app-release.apk
  ```
- Copied the output APK to the root workspace folder for easy installation and testing:
  ```powershell
  f:\.gemini\antigravity\scratch\app-release.apk
  ```
