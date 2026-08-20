# Implementation Plan - Combat Hub, Live Leaderboard & Coin Animations

We will implement a central Combat Hub selection screen, a real-time live leaderboard overlay upon level completion, a flying coin particle animation system, and responsive adjustments to the lobby vault widgets.

## Proposed Changes

### 1. Routing & Combat Hub Screen
* Create a new selection screen: `CombatHubScreen` at `/multiplayer`.
* Move the online matchmaking lobby/presence screen to `/online-lobby`.
* Update GoRouter configuration to wire up the new screen flow.

#### [NEW] [combat_hub_screen.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/lobby/screens/combat_hub_screen.dart)
* Displays options for:
  1. **Local Multiplayer**: A card with difficulty chips (Easy, Medium, Hard, Expert) and a "Start Duel" button. When clicked, launches local 2-player split-screen gameplay (`GameArgs` with `playerCount: 2`, `isOnline: false`).
  2. **Online Multiplayer**: A card that redirects players to the matchmaking lobby (`/online-lobby`). Automatically intercepts guest users and displays the login/registration required overlay.

#### [MODIFY] [app_router.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/core/router/app_router.dart)
* Map `/multiplayer` route to `CombatHubScreen`.
* Map `/online-lobby` route to `MultiplayerLobbyScreen`.

---

### 2. Live Leaderboard Overlay on Level Win
* Integrate a live leaderboard rank list overlay shown after a level is won.

#### [NEW] [live_leaderboard_overlay.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/game/widgets/live_leaderboard_overlay.dart)
* Implements a beautiful, blurred glassmorphic overlay containing:
  * "LIVE RANKINGS" title with a green blinking online indicator.
  * A list of the top 10 scores from `leaderboardStreamProvider` (real-time Supabase connection).
  * Auto-highlights the current player's score entry and ranking.
  * A prominent "CONTINUE" button that executes the exit/ad sequence.
  * Plays `AudioService.instance.playMiniCelebration()` upon mounting (the sound effect).

#### [MODIFY] [game_screen.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/game/screens/game_screen.dart)
* Introduce `_showLiveLeaderboard` state.
* When `AwesomeVictoryOverlay` completes (i.e. user clicks "NEXT"), instead of returning immediately to the lobby, set `_showLiveLeaderboard = true` and show the `LiveLeaderboardOverlay`.

---

### 3. Flying Coin Animation System
* Implement a particle system using Flutter's `Overlay` to animate coins flying from a source position to the vault badges at the top of the screen.

#### [NEW] [coin_fly_animation.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/core/widgets/coin_fly_animation.dart)
* Defines global keys `normalCoinKey` and `webspiderCoinKey` to dynamically locate vault positions on any screen size.
* Spawns 10 coin particles that:
  1. Scatter outwards in random directions (explosive start phase).
  2. Curve towards the target vault using a Quadratic Bezier path.
  3. Scale up initially, then scale down and fade out as they reach the target.
* Bypasses blank frames by removing the overlay entry automatically when complete.

#### [MODIFY] [daily_reward_dialog.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/lobby/widgets/daily_reward_dialog.dart)
* Trigger `CoinFlyAnimation.play` when the user clicks "COSMIC EXCELLENT" to close the daily reward dialog, using the specific earned coin type.
* Trigger multiple staggered animations when a milestone chest is claimed.

#### [MODIFY] [spider_coin_store_dialog.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/lobby/widgets/spider_coin_store_dialog.dart)
* Trigger `CoinFlyAnimation.play` when the user successfully claims gold coins from a rewarded ad or does a currency exchange.

#### [MODIFY] [webspider_vault_dialog.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/lobby/widgets/webspider_vault_dialog.dart)
* Trigger the flying coin animation when a user swaps regular coins or lower-tier currencies for higher-tier WebSpider coins.

---

### 4. Symmetrical Vault Badges & Responsive Layout
* Address the spacing bug where the help button overlays or touches the yellow coin vault on smaller screen sizes.

#### [MODIFY] [currency_pill.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/lobby/widgets/currency_pill.dart)
* Set a fixed width of `110px` and height of `40px` to match the WebSpider Vault layout.
* Adjust internal layout to `MainAxisAlignment.spaceBetween` for a uniform look.

#### [MODIFY] [campaign_screen.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/lobby/screens/campaign_screen.dart)
* Redesign the WebSpider Vault badge to be symmetrical to the yellow coin vault:
  * Width: `110px`, Height: `40px`.
  * Shows Gold Coin icon + Gold Coin amount on the left, and a circular key icon action button on the right.
  * Attach the `CoinFlyAnimation` global keys to both badges.
* Make horizontal padding in the header row dynamic based on screen width (`10px` for `< 380px` widths, `22px` otherwise) to prevent touching.

## Verification Plan

### Automated Tests
* Run `flutter analyze` to ensure code compiles cleanly.

### Manual Verification
1. Click the **Combat Hub** (radar icon) on the home screen. Verify that the new selection screen appears showing "Local Multiplayer" and "Online Multiplayer".
2. Select a difficulty (e.g. Medium) in Local Multiplayer and click **Start Duel**. Verify a local 2-player split-screen game starts.
3. Click **Online Multiplayer**. Verify guest check triggers or it opens the online matchmaking room list.
4. Win a level in single-player or multiplayer mode.
   * Verify the celebration screen appears.
   * Click **Next** on the victory card. Verify the **Live Leaderboard Overlay** appears and plays a short fanfare sound.
   * Verify your rank and score are highlighted in the rankings list.
   * Click **Continue** on the leaderboard to return to the map.
5. Open **Daily Rewards** or watch an ad to earn coins:
   * Verify that coin particles burst from the reward dialog and fly along a curved path directly to the vault badge at the top.
6. Verify that the help button and vaults never touch on simulated smaller screen sizes (e.g. iPhone SE, small Android devices).
