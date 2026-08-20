# Tasks Checklists

## Phase 1: Combat Hub Selection Screen
- `[x]` Create `CombatHubScreen` at `combat_hub_screen.dart` with Local and Online options
- `[x]` Update routes in `app_router.dart` to add `/online-lobby` and point `/multiplayer` to `CombatHubScreen`

## Phase 2: Live Leaderboard win Overlay
- `[x]` Create `LiveLeaderboardOverlay` widget at `live_leaderboard_overlay.dart`
- `[x]` Update `game_screen.dart` to show `LiveLeaderboardOverlay` after victory celebration, playing a fanfare sound

## Phase 3: Coin Fly Animation System
- `[x]` Create `CoinFlyAnimation` particle overlay helper at `coin_fly_animation.dart`
- `[x]` Attach keys to vaults in `campaign_screen.dart`
- `[x]` Trigger coin fly animation on Daily Reward claim and milestone claim in `daily_reward_dialog.dart`
- `[x]` Trigger coin fly animation on Ad rewards in `spider_coin_store_dialog.dart`
- `[x]` Trigger coin fly animation on Currency exchanges in `webspider_vault_dialog.dart`

## Phase 4: Symmetrical Vaults & Layout Adjustments
- `[x]` Update `CurrencyPill` in `currency_pill.dart` to have a fixed size (`110x40`) and updated layout
- `[x]` Update WebSpider Vault widget in `campaign_screen.dart` to show Gold Coin only and have size `110x40`
- `[x]` Add dynamic horizontal padding to CampaignScreen header row to prevent help button overlap

## Phase 5: Verification & Push
- `[x]` Run `flutter analyze` and confirm no compile errors
- `[x]` Commit and push all changes to GitHub
