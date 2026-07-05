# Google Play In-App Purchase Setup Guide

This guide details the step-by-step configuration required on your Google Play Console to enable payments, create products, set up sandbox testing, and connect secure database verification.

---

## Step 1: Set Up your Merchant Profile (Accept Payments)
Before you can sell any digital items or upgrades, Google requires a linked Merchant Account:
1. Log in to the [Google Play Console](https://play.google.com/console/).
2. On the left-hand sidebar, scroll down and go to **Settings** > **Developer Account** > **Merchant Account**.
3. Click **Set up merchant account** (or **Link a Google payments profile**).
4. Fill in your business details (individual/sole proprietor is fine), bank account info, and tax declaration.
5. Google will verify your details. Once complete, you will be able to create priced products.

---

## Step 2: Create In-App Products (Consumable & Non-Consumable)
Now, create the products corresponding to your game shop:
1. Go to the Play Console sidebar and navigate to **Monetize** > **Products** > **In-app products**.
2. Click **Create product** in the top-right corner.
3. Define the product details:
   * **Product ID**: E.g., `webspider_premium_upgrade` (This must match your Flutter code exactly).
   * **Name**: "Go Premium"
   * **Description**: "Permanently unlock ad-free gameplay, unlimited undos, and premium themes."
4. Set the **Price**:
   * Set the default USD price (e.g., `$1.99`).
   * Click **Edit local prices** to override local pricing. Scroll to **India** and set it to your desired economical price (e.g., `₹99.00`).
   * Click **Apply**.
5. Choose the product type:
   * Select **Consumable** for coin packs (which can be bought repeatedly).
   * Select **Non-consumable** for the Premium Upgrade (which is bought once).
6. Click **Save** and then click **Activate** (in-app products must be activated to show up in the app's shop).

Repeat this process for all proposed coin pack IDs:
* `webspider_coins_pack_regular`
* `webspider_coins_pack_silver`
* `webspider_coins_pack_gold`
* `webspider_coins_pack_obsidian`

---

## Step 3: Set Up License Testing (Free Sandbox Testing)
License testing allows you to run purchase transactions on your phone using dummy credit cards without spending real money:
1. In the Play Console sidebar, scroll to the bottom and click **Settings** > **License testing**.
2. Under **License testers**, add the Gmail addresses of your testers (e.g. `vivekanandrajbhar96@gmail.com`).
3. Set **License response** to `RESPOND_NORMALLY`.
4. Click **Save changes**.

---

## Step 4: Configure API Credentials for Secure Verification
To prevent players from hacking their coin balances locally, our Supabase Edge Function will verify purchase receipts directly with Google's servers:
1. Go to the [Google Cloud Console](https://console.cloud.google.com/) using the owner account of your Google Play Developer Console.
2. Ensure you have selected the Google Play Console linked project.
3. Search for and enable the **Google Play Developer API**.
4. Navigate to **IAM & Admin** > **Service Accounts**.
5. Click **Create Service Account**:
   * Name: `supabase-iap-verifier`
   * Role: **Project Reader** (or Google Play Console permission with "View Financial Data" and "Manage Orders").
6. Once created, click on the Service Account, go to the **Keys** tab, click **Add Key** > **Create New Key**, and select **JSON**.
7. Download the JSON key file.
8. We will securely configure this key in Supabase using the CLI:
   ```bash
   npx supabase secrets set GOOGLE_PLAY_SERVICE_ACCOUNT_KEY="[PASTE_JSON_KEY_CONTENT_HERE]"
   ```

---

## Step 5: Test the flow in the App
Once the setup is done:
1. Upload a release APK to the **Internal Testing** track in Google Play Console.
2. Opt-in to the internal test using the opt-in link provided by Google Play.
3. Open the app on your testing phone (logged into the license tester Gmail address).
4. Tap purchase — you will see a Google Play dialog stating *"This is a test purchase, you will not be charged."*
