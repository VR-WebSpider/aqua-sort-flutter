# Walkthrough - Dynamic Universal Authentication System & Daily Reward Streak

We have successfully implemented the **Dynamic Universal Authentication System** along with the **7-day Daily Reward Streak and Cumulative Milestones** across the **WebSpider Studios Hub**.

---

## 🛡️ Dynamic Universal Auth & Identity System

### 1. Database Schema & Triggers (Supabase)
- **Table Creation (`public.purity_challenges`)**:
  - Implemented a secure database schema to hold identity challenges (`id`, `user_id`, `code`, `target_email`, `challenge_type`, `game`, `expires_at`, `created_at`).
  - Solved name collisions by migrating security challenges away from the Room-puzzle `security_challenges` table.
- **Row-Level Security (RLS)**:
  - Enabled RLS on the table and deployed the policy:
    ```sql
    CREATE POLICY "Users can manage their own purity challenges." ON public.purity_challenges
        FOR ALL USING (auth.uid() = user_id);
    ```
- **Automated DB Webhook Triggers**:
  - Deployed `send_security_challenge_email()` Postgres trigger function which makes an HTTP POST request via `net.http_post` to the Supabase Edge Function using service role authorization headers.
  - Set the `AFTER INSERT` trigger `tr_send_security_challenge_email` on the `purity_challenges` table.

### 2. Deno Edge Function (`send-security-email`)
- Upgraded Deno DRL routing in `supabase/functions/send-security-email/index.ts`.
- **Dynamic Brand Adaptation**:
  - Read `record.game` from webhook payloads.
  - Dynamically customizes sender tags (e.g. `Aqua Sort Security <security@webspiderstudios.com>` vs `Chess Royale Security`), email subject headers, and custom-styled responsive HTML layouts (themed colors, gradients, and badges).
- Deployed and activated the Edge Function on project ID `zpwwjdiwcucwfuzyuiqu`.

### 3. Flutter Client Integration
- Modified [auth_provider.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/auth/providers/auth_provider.dart) to:
  - Inject metadata `{ 'game': 'Aqua Sort' }` inside `signUp` to automatically register the player's primary game.
  - Target the new `purity_challenges` table with custom metadata in `initiatePurityChallenge`, `initiateEmailSwap`, `verifyEmailSwap`, and `verifyPurityChallenge`.
- Verified file builds locally with `flutter analyze`.

---

## 🏦 Backend Database Implementation (Daily Reward)

1. **Table Schema Migration**:
   - Added tracking columns to the `profiles` table:
     - `last_daily_claim_at` (`timestamp with time zone`, nullable)
     - `daily_streak_count` (`integer`, default 0)
     - `total_daily_claims` (`integer`, default 0)
     - `claimed_milestones` (`text[]`, default empty array)

2. **Atomic PL/pgSQL Routines**:
   - **`claim_daily_reward_v1(p_user_id)`**:
     - Calculates if 24 hours have passed since last claim.
     - Resets streak to 1 if it has been >48 hours (streak broken) or if they just completed Day 7.
     - Awards rewards based on the current day:
       - Day 1: 50 Copper, Day 2: 100 Copper, Day 3: 20 Brass, Day 4: 50 Brass, Day 5: 10 Silver, Day 6: 20 Silver, Day 7: 5 Gold.
     - Writes transaction logs to avoid constraint conflicts.
   - **`claim_milestone_reward_v1(p_user_id, p_milestone_id)`**:
     - Handles claims for cumulative milestone chests:
       - **10 Claims**: Awards **10 Jade Coins** + **5 Silver Coins**.
       - **25 Claims**: Awards **5 Diamond Coins** + **20 Silver Coins**.
       - **50 Claims**: Awards **2 Obsidian Coins** + **10 Gold Coins**.
     - Updates `claimed_milestones` array and writes audit logs.

---

## 💻 Client Integration (Daily Reward & UI Polish)

1. **Data Synchronization**:
   - Updated `AuthUser` class in [auth_provider.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/auth/providers/auth_provider.dart) to fetch, parse, and refresh all daily reward and milestone properties.
   - Added RPC bindings in [wallet_service.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/core/services/wallet_service.dart).

2. **Guest Fallback Logic**:
   - Updated `LevelNotifier` in [level_provider.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/lobby/providers/level_provider.dart) to implement daily streak cooldown calculations locally in `SharedPreferences` for guest and offline players.

3. **Premium Glassmorphic Dashboard**:
   - Created [daily_reward_dialog.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/lobby/widgets/daily_reward_dialog.dart) featuring a 7-day card grid displaying 3D coin assets, completed check glows, locked overlays, countdown timer, and claimable milestone progress chests.

4. **Lobby & Exchange Integration**:
   - Modified [campaign_screen.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/lobby/screens/campaign_screen.dart) to automatically check and trigger `DailyRewardDialog` on launch.
   - Modified [exchange_overlay.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/lobby/widgets/exchange_overlay.dart) to open the `DailyRewardDialog`.

5. **Capsule UI & Interaction Polish**:
   - Updated [currency_pill.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/lobby/widgets/currency_pill.dart) to make the entire coin capsule clickable (via an outer `GestureDetector` with `HitTestBehavior.opaque`), making the whole coin capsule open the exchange overlay.
   - Updated [campaign_screen.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/lobby/screens/campaign_screen.dart) to size the Vault capsule identically to the coin capsule (`height: 40`, `borderRadius: 24`, `borderWidth: 1.5` in purple), scaling the inner icons, images, divider, and labels.

---

## 🧪 Verification Results

1. **Analysis Verification**:
   - Ran `flutter analyze` and resolved all compile errors. Unused imports and variables were cleaned up.
2. **Build Compilation**:
   - Successfully compiled the signed release APK containing all auth systems and visual UI updates.
   - Copied binary file to: **[f:\.gemini\antigravity\scratch\app-release.apk](file:///f:/.gemini/antigravity/scratch/app-release.apk)**.
