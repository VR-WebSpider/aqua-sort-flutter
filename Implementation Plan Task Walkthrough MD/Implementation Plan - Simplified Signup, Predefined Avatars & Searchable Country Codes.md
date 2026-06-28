# Implementation Plan - Simplified Signup, Predefined Avatars & Searchable Country Codes

This plan details the changes required to simplify the signup system, auto-generate unique names upon verification, add a grid selector for predefined avatars, and integrate search-enabled country code pickers for phone numbers across both the **Aqua Sort Flutter Game** and the **Web Hub Player Portal**.

---

## 🏗️ Design & Architecture

### 1. Simplified Signup Flow
Instead of asking for names, display names, and avatars during registration, players only provide:
* **Email Address**
* **Phone Number** (Optional, with search-enabled country code selector)
* **Password**
* **Confirm Password**

### 2. Auto-Generated Player Name
Once OTP verification is successful:
* The system automatically generates a unique player handle: `SpiderPlayer_[5-digit random number]` (e.g. `SpiderPlayer_48293`).
* This value is stored in the newly created database column `display_name`.
* The player is logged in and can later customize their profile.

### 3. Profile Settings & Avatars Grid
Inside the logged-in profile dashboard, players can update:
* First Name
* Last Name
* Display Name (public handle)
* Profile Photo selected from **6 premium pre-defined cartoon avatars** (displayed as a compact circular grid selector):
  1. 🕷️ WebSpider Logo
  2. 💻 Cyber Hacker
  3. 👩‍🎤 Cyborg Woman
  4. 👨‍🚀 Astronaut
  5. 🤖 Cute Robot
  6. 🥷 Shadow Ninja

### 4. Searchable Country Code Selector
* **Flutter**: Customized `CountryCodePicker` configured with an elegant search bar to allow searching by country name (e.g. "India") or code (e.g. "+91").
* **Web Portal**: Built a custom vanilla HTML/JS country code selector containing major world countries, searchable dynamically in real-time.

---

## 🛠️ Proposed Changes

### Component 1: Flutter Client (`aqua-sort-flutter`)

#### [MODIFY] [auth_provider.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/auth/providers/auth_provider.dart)
* Add `dart:math` import.
* Update `AuthUser` class to select, map, and copy `display_name` column.
* Update `verifyOtp` method to generate a random `SpiderPlayer_[random5]` name and save it to the `display_name` column on profile upsert.
* Update `updateProfile` method to write `display_name` to the Supabase database.

#### [MODIFY] [register_screen.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/auth/screens/register_screen.dart)
* Remove First Name, Last Name, Display Name, Avatar Picker, and Public/Private Toggle inputs.
* Retain Email and Phone Number fields.
* Add **Confirm Password** input field with validation matching the primary password field.
* Style the `CountryCodePicker` to use a clean search input dialog matching the dark theme.

#### [MODIFY] [profile_screen.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/profile/screens/profile_screen.dart)
* Update profile name text header to display `user.displayName` (which falls back to the auto-generated unique username) instead of always combining `firstName + lastName`.

#### [MODIFY] [profile_editor_overlay.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/profile/widgets/profile_editor_overlay.dart)
* Add a `_displayController` for editing the Display Name.
* Integrate the **6 Predefined Avatars Grid** (circular avatar buttons in a clean single-row grid) visible in editing mode.
* Add the display name text field input.
* Optimize layout to fit these elements nicely.

---

### Component 2: Web Player Portal (`vr-webspider.github.io`)

#### [MODIFY] [index.html](file:///f:/.gemini/antigravity/scratch/vr-webspider.github.io/auth/index.html)
* **Simplified Signup**: Re-structure the multi-step signup screen to a single clean view containing only Email, Phone (optional) with custom country code dropdown, Password, and Confirm Password.
* **Auto-generated Name**: Modify the OTP verification callback to generate a random unique name (e.g. `SpiderPlayer_12345`) and assign it as both `username` and `fullname` in local database storage.
* **Search-enabled Country Picker**:
  - Add a flag & dial code select button next to the phone number input.
  - Implement a country modal with a search field that filters a lists of country dial codes and flags in real-time.
* **Dashboard Profile Editor**:
  - Add a glassmorphic "Edit Profile" modal to the dashboard screen.
  - Allow editing First Name, Last Name, and Display Name.
  - Show a grid of the 6 predefined avatars to select as the profile picture.

---

## 🧪 Verification Plan

### Automated Tests
* Run `flutter analyze` inside `aqua-sort-flutter` to ensure no compile errors or missing imports.

### Manual Verification
1. Open the simplified signup form: verify that only Email, Phone, Password, and Confirm Password fields are displayed.
2. Search and select a country code in the phone input field (e.g. search "India" -> selects "+91").
3. Register and complete OTP verification: verify the user is redirected to the success screen showing an auto-generated unique name (e.g., `SpiderPlayer_84920`).
4. Visit the Profile section: click Edit, change First Name, Last Name, and Display Name, select a different avatar from the grid, and verify it updates the profile card correctly.
