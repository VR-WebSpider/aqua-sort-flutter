# Auth Fixes & Multi-ID Login Implementation

The following plan addresses the issues with login via User ID / Phone, synchronization with Supabase's Auth Dashboard, login method toggles, and email OTP behaviors.

## User Review Required
> [!IMPORTANT]
> Please review the **Proposed Changes** below. Some UI changes (like checkboxes for login methods) will be added to the Register and Profile screens. Does the behavior described match what you want?

## Open Questions
> [!WARNING]
> **Regarding "Two OTP Emails":** If they arrive at the exact same millisecond, this is usually caused by the Flutter button registering a "double-tap" before the loading state activates. I will add a strict debouncer/lock to the "Create Account" button in the app to prevent this from ever happening. If it STILL happens after that, it means there is a rogue database trigger in your Supabase backend sending a duplicate.

## Proposed Changes

### 1. Fix Player Portal (`vr-webspider.github.io/auth/index.html`)
- **Fix Contradiction:** The password reset email provides a 6-digit code, but when users click the reset link, the portal takes them straight to a "New Password" screen without ever asking for the code (because Supabase handles the token in the URL). This is confusing. 
- **Change:** I will update the email template configuration instructions so you can remove the confusing 6-digit code from the "Reset Password" email, making it clear they just need to click the button. I will also make sure the Player Portal correctly routes the `type=recovery` hash to the `s-recovery` screen cleanly.

### 2. Supabase User Dashboard Sync (`auth_provider.dart`)
- **Fix:** Currently, the `phone` and `username` are only saved to the public `profiles` table. They are not sent to the internal Supabase Auth system. 
- **Change:** I will modify `signUp` and `updateProfile` to push `phone` and `username` into Supabase's `raw_user_meta_data`. This will make them visible immediately in your Supabase Authentication Dashboard under the user's row.

### 3. Multi-Identifier Login Fix (`auth_provider.dart` & `login_screen.dart`)
- **Fix:** The current phone number lookup strips formatting in a way that sometimes mismatches the database. 
- **Change:** I will standardize the phone number format strictly to E.164 (e.g., `+919999999999`) before saving and looking up. 
- **Change:** I will ensure the login function correctly queries the `profiles` table to find the master email associated with the `username` or `phone` and uses the single master password to authenticate. (Old usernames will naturally be deprecated because the lookup will only find the *current* username).

### 4. Login Method Checkboxes (UI & Database)
- **Database:** Add two boolean flags to the `profiles` table: `allow_phone_login` (default: false) and `allow_username_login` (default: false).
- **Register Screen:** Add checkboxes below the phone and username fields: "Allow login with Phone" and "Allow login with Username".
- **Profile Settings Screen:** Add these toggles so users can enable/disable them later.
- **Login Logic:** When a user attempts to log in with a phone or username, the system will check these flags. If the flag is false, login will be rejected with "Login via this method is disabled in your settings."

### 5. OTP Screen Resend Logic (`otp_screen.dart`) & Double Email Fix (`register_screen.dart`)
- **Fix:** Ensure the 60-second timer strictly blocks the "Resend" button on load to prevent accidental double-taps.
- **Fix:** Add a strict lock to the "Create Account" button to ensure only one `signUp` request can fire, preventing duplicate emails on the exact same millisecond.

## Verification Plan

### Automated Tests
- Run `flutter analyze` to ensure no syntax errors.

### Manual Verification
- You will need to create a new account, check the checkboxes, and verify if the Phone/Username appear in your Supabase Auth Dashboard.
- Attempt to log in using Email, Username, and Phone to verify they all share the single password.
- Attempt to change the username in the profile and verify the old one can no longer log in.
