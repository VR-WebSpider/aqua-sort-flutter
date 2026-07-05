# Implementation Plan — In-App Purchases (IAPs) & Premium Payments

Integrate the official Flutter `in_app_purchase` package to replace the existing mock checkout dialogs. This will allow players to buy real premium upgrades (non-consumable) and coin packs (consumable) using Google Play Billing (and App Store Connect if deployed to iOS).

---

## User Review Required

> [!IMPORTANT]
> **Developer Console Configurations Required:**
> In-App Purchases cannot be fully tested or run in production without configuration on the respective app stores. You will need to:
> 1. Set up a **Merchant Profile** on your Google Play Console to accept payments.
> 2. Register the following **Product IDs** under the **In-App Products** section:
>    * `webspider_premium_upgrade` (Non-consumable: $2.99)
>    * `webspider_coins_pack_100` (Consumable: $0.99)
>    * `webspider_coins_pack_500` (Consumable: $2.99)
>    * `webspider_coins_pack_1000` (Consumable: $4.99)
> 3. Upload a signed test build containing the billing permission to a Closed Testing track.

---

## Open Questions

> [!WARNING]
> Please review and clarify the following details to ensure alignment:
> 1. Do you already have a **Merchant Profile** set up on your Google Play Console?
> 2. Should we target **Regular Coins** (used for standard cosmetics/skins) or **Spider Coins** (the premium currencies like Gold, Jade, Obsidian, etc.) for the shop purchases?
> 3. Are the proposed pricing tiers ($0.99 for 100 coins, $2.99 for 500, etc.) aligned with your monetization goals?

---

## Proposed Changes

### Core Dependencies

#### [MODIFY] [pubspec.yaml](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/pubspec.yaml)
* Add the official `in_app_purchase` plugin to `dependencies`.

---

### Billing & Purchase Service Layer

#### [NEW] [iap_service.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/core/services/iap_service.dart)
* Create `IapService` as a singleton to:
  * Initialize the Google Play / App Store billing connection.
  * Listen to the `purchaseStream` globally to process transactions.
  * Verify transactions (locally or via Supabase edge functions).
  * Auto-complete transactions.
  * Provide functions to purchase specific products: `buyPremium()` and `buyCoins(String productId)`.
  * Support `restorePurchases()` for the premium upgrade.

#### [MODIFY] [main.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/main.dart)
* Initialize `IapService.instance.initialize()` at startup so it begins listening to purchases as soon as the app starts.

---

### UI & Presentation Layer

#### [MODIFY] [premium_purchase_dialog.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/profile/widgets/premium_purchase_dialog.dart)
* Replace the mock callback with `IapService.instance.buyPremium()`.
* Show a loading spinner during the purchase flow.
* Add a "Restore Purchases" button for users re-installing the app.

#### [MODIFY] [spider_coin_store_dialog.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/lobby/widgets/spider_coin_store_dialog.dart)
* Add new purchase options listing the real coin packs and prices.
* Bind the pack purchase buttons to `IapService.instance.buyCoins(productId)`.

---

## Verification Plan

### Automated Tests
* Run `flutter analyze` to ensure there are no compilation errors or deprecated API usages in the newly integrated billing codebase.

### Manual Verification
* Deploy a test version of the app to a Google Play Console **Closed Testing** track.
* Register your Gmail address under **License Testing** in the Developer Console to test purchases using a dummy test credit card (without charging real money).
