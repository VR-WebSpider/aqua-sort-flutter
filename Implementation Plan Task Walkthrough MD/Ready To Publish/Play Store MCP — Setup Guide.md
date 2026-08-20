# Play Store MCP — Setup Guide
## Connect Google Play Developer Console to Antigravity

The `play-store-mcp` server is already installed and registered. You just need to provide your **Google Cloud service account key** to authenticate with the Play Developer API.

---

## Step 1: Create a Google Cloud Service Account

1. Go to [console.cloud.google.com](https://console.cloud.google.com)
2. Select an existing project (or create a new one, e.g. **"WebSpider Studios"**)
3. In the left menu: **APIs & Services → Library**
4. Search for **"Google Play Android Developer API"** → Click **Enable**
5. Go to **IAM & Admin → Service Accounts**
6. Click **"+ Create Service Account"**
   - Name: `play-store-mcp`
   - Description: `Antigravity Play Store MCP access`
7. Click **"Create and Continue"** (no special IAM role needed at this step)
8. Click **"Done"**
9. Click on the service account you just created
10. Go to the **"Keys"** tab → **"Add Key" → "Create new key"**
11. Choose **JSON** → Click **"Create"**
12. A `.json` file downloads to your computer

---

## Step 2: Save the Key File

> [!IMPORTANT]
> Place the downloaded JSON file at exactly this path:
> ```
> C:\Users\vivek\.gemini\play-store-service-account.json
> ```
> (Rename the file to `play-store-service-account.json`)

---

## Step 3: Grant Play Console Access

1. Open the downloaded JSON file — copy the **`client_email`** field (looks like `play-store-mcp@your-project.iam.gserviceaccount.com`)
2. Go to [play.google.com/console](https://play.google.com/console)
3. Navigate to **Users and permissions → Invite new users**
4. Enter the **service account email** you copied
5. Grant these permissions for **Aqua Sort** specifically:

| Permission | Why |
|---|---|
| ✅ View app information and download bulk reports | Read app details, reviews |
| ✅ Release to testing tracks | Deploy internal/alpha/beta releases |
| ✅ Release apps to production | Deploy production releases |
| ✅ Reply to reviews | Respond to user reviews |
| ✅ Manage store listing and pricing | Update descriptions, screenshots |
| ✅ Manage orders and subscriptions | Check IAP/subscription status |

6. Click **"Invite user"** and **"Apply"**

> [!NOTE]
> It may take up to **24 hours** for permissions to propagate to the API.

---

## Step 4: Restart Antigravity

After placing the JSON file, **restart Antigravity** to pick up the new MCP server. The `play-store` server will then be available with all these tools:

### 🚀 Publishing Tools
| Tool | What it does |
|---|---|
| `deploy_app` | Upload APK/AAB to any track |
| `promote_release` | Promote internal → beta → production |
| `get_releases` | Check current releases on any track |
| `halt_release` | Pause a staged rollout |
| `update_rollout` | Change rollout % (e.g. 10% → 50% → 100%) |
| `batch_deploy` | Deploy to multiple tracks at once |

### 📝 Store Listing Tools
| Tool | What it does |
|---|---|
| `get_listing` | Read current store title/description |
| `update_listing` | Update title, description, promo video |
| `list_all_listings` | See all language listings |

### ⭐ Review Tools
| Tool | What it does |
|---|---|
| `get_reviews` | Fetch user reviews (filter by language) |
| `reply_to_review` | Post a reply to a review |

### 💳 IAP & Subscription Tools
| Tool | What it does |
|---|---|
| `list_in_app_products` | List all coin packs |
| `get_in_app_product` | Get details on a specific IAP |
| `list_subscriptions` | List all subscription products |
| `get_subscription_status` | Verify a purchase token |
| `list_voided_purchases` | Find refunded/cancelled orders |

### 👥 Tester Management
| Tool | What it does |
|---|---|
| `get_testers` | List testers on a track |
| `update_testers` | Add/remove testers |

---

## What I Can Do Once This Is Set Up

Once you restart Antigravity with the credentials in place, I can:

- 📦 **Deploy your AAB directly to Play Console** — no manual upload needed
- 🔄 **Manage staged rollouts** — start at 10%, bump to 50%, then 100%
- ✅ **Fix the Advertising ID Declaration** — by checking and confirming your app content
- ⭐ **Reply to reviews** automatically with professional responses  
- 📊 **Check release status** on any track in real time
- 🔁 **Promote releases** through tracks in one command

> [!TIP]
> Once set up, you can say things like:
> - *"Deploy the latest AAB to the production track"*
> - *"Check what version is live on production"*
> - *"Get the last 10 reviews and reply to the 1-star ones"*
> - *"Promote from internal to beta"*
