# Aqua Sort v1.2.1+8 — Google Play Production Readiness Report

## ✅ FIXES APPLIED IN THIS SESSION

### 🔴 Critical Security Fixes (Code Changes)
| # | Issue | Status |
|---|---|---|
| 1 | **Security codes printed to console** — OTP codes from Purity Challenge and Zero Casualization were printed to logs in production, exposing them to log-reading attacks | ✅ FIXED — replaced with `assert(() { debugPrint(...) }())` (debug-only, stripped from release builds) |
| 2 | **`deleteAccount()` didn't delete data** — only called `logout()`, violating Google Play's account deletion policy | ✅ FIXED — now deletes profile & purity_challenges rows from Supabase, then calls the delete-user-account Edge Function |
| 3 | **Privacy Policy outdated** — didn't mention AdMob, Google Play Games, IAP, GDPR/CCPA, or children's privacy | ✅ FIXED — comprehensive policy updated in `register_screen.dart` and `profile_screen.dart` |
| 4 | **EULA too thin** — no mention of subscription auto-renewal, IAP refunds, or features in development | ✅ FIXED — comprehensive 12-clause EULA updated in `register_screen.dart` |
| 5 | **Version bump** — needed new version code for Play Store upload | ✅ FIXED — bumped to `1.2.1+8` in `pubspec.yaml` |

### Build Output
| Artifact | Path | Size |
|---|---|---|
| APK (for device install) | `build\app\outputs\flutter-apk\app-release.apk` | ~79 MB |
| **AAB (for Play Store upload)** | `build\app\outputs\bundle\release\app-release.aab` | ~70 MB |

---

## ⚠️ ACTIONS YOU MUST COMPLETE MANUALLY

### 1. Fix the Play Console Issue: Advertising ID Declaration
The screenshot showed this exact error blocking your submission.

**Steps:**
1. Go to Play Console → **Policy → App content**
2. Find **"Advertising ID"** section
3. Click **"Update declaration"**
4. Select: **"Yes, this app uses Advertising ID"**
5. Purpose: **Advertising** ✓, check **"Analytics"** if applicable
6. Save → this will clear the blocking issue

### 2. Get Your Real AdMob App ID & Ad Unit IDs
> [!IMPORTANT]
> Your app is currently using **Google's public test AdMob App ID** in the manifest. This is a Google Play policy violation for production apps.

**Steps:**
1. Go to [admob.google.com](https://admob.google.com)
2. Create/reactivate your Aqua Sort app in AdMob
3. Get your **App ID** (format: `ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX`)
4. Create 3 ad units: **Banner**, **Interstitial**, **Rewarded**
5. Update `android/app/src/main/AndroidManifest.xml` line 56 — replace test App ID with your real one
6. Update `lib/core/services/ad_config.dart` — fill in `_realAndroidBanner`, `_realAndroidInterstitial`, `_realAndroidRewarded`
7. Set `_forceTestIds = false` in `ad_config.dart`
8. Rebuild APK and AAB after updating

### 3. Create IAP Products in Google Play Console
The app defines 11 IAP product IDs in code. They must exist in Play Console:

**Go to:** Play Console → Monetize → Products → In-app products / Subscriptions

Create these products:
| Product ID | Type | Description |
|---|---|---|
| `com.webspider.aqua.coins.100` | Consumable | 100 Coin Pack |
| `com.webspider.aqua.coins.500` | Consumable | 500 Coin Pack |
| `com.webspider.aqua.coins.1000` | Consumable | 1000 Coin Pack |
| `com.webspider.aqua.coins.3000` | Consumable | 3000 Coin Pack |
| `com.webspider.aqua.coins.5000` | Consumable | 5000 Coin Pack |
| `com.webspider.aqua.premium.daily` | Subscription | Premium Daily |
| `com.webspider.aqua.premium.weekly` | Subscription | Premium Weekly |
| `com.webspider.aqua.premium.monthly` | Subscription | Premium Monthly |
| `com.webspider.aqua.premium.quarterly` | Subscription | Premium Quarterly |
| `com.webspider.aqua.premium.halfyearly` | Subscription | Premium 6-Month |
| `com.webspider.aqua.premium.yearly` | Subscription | Premium Annual |

### 4. Update Privacy Policy URL in Play Console
1. Update your Google Sites page with the new privacy policy text (see separate artifact)
2. In Play Console → **Store listing → Privacy Policy URL** — make sure this URL matches your updated Google Sites page

### 5. Create a Supabase Edge Function for Account Deletion
The `deleteAccount()` now calls `delete-user-account` Edge Function. You need to create this in Supabase:

```typescript
// supabase/functions/delete-user-account/index.ts
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

Deno.serve(async (req) => {
  const { user_id } = await req.json()
  const supabaseAdmin = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  )
  const { error } = await supabaseAdmin.auth.admin.deleteUser(user_id)
  if (error) return new Response(JSON.stringify({ error: error.message }), { status: 400 })
  return new Response(JSON.stringify({ success: true }), { status: 200 })
})
```

### 6. Data Safety Form in Play Console
Go to: Play Console → **Policy → Data safety**

Fill in based on data you collect:
- **Location**: No
- **Personal info**: Email address (collected, required, not shared)
- **Financial info**: No (Google Play handles payments)
- **Health & Fitness**: No
- **Messages**: No
- **App activity**: App interactions, In-app search history (optional)
- **Device IDs**: Advertising ID (collected by AdMob for ads)
- **User-generated content**: Profile avatar (optional)

---

## Play Store Submission Steps

Once AdMob IDs are updated and rebuilt:

1. Go to **Play Console → Production → Create new release**
2. Upload `build\app\outputs\bundle\release\app-release.aab` (v1.2.1+8)
3. Add release notes (see below)
4. Click **Review release** → Start **100% rollout** to Production

### Suggested Release Notes
```
Version 1.2.1 — Stability & Policy Update

• Enhanced privacy policy with full transparency on data collection
• Security improvements to account protection system  
• Improved winner/loser screens for multiplayer modes
• Screen rotation option for local split-screen multiplayer
• Animated coin reward effects
• Bug fixes for undo limit, profile reset button, and UI layout
```

---

> [!WARNING]
> Do NOT submit to production until the Advertising ID declaration is completed in Play Console — it is currently a hard blocker as shown in your screenshot.
