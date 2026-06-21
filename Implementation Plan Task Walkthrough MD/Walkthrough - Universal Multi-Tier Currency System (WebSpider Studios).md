# Walkthrough - Universal Multi-Tier Currency System (WebSpider Studios)

We have successfully implemented the 7-Tier Universal WebSpider Studios Economy (Brass, Copper, Silver, Gold, Diamond, Jade, Obsidian), complete with custom 3D visual coin assets, secure cloud databases, a fully functional exchange station, and updated game gating.

## Features Completed

### 1. 7-Tier WebSpider Economy & Database
- **Database Schema**: Added 7 new columns representing the coin tiers under the public `profiles` table in Supabase.
- **Data Migration**: Migrated the legacy `webspider_coins` column to the new `webspider_gold_coins` column to preserve player progress.
- **Cross-Engine PL/pgSQL RPCs**:
  - `get_webspider_currency_v1`: Retrieves all 7 coin balances in a single unified JSON object.
  - `update_webspider_currency_v1`: Dynamically credits/debits any of the 7 coin balances securely with row-level locks and logs transaction audits. Works universally across Unity, Unreal, and Flutter.

### 2. Premium Swapping Station & Vault Dialog
- **WebSpider Vault Button**: Replaced the simple coin pill with a premium purple-gradient **Vault Button** in the main campaign header showing micro-HUDs of Gold (🕸🥇) and Copper (🕸🟫) balances.
- **Vault Dialog**: Displays all 7 tiers with their beautiful custom 128x128 3D rendering assets, rarity badges, and descriptions.
- **Swap Station**: An interactive exchange module where users can swap between tiers:
  - Coins 🪙 ➔ Copper 🕸🟫 (5:1)
  - Copper 🕸🟫 ➔ Brass 🕸🟨 (10:1)
  - Brass 🕸🟨 ➔ Silver 🕸🥈 (5:1)
  - Silver 🕸🥈 ➔ Gold 🕸🥇 (5:1)
  - Gold 🕸🥇 ➔ Diamond 🕸💎 (5:1)

### 3. Gameplay Currency Gating
- **Undo Actions**: Players can choose to spend **5 Gold Coins 🕸🥇** or **50 Copper Coins 🕸🟫** to perform an extra undo.
- **Pause Actions**: Free pauses are limited to 2. Subsequent pauses require spending **2 Gold Coins 🕸🥇** or **20 Brass Coins 🕸🟨**.

---

## Technical Details & Files Modified

1. **Database & API**:
   - Executed database migrations and routine definitions in Supabase.
   - [wallet_service.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/core/services/wallet_service.dart): Implemented `updateWebSpiderCurrency` to call the new RPC.
   - [auth_provider.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/auth/providers/auth_provider.dart): Added all 7 coin balance fields to `AuthUser` and parsed them from Supabase.
2. **State & Providers**:
   - [level_provider.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/lobby/providers/level_provider.dart): Updated `LevelProgress` and `LevelNotifier` to store, sync, and exchange all 7 balances locally and in the cloud.
   - [game_provider.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/game/providers/game_provider.dart): Updated `requestUndo` and `pauseGame` to prompt and deduct specific coin balances.
3. **UI Elements**:
   - [pubspec.yaml](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/pubspec.yaml): Registered the new assets folder `assets/webspider_coins/`.
   - [webspider_vault_dialog.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/lobby/widgets/webspider_vault_dialog.dart): Interactive 7-coin drawer showing balances, descriptions, and dropdown swapping.
   - [campaign_screen.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/lobby/screens/campaign_screen.dart): Displays the Vault entry pill in the header.
   - [undo_gate_sheet.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/game/widgets/undo_gate_sheet.dart): Modified to support Gold and Copper spend options.
   - [pause_dialogs.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/game/widgets/pause_dialogs.dart): Modified to support Gold and Brass spend options.

---

## Verification & Build Status

### 1. Code Quality & Analysis
- Ran `flutter analyze` and resolved all syntax errors, including unused imports and layout paddings.

### 2. Successful Android Compilation
- Successfully compiled the production release APK:
  ```powershell
  build\app\outputs\flutter-apk\app-release.apk
  ```
- Copied the output APK to the root workspace folder for easy installation and testing:
  * **[app-release.apk](file:///f:/.gemini/antigravity/scratch/app-release.apk)**
