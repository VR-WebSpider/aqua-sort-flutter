# Dual-Mode Password Reset & Player Portal Redesign

Implement a password reset flow that supports BOTH a 6-digit OTP (for in-app recovery) and a direct link (for Player Portal web recovery). Additionally, we will redesign the Player Portal to align seamlessly with the WebSpider Studios Hub.

## Open Questions

> [!WARNING]
> **MCP Tool Availability:** You requested that I use MCP tools for Supabase and GitHub. My current environment **does not have** Supabase or GitHub MCP servers installed. However, because the `vr-webspider.github.io` repository is locally available on your machine, I can use standard `git` terminal commands to commit and push changes directly to GitHub! For Supabase, I will generate the exact Email Templates and configurations for you to paste into your dashboard. **Is it okay if I use the standard `git` terminal instead of an MCP tool?**

> [!IMPORTANT]
> **Player Portal Redesign Preferences:** The current Player Portal uses a dark theme with green/cyan glows (`#070709` background). To redesign it to match "WebSpider Studios Hub" seamlessly, are there any specific colors, layouts, or CSS styles from `webspiderstudios.com` you want me to replicate? (e.g., changing the background, button shapes, or fonts).

## Proposed Changes

### 1. App Password Recovery Flow (`aqua-sort-flutter`)
Currently, the app lacks the UI screens to enter an OTP for password recovery. I will build these out:
- **[NEW] `forgot_password_screen.dart`**: A screen asking the user for their Email to send the recovery code.
- **[NEW] `reset_password_otp_screen.dart`**: A screen where the user enters the 6-digit OTP (`{{ .Token }}`).
- **[NEW] `change_password_screen.dart`**: A screen for the user to type their new password after verifying the OTP.
- **[MODIFY] `auth_provider.dart`**: Implement `resetPasswordForEmail()` to trigger the email, and `updateUser({ password })` to change it.
- **[MODIFY] `router.dart` / `main.dart`**: Add the new routes.

### 2. Player Portal Web Redesign (`vr-webspider.github.io`)
- **[MODIFY] `auth/index.html`**:
  - Overhaul the CSS and layout to match the WebSpider Studios Hub.
  - The `s-recovery` screen will remain intact so that if the user taps the link in the email instead of the OTP, they can seamlessly reset their password on the web.

### 3. Supabase Email Template Updates
- **[MODIFY] `email_template_guide.md`**: I will update the guide so your Password Recovery email includes **BOTH**:
  1. The large 6-digit OTP code (`{{ .Token }}`) instructing them to enter it in the app.
  2. The "Reset Password via Web" button (`{{ .ConfirmationURL }}`) taking them to the redesigned Player Portal.

## Verification Plan
1. Launch the Flutter app and navigate to "Forgot Password".
2. Enter an email and verify that an email is received containing *both* the 6-digit OTP and the Web Link.
3. **Test Path A:** Enter the 6-digit OTP inside the Flutter app and change the password.
4. **Test Path B:** Click the Web Link in the email, arrive at the newly redesigned Player Portal, and change the password.
5. Push all changes to GitHub using the `git` command line.
