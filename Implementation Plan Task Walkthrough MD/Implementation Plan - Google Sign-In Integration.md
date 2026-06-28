# Implementation Plan - Google Sign-In Integration

This plan details the changes required to integrate a Google Sign-In authentication option across both the **Aqua Sort Flutter Game** and the **Web Hub Player Portal**. It ensures that if a user is already registered with a Gmail address, signing in via Google automatically resolves and links to the same account.

---

## 🏗️ Design & Architecture

### 1. Unified Google OAuth Options
* **Flutter**: Add a "Continue with Google" button on the Login and Register screens. The button invokes the existing Supabase OAuth provider (`signInWithSocial(OAuthProvider.google)`).
* **Web Portal**: Add a "Continue with Google" button on the Sign In and Sign Up views. Implement a simulated Google Account Selection modal to mimic the OAuth flow and authenticate users.

### 2. Same-Account Automatic Linkage
* If a user is already registered under an email (e.g., `test@gmail.com`):
  * **Flutter (Supabase)**: Signing in with Google automatically maps to the existing user record in Supabase Auth (via email matching), logging the user into their existing profile.
  * **Web Portal (Mock DB)**: The Google auth flow checks if the selected Gmail address exists in the local database. If yes, it logs in as that existing user; if no, it registers them as a new user.

### 3. Automatic Unique Handle Assignment
* If a profile is newly created (e.g., first-time Google sign-in):
  * The system will detect if `display_name` is empty or null, auto-generate a unique `SpiderPlayer_[random5]` handle, and save it to the database profile.

---

## 🛠️ Proposed Changes

### Component 1: Flutter Client (`aqua-sort-flutter`)

#### [MODIFY] [auth_provider.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/auth/providers/auth_provider.dart)
* In `_fetchProfile`, check if the fetched profile has an empty or null `display_name`.
* If empty, auto-generate a `SpiderPlayer_[5-digit random number]` handle, save it to the database via Supabase update, and use it.

#### [MODIFY] [login_screen.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/auth/screens/login_screen.dart)
* Insert a visual separator (`or`) and a "Continue with Google" button (styled using `GlowButton` with outline design and `Icons.g_mobiledata` or similar icon) under the "Sign In & Play" button.
* On tap, invoke `ref.read(authProvider.notifier).signInWithSocial(OAuthProvider.google)` and navigate to `/lobby` on success.

#### [MODIFY] [register_screen.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/auth/screens/register_screen.dart)
* Insert a visual separator (`or`) and a "Continue with Google" button under the "Create Account" button.
* Bind the tap event to trigger `signInWithSocial(OAuthProvider.google)`.

---

### Component 2: Web Player Portal (`vr-webspider.github.io`)

#### [MODIFY] [index.html](file:///f:/.gemini/antigravity/scratch/vr-webspider.github.io/auth/index.html)
* **HTML UI Updates**:
  * Add a visual separator (`<div class="divider">or</div>`) and a "Continue with Google" button (`<button class="btn btn-ghost" id="google-login-btn">Continue with Google</button>`) inside the Signup card (`#s-signup-1`) and the Login card (`#s-login`).
  * Add a modal layout for the **Google Account Selector** (`#google-picker-modal`) containing options for mock Google accounts (e.g., `webspider.player@gmail.com`, `coder.test@gmail.com`) and a manual email typing option.
* **JavaScript Logic Updates**:
  * Implement `openGooglePicker()`, `closeGooglePicker()`, and `handleGoogleLogin(email)` functions.
  * In `handleGoogleLogin(email)`:
    * Check if an account with `email` already exists in `getUsers()`.
    * If it exists, log in as that user directly by writing the session and calling `renderDash()` and `show('s-dash')`.
    * If it does not exist, create a new user profile with `email`, generate `SpiderPlayer_[random5]` as `fullname` and `display_name`, set the default avatar, save it to `localStorage`, and log in.

---

## 🧪 Verification Plan

### Automated Tests
* Run `flutter analyze` inside `aqua-sort-flutter` to ensure no compile errors or warnings are introduced.

### Manual Verification
1. **Google Signup (New User)**:
   * Click "Continue with Google" on the Web Portal or Flutter client.
   * Provide a new Google account/email.
   * Verify a new profile is created with an auto-assigned `SpiderPlayer_[random5]` name.
2. **Google Login (Existing User)**:
   * Register a user with email `test@gmail.com` and password `password123`.
   * Log out, and then click "Continue with Google".
   * Authenticate/Select `test@gmail.com`.
   * Verify it logs into the existing account and retrieves the profile successfully without creating a duplicate.
