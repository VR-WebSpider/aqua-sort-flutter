# Implementation Plan - Daily Reward Streak System

This plan details the design, database schema, and client implementation of the 7-Day Daily Reward Streak System. This system leverages the newly established 7-tier WebSpider Studios universal economy (Copper, Brass, Silver, Gold).

---

## 📅 Daily Reward Matrix (7-Day Track)

The rewards scale across the tiers of our universal economy, encouraging daily engagement:

| Day | Reward | Currency | Asset | Category |
|---|---|---|---|---|
| **Day 1** | 50 Copper | `copper` | `CopperCoin.png` | Common |
| **Day 2** | 100 Copper | `copper` | `CopperCoin.png` | Common |
| **Day 3** | 20 Brass | `brass` | `BrassCoin.png` | Common |
| **Day 4** | 50 Brass | `brass` | `BrassCoin.png` | Common |
| **Day 5** | 10 Silver | `silver` | `SilverCoin.png` | Uncommon |
| **Day 6** | 20 Silver | `silver` | `SilverCoin.png` | Uncommon |
| **Day 7** | 5 Gold | `gold` | `GoldCoin.png` | Rare |

---

## 🏦 Database & Backend Schema

We have successfully added the necessary tracking columns to the `profiles` table:
* `last_daily_claim_at` (`timestamp with time zone`, nullable)
* `daily_streak_count` (`integer`, default 0)

### Secure Supabase RPC Function (`claim_daily_reward_v1`)
We will deploy a PL/pgSQL function to atomically calculate and process the claim on the server:
* Checks if `now() - last_daily_claim_at < interval '24 hours'`. If true, rejects claim and returns remaining seconds.
* Checks if `now() - last_daily_claim_at >= interval '48 hours'`. If true, the streak is broken and resets to Day 1.
* Increments the streak count (loops back to Day 1 after Day 7).
* Credits the user's tiered coin balance (e.g. `webspider_copper_coins`, `webspider_gold_coins`).
* Writes an audit trail transaction (`type: 'credit'`) to `public.transactions`.
* Returns the status, new streak count, reward type, and new balance.

---

## 💻 Proposed Source Code Changes (Flutter Client)

### 1. Model & Provider Sync
#### [MODIFY] [auth_provider.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/auth/providers/auth_provider.dart)
* Add `lastDailyClaimAt` (DateTime?) and `dailyStreakCount` (int) to `AuthUser`.
* Parse these fields from the profiles table query and update the factory models.

#### [MODIFY] [wallet_service.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/core/services/wallet_service.dart)
* Add a `claimDailyReward` function calling the `claim_daily_reward_v1` RPC.

#### [MODIFY] [level_provider.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/lobby/providers/level_provider.dart)
* Add `lastDailyClaimAt` and `dailyStreakCount` to `LevelProgress`.
* Implement local claim calculation in `LevelNotifier` for guests/offline players, persisting timestamps (ISO string) and streak numbers in `SharedPreferences`.
* Add `claimDailyReward` wrapper that calls Supabase (for authenticated users) or executes the local fallback logic, then updates the provider state.

### 2. Premium User Interface
#### [NEW] [daily_reward_dialog.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/lobby/widgets/daily_reward_dialog.dart)
* A high-fidelity glassmorphic dialog with a 7-day grid showing all milestones.
* Uses custom 3D coin assets:
  - Day 1-2: `assets/webspider_coins/CopperCoin.png`
  - Day 3-4: `assets/webspider_coins/BrassCoin.png`
  - Day 5-6: `assets/webspider_coins/SilverCoin.png`
  - Day 7: `assets/webspider_coins/GoldCoin.png`
* Animates cards using `flutter_animate` (glowing border for claimable day, checklist for completed days, locked status for future days).
* Shows a countdown timer if the reward is on cooldown, or a glowing **"CLAIM REWARD"** button.

#### [MODIFY] [campaign_screen.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/lobby/screens/campaign_screen.dart)
* Check if a claim is available upon loading. If so, automatically show the `DailyRewardDialog`.

#### [MODIFY] [exchange_overlay.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/lobby/widgets/exchange_overlay.dart)
* Modify the "Daily Resonance Boost" card to open the `DailyRewardDialog` rather than granting a static 50 coins.

---

## 🧪 Verification Plan

### Automated Verification
* Run `flutter analyze` to ensure there are no syntax or type errors.

### Manual Verification
1. **Lobby Launch Trigger**: Open the lobby and verify if the Daily Reward modal pops up automatically when a claim is available.
2. **Streak Progression (Cloud)**: Log in, click "Claim", and verify that:
   - Balances update atomically in Supabase.
   - Streak updates to Day 1, then subsequent days.
   - Audit logs are written to `transactions`.
3. **Streak Progression (Guest)**: Log in as guest, click "Claim", verify local balance credits, close app, open again, and check persistence.
4. **Cooldown timer**: After claiming, verify that the dialog shows a counting-down timer (e.g. `23:59:58`) and the claim button is disabled.
5. **APK compilation**: Compile the release APK to: **[f:\.gemini\antigravity\scratch\app-release.apk](file:///f:/.gemini/antigravity/scratch/app-release.apk)**.
