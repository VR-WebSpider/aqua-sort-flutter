# Auth Fixes & Multi-ID Login Implementation

The following plan addresses the issues with login via User ID / Phone, synchronization with Supabase's Auth Dashboard, login method toggles, and email OTP behaviors.

## User Review Required
> [!IMPORTANT]
> Please review the **Proposed Changes** below. Some UI changes (like checkboxes for login methods) will be added to the Register and Profile screens. Does the behavior described match what you want?

## Open Questions
> [!WARNING]
> **Regarding the "Blank Webpage" on Password Reset:** The email template contains a "Reset Password" button. When users click it, Supabase tries to redirect them to your website to type a new password. Since you don't have a web-version of the game, it shows a blank page. 
> *Question:* Do you want me to update the app's code to intercept that deep link so it opens the app, OR would you rather just instruct users in the email to "Open the app and type the 6-digit code" and remove the button from your Supabase Email Template settings?
> 
> **Regarding "Two OTP Emails":** Supabase only sends one OTP by default when `signUp` is called. Are you clicking "Resend" manually, or does the second email arrive at the exact same millisecond?

## Proposed Changes

### 1. Supabase User Dashboard Sync (`auth_provider.dart`)
- **Fix:** Currently, the `phone` and `username` are only saved to the public `profiles` table. They are not sent to the internal Supabase Auth system. 
- **Change:** I will modify `signUp` and `updateProfile` to push `phone` and `username` into Supabase's `raw_user_meta_data`. This will make them visible immediately in your Supabase Authentication Dashboard under the user's row.

### 2. Multi-Identifier Login Fix (`auth_provider.dart` & `login_screen.dart`)
- **Fix:** The current phone number lookup strips formatting in a way that sometimes mismatches the database. 
- **Change:** I will standardize the phone number format strictly to E.164 (e.g., `+919999999999`) before saving and looking up. 
- **Change:** I will ensure the login function correctly queries the `profiles` table to find the master email associated with the `username` or `phone` and uses the single master password to authenticate. (Old usernames will naturally be deprecated because the lookup will only find the *current* username).

### 3. Login Method Checkboxes (UI & Database)
- **Database:** Add two boolean flags to the `profiles` table: `allow_phone_login` (default: false) and `allow_username_login` (default: false).
- **Register Screen:** Add checkboxes below the phone and username fields: "Allow login with Phone" and "Allow login with Username".
- **Profile Settings Screen:** Add these toggles so users can enable/disable them later.
- **Login Logic:** When a user attempts to log in with a phone or username, the system will check these flags. If the flag is false, login will be rejected with "Login via this method is disabled in your settings."

### 4. OTP Screen Resend Logic (`otp_screen.dart`)
- **Fix:** Ensure the 60-second timer strictly blocks the "Resend" button on load to prevent accidental double-taps causing two emails.

## Verification Plan

### Automated Tests
- Run `flutter analyze` to ensure no syntax errors.

### Manual Verification
- You will need to create a new account, check the checkboxes, and verify if the Phone/Username appear in your Supabase Auth Dashboard.
- Attempt to log in using Email, Username, and Phone to verify they all share the single password.
- Attempt to change the username in the profile and verify the old one can no longer log in.
