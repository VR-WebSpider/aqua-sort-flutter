# Implementation Plan - Web Player Portal Supabase Integration

This plan details the changes required to connect the **Web Player Portal** (`vr-webspider.github.io`) directly to the active **Supabase** backend (`zpwwjdiwcucwfuzyuiqu`). This replaces the simulated `localStorage` database with real Supabase Auth and database operations, unifying player identities across the game client and the player portal.

---

## 🏗️ Design & Architecture

### 1. Supabase Client Integration
* Load the `@supabase/supabase-js` library from CDN (jsDelivr) inside `auth/index.html`.
* Initialize the client using:
  * **URL**: `https://zpwwjdiwcucwfuzyuiqu.supabase.co`
  * **Anon Key**: `sb_publishable_RshKP0PKYrNinhh8xcKuqA_3CjMiKhq`

### 2. Streamlined Signup & Verification
* **Create Account**: Calls `supabase.auth.signUp({ email, password })`. The optional phone number is stored in a temporary global variable (`signupPending`).
* **Verify OTP**: Calls `supabase.auth.verifyOtp({ email, token, type: 'signup' })`.
  * On success, a random player name `SpiderPlayer_[random5]` is generated.
  * Deploys a Supabase DB upsert operation to write the profile record (`id`, `display_name`, `email_lookup`, `phone`, `coins`, `owned_skins`) to the `public.profiles` table.

### 3. Multi-Identifier Login
* Resolves logins using Email, Username, or Phone:
  * **Email**: Signs in directly using `signInWithPassword({ email, password })`.
  * **Phone**: Queries `public.profiles` for `phone = identifier` to retrieve `email_lookup`, then signs in.
  * **Username**: Queries `public.profiles` for `display_name = identifier` to retrieve `email_lookup`, then signs in.
* **OTP Login**: Not natively supported by GoTrue for username/email combos in one unified API, but we can query `email_lookup` first, then call `supabase.auth.signInWithOtp({ email })`.

### 4. Real Google OAuth Integration
* Replace simulated Google picker modal with real Google OAuth:
  * Clicking "Continue with Google" invokes `supabase.auth.signInWithOAuth({ provider: 'google', options: { redirectTo: window.location.origin + '/auth/' } })`.
  * On session load/restore, if a profile's `display_name` is empty, auto-generate `SpiderPlayer_[random5]` and update the database profile row.

---

## 🛠️ Proposed Changes

### Component: Web Player Portal (`vr-webspider.github.io`)

#### [MODIFY] [auth/index.html](file:///f:/.gemini/antigravity/scratch/vr-webspider.github.io/auth/index.html)
* **Head Scripts**:
  * Import `<script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>`.
* **State / Initialization**:
  * Instantiate the `supabase` client.
  * Update `init()` to retrieve the current session (`supabase.auth.getSession()`). If logged in, fetch profile from `profiles` table and render dashboard.
* **Remove simulated Google Picker**:
  * Remove the `#google-modal` div from HTML.
  * Set `openGooglePicker()` to call `supabase.auth.signInWithOAuth({ provider: 'google' })`.
* **Signup / Verify OTP**:
  * Rewrite signup logic to trigger `supabase.auth.signUp()`.
  * Rewrite signup verification to call `supabase.auth.verifyOtp()` and insert the profile row.
* **Login Action**:
  * Implement username/phone lookups to find `email_lookup` from the database.
  * Invoke `supabase.auth.signInWithPassword()` or `supabase.auth.signInWithOtp()`.
* **Profile Edit**:
  * Save profile updates (First/Last/Display Name and Avatar URL) to `public.profiles` database.
* **Security Action**:
  * Bind password change/recovery to Supabase reset password endpoints.

---

## 🧪 Verification Plan

### Manual Verification
1. **Signup Test**: Create a new account with a real email. Receive the OTP code, verify, and confirm that a new row appears in `public.profiles` database with a `SpiderPlayer_` name.
2. **Game Client Login**: Verify that you can now log into the Aqua Sort Flutter game client using the same email/password credentials created on the website.
3. **Google Sign-In**: Click "Continue with Google" on the Web Portal. Verify it redirects to Google, returns successfully, and registers/retrieves the profile card.
