# Implementation Plan - Separate Username & Display Name for Security

This plan outlines the changes required to separate the **Username** (sensitive login ID, kept private) from the **Display Name** (public moniker shown to other players). This prevents other players from knowing a user's login identifier, enhancing account security.

---

## 🏗️ Design & Architecture

### 1. Database Schema Update
- Add a `username` column of type `text UNIQUE` to the `public.profiles` table.
- Initialize existing profiles' `username` to be their `display_name` lowercased and stripped of spaces.

### 2. Login Flow Updates (Web Portal & Flutter Client)
- **Web Portal**: Update identifier resolution (`resolveLoginEmail`) to look up the user's `email_lookup` using the `username` column (exact match, case-insensitive) instead of `display_name`.
- **Flutter App**: Update login lookup query to check `username` instead of `display_name` when resolving non-email identifiers.

### 3. Edit Profile Security Updates (Web Portal)
- Add a new **Username** field to the profile edit form.
- Updating the **Username** (login ID) requires OTP verification sent to the registered email address (same as Phone or Email updates).
- Display Name updates remain instant (no OTP) since it is a public-facing moniker.

---

## 🛠️ Proposed Changes

### Component: Supabase Database

#### [MIGRATION] Deployed SQL DDL
```sql
ALTER TABLE public.profiles ADD COLUMN username text UNIQUE;
UPDATE public.profiles SET username = LOWER(REPLACE(display_name, ' ', '')) WHERE username IS NULL;
```
*(This migration has already been executed successfully on project `zpwwjdiwcucwfuzyuiqu`)*

---

### Component: Web Player Portal (`vr-webspider.github.io`)

#### [MODIFY] [auth/index.html](file:///f:/.gemini/antigravity/scratch/vr-webspider.github.io/auth/index.html)
- **HTML Inputs**: Add `<div class="field" id="f-edit-username">` to `dash-edit-mode`.
- **`loadUserProfile`**: Retrieve `username`. Auto-generate it (lowercased display name) if missing.
- **`renderDash`**: Display `@username` using the `username` field instead of lowercasing the display name.
- **`resolveLoginEmail`**: Query `username` column when type is `'username'`.
- **Profile Edit Handler**: Populate the Username field, validate format (`/^[a-z0-9_]{3,20}$/`), check availability, and trigger OTP verification if changed.

---

### Component: Aqua Sort (Flutter App)

#### [MODIFY] [auth_provider.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/auth/providers/auth_provider.dart)
- **`AuthUser` Class**:
  - Add `final String username;` field and construct it.
  - Remove the legacy getter `String get username => displayName;`.
- **`_fetchProfile`**:
  - Select `username` column in the profiles fetch query.
  - Parse `username` and construct `AuthUser`. Auto-generate it if missing in the database.
- **`verifyOtp`**:
  - Insert `'username': randomName.toLowerCase()` when creating the initial profile record.
- **`login`**:
  - Change the lookup `.or('phone.eq.$identifier,display_name.eq.$identifier')` to `.or('phone.eq.$identifier,username.eq.$identifier')` to only permit logging in with the private username.

---

## 🧪 Verification Plan

### Automated Tests
- Build and run `flutter analyze` in `aqua-sort-flutter` to ensure no compile errors.

### Manual Verification
1. **SignUp Test**: Create a new account. Verify the `profiles` table contains both `username` (lowercased) and `display_name` (original case).
2. **Dashboard Test**: Open the Edit Profile screen. Modify the **Username** and click Save. Verify that an OTP email is sent and the change only applies after verification.
3. **Login Test**: Verify that you can log in using the new Username and password, but trying to log in using the public Display Name fails.
