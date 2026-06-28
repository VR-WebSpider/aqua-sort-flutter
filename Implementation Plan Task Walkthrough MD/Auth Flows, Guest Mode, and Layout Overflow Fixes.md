# Auth Flows, Guest Mode, and Layout Overflow Fixes

## Overview
This plan addresses several visual layout overflows, auth routing behaviors, and signup service issues reported by the user:
1. **Signup Failure Hook Error**: Resolved the `Hook requires authorization token` signup failure by creating a `supabase/config.toml` that disables JWT verification (`verify_jwt = false`) for the `send-security-email` Edge Function and deployed it.
2. **Startup welcome screen button order**: Swap the order of "Secure Login" and "Play as Guest" buttons in `splash_screen.dart`.
3. **Guest mode button mismatch**: Update the profile screen to display "Log In / Sign Up" instead of "Log Out" for guests, and fix guest status propagation in `auth_provider.dart` by checking if the session is anonymous.
4. **Purity Exchange Layout Overflows**:
   - Wrap the filter chip row inside a horizontal `SingleChildScrollView` to prevent right-overflow.
   - Constrain the header row widths by wrapping the title column in an `Expanded` and `FittedBox` widget.
   - Adjust `childAspectRatio` and visual item paddings on skin cards in the grid to prevent bottom layout overflows.

---

## Proposed Changes

### 1. Supabase Configurations — `[COMPLETED]`
#### [NEW] [config.toml](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/supabase/config.toml)
- Created `config.toml` with `verify_jwt = false` for the `send-security-email` function.
- Successfully deployed the updated configuration to the active project (`zpwwjdiwcucwfuzyuiqu`) via CLI.

### 2. Welcome Screen — `[MODIFY]`
#### [MODIFY] [splash_screen.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/auth/screens/splash_screen.dart)
- Reorder the buttons column to render the `Secure Login` button on top of the `Play as Guest` button.

### 3. Authentication Provider — `[MODIFY]`
#### [MODIFY] [auth_provider.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/auth/providers/auth_provider.dart)
- In `_fetchProfile`, check if the active user is anonymous via `_supabase.auth.currentUser?.isAnonymous ?? false`.
- If true, assign `status: AuthStatus.guest`, otherwise assign `status: AuthStatus.authenticated`.
- This ensures correct local state propagation for guests and properly triggers guest-specific UI across the app.

### 4. Profile Menu Screen — `[MODIFY]`
#### [MODIFY] [profile_screen.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/profile/screens/profile_screen.dart)
- Change the `GlowButton` label from `'Log Out'` to `auth.status == AuthStatus.guest ? 'Log In / Sign Up' : 'Log Out'`.

### 5. Purity Exchange Overlay — `[MODIFY]`
#### [MODIFY] [exchange_overlay.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/lobby/widgets/exchange_overlay.dart)
- **Header**: Wrap the title column in `Expanded` and use `FittedBox` to prevent header overflow. Reduce outer padding and text sizes slightly.
- **Filter Tabs**: Wrap the chips `Row` in a `SingleChildScrollView(scrollDirection: Axis.horizontal)` to prevent horizontal overflow on narrow screens.
- **Skins Grid**: Decrease the card visual preview height from `76` to `68` and card padding from `16` to `12`.
- Change `childAspectRatio` from `0.78` to `0.68` to allocate more height for card text and action buttons.

---

## Verification Plan

### Automated Tests
- Run `flutter analyze` to ensure zero compilation or syntax errors.
- Compile a fresh debug APK using `flutter build apk --debug`.

### Manual Verification
- Verify the splash screen layout: "Secure Login" must be above "Play as Guest".
- Verify guest mode: Tapping "Play as Guest" lands the user in the lobby. Opening the profile screen should show "Log In / Sign Up" instead of "Log Out".
- Verify Purity Exchange grid: Open the shop overlay. Verify that there are zero yellow/black overflow banners on the header, filter chips, or cards.
- Verify signup: Register a new user in the app and verify the email OTP challenge is delivered successfully.
