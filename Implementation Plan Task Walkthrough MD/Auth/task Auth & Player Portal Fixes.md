# Auth & Player Portal Fixes

- `[x]` Update Player Portal `index.html` (Fix Password Reset URL logic)
- `[x]` Add debouncer to "Create Account" button in `register_screen.dart`
- `[x]` Add timer logic block to `otp_screen.dart`
- `[x]` Update `auth_provider.dart` to push phone/username to `raw_user_meta_data`
- `[x]` Standardize phone numbers to E.164 in `auth_provider.dart`
- `[x]` Refactor login query in `auth_provider.dart` for phone and username lookups
- `[x]` Add "Allow Phone Login" & "Allow Username Login" checkboxes to `register_screen.dart`
- `[x]` Enforce login method toggles in `auth_provider.dart`
- `[x]` Update email template configuration guide with new instructions for Password Reset
