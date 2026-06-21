# Implementation Plan - Universal Multi-Tier Currency System (WebSpider Studios)

This plan details the design, database schema, and integration of the 7-tier currency economy (Brass, Copper, Silver, Gold, Diamond, Jade, Obsidian) for WebSpider Studios games.

---

## 🎨 Visual Coin Designs (Cyberpunk/Premium Style)

We have pre-designed the coin assets incorporating the official WebSpider Studios logo (web, spider, and gamepad controller).

````carousel
![Brass Coin (Common/Actions)](file:///C:/Users/vivek/.gemini/antigravity/brain/563eb938-bac9-4c94-a1b9-1bab2f819f11/coin_brass_1782033727849.png)
<!-- slide -->
![Copper Coin (Common/Actions)](file:///C:/Users/vivek/.gemini/antigravity/brain/563eb938-bac9-4c94-a1b9-1bab2f819f11/coin_copper_1782033743700.png)
<!-- slide -->
![Silver Coin (Uncommon/Special)](file:///C:/Users/vivek/.gemini/antigravity/brain/563eb938-bac9-4c94-a1b9-1bab2f819f11/coin_silver_1782033758617.png)
<!-- slide -->
![Gold Coin (Rare/Premium-lite)](file:///C:/Users/vivek/.gemini/antigravity/brain/563eb938-bac9-4c94-a1b9-1bab2f819f11/coin_gold_1782033775167.png)
<!-- slide -->
![Diamond Coin (Premium)](file:///C:/Users/vivek/.gemini/antigravity/brain/563eb938-bac9-4c94-a1b9-1bab2f819f11/coin_diamond_1782033790776.png)
<!-- slide -->
![Jade Coin (Event/Seasonal)](file:///C:/Users/vivek/.gemini/antigravity/brain/563eb938-bac9-4c94-a1b9-1bab2f819f11/coin_jade_1782033809467.png)
<!-- slide -->
![Obsidian Coin (Elite/Exclusive)](file:///C:/Users/vivek/.gemini/antigravity/brain/563eb938-bac9-4c94-a1b9-1bab2f819f11/coin_obsidian_1782033825943.png)
````

---

## 🏦 Economic Architecture

| Currency | Material | Rarity | Primary Purpose | How to Earn / Spend |
|---|---|---|---|---|
| **Copper (🕸🟫)** | Copper | Common | Basic actions, standard level continues, basic skins | Earned by playing standard levels, swapping, or daily rewards. |
| **Brass (🕸🟨)** | Brass | Common | Hints, undo assistance, speed modifiers | Earned by level achievements, swapping. |
| **Silver (🕸🥈)** | Silver | Uncommon | Premium undos, game pauses, standard cosmetics | Earned by perfect level clears, weekly challenges. |
| **Gold (🕸🥇)** | Gold | Rare | Game pause gates, revives, premium skins | Earned by event milestones or exchanging Silver. *(Existing Spider Coins migrate here)* |
| **Diamond (🕸💎)** | Diamond | Premium | Season passes, exclusive skins, cross-game items | Purchased via App Store or earned in elite leaderboards. |
| **Jade (🕸🟢)** | Jade | Event | Guild upgrades, seasonal unlocks, event access | Earned in limited-time events or global competitions. |
| **Obsidian (🕸🖤)** | Obsidian | Elite | Ultimate cosmetics, master skins, system modifications | Earned by completing maximum-difficulty levels or extreme accomplishments. |

---

## 🛠 Database & Schema Migration

We will perform DDL schema modifications to store the new currency balances under the `profiles` table.

### 1. Column Additions (PostgreSQL)
```sql
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS webspider_brass_coins INTEGER DEFAULT 100;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS webspider_copper_coins INTEGER DEFAULT 200;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS webspider_silver_coins INTEGER DEFAULT 50;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS webspider_gold_coins INTEGER DEFAULT 10;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS webspider_diamond_coins INTEGER DEFAULT 0;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS webspider_jade_coins INTEGER DEFAULT 0;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS webspider_obsidian_coins INTEGER DEFAULT 0;
```

### 2. Backward Compatibility & Migration
```sql
-- Migrate existing Spider Coin balances (from webspider_coins column) to the new webspider_gold_coins column
UPDATE public.profiles SET webspider_gold_coins = COALESCE(webspider_coins, 10);
```

### 3. Centralized RPC Functions (Supabase)
We will create a unified transaction RPC that handles all currency types securely using table-level row locks:

#### A. Unified Transaction RPC (`update_webspider_currency_v1`)
* **Parameters**:
  - `p_user_id` (UUID): User's profile ID.
  - `p_currency_type` (TEXT): One of `'brass'`, `'copper'`, `'silver'`, `'gold'`, `'diamond'`, `'jade'`, `'obsidian'`.
  - `p_amount` (INTEGER): Positive (credit) or negative (debit).
  - `p_reason` (TEXT): Audit/transaction reason.
  - `p_game_id` (TEXT): Identifier of the client game (e.g. `'aqua_sort'`, `'lost_arrow_unity'`).
* **Implementation Details**: Uses row locking (`FOR UPDATE`) to update the specific column dynamically, performs safety validation (insufficient funds check), and inserts a record into the `transactions` table with full metadata.

#### B. Unified Fetch RPC (`get_webspider_currency_v1`)
* **Parameters**:
  - `p_user_id` (UUID): User's profile ID.
* **Returns**: A JSON object of all balances:
  `{"brass": X, "copper": Y, "silver": Z, "gold": A, "diamond": B, "jade": C, "obsidian": D}`

---

## 💻 Proposed Source Code Changes (Flutter Client)

### 1. Currency Asset Copier
- Copy the generated `.png` assets to [assets/coins/](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/assets/coins/) and register them in `pubspec.yaml`.

### 2. Core Service & Data Models
#### [MODIFY] [auth_provider.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/auth/providers/auth_provider.dart)
- Update the `AuthUser` data class to support all 7 currencies.
- Parse these currencies from the Supabase profile fetch response.

#### [MODIFY] [wallet_service.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/core/services/wallet_service.dart)
- Update `WalletService` to expose unified transactional calls to `update_webspider_currency_v1` and `get_webspider_currency_v1` RPC functions.

#### [MODIFY] [level_provider.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/lobby/providers/level_provider.dart)
- Expose the 7 balances in the local `LevelProgress` and `LevelNotifier` states.
- Maintain guest/offline play fallbacks in local `SharedPreferences` (writing/reading key `webspider_coins_<currency>`).

### 3. UI Changes & Vault Modal
#### [NEW] [webspider_vault_dialog.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/lobby/widgets/webspider_vault_dialog.dart)
- A highly polished dialog/drawer showing the user's **WebSpider Studios Vault**.
- Displays each of the 7 coins with their custom 3D image assets, name, descriptions, and current balances.
- Allows exchanges between tiers (e.g. trade Brass for Copper, or Gold for Diamond).

#### [MODIFY] [campaign_screen.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/lobby/screens/campaign_screen.dart)
- Replace the simple `SpiderCoinPill` in the header with a **Vault Button** (icon showing a cybernetic treasure chest or glowing key). Clicking this button triggers the `WebSpiderVaultDialog`.
- Display a micro-hud of the main currencies (Gold, Copper) directly next to the regular Aqua Sort coins.

#### [MODIFY] [undo_gate_sheet.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/game/widgets/undo_gate_sheet.dart) & [pause_dialogs.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/game/widgets/pause_dialogs.dart)
- Update game interactions (Undo, Pause) to display and debit the correct currency:
  - **Undo**: Gated by **Gold Coins** (5 🕸🥇) or **Copper Coins** (50 🕸🟫).
  - **Pause**: Gated by **Gold Coins** (2 🕸🥇) or **Brass Coins** (20 🕸🟨).

---

## 🧪 Verification Plan

### Automated Tests
- Execute `flutter analyze` to ensure compiler correctness.
- Validate Supabase database migrations by executing test queries.

### Manual Verification
1. **Vault Interaction**: Open the WebSpider Vault in the Lobby. Inspect all 7 coins and verify balances.
2. **Coin Exchanges**: Attempt swapping coins (e.g., Copper ➔ Gold) and verify correct debits/credits in the cloud.
3. **Gameplay Deductions**: Trigger an Undo or Pause. Verify that selecting the specific coin deducts the corresponding amount correctly.
4. **Android Build**: Re-build the APK and run a test run on a device/emulator.

---

## User Review Required

> [!IMPORTANT]
> - We will migrate the current universal `webspider_coins` balances (Spider Coins) to **Gold Coins** so that users do not lose their current progress/balance.
> - Please review the 3D coin assets in the carousel above. If you approve, click the **Proceed** button to apply the database migrations and implement the universal multi-tier economy!
