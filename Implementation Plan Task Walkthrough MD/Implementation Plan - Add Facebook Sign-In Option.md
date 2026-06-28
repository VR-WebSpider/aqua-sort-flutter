# Implementation Plan - Add Facebook Sign-In Option

We will integrate a Facebook Sign-In option alongside the existing Google Sign-In option in both the Web Player Portal and the Flutter client.

## Proposed Changes

### Component: Web Player Portal (`vr-webspider.github.io`)

#### [MODIFY] [auth/index.html](file:///f:/.gemini/antigravity/scratch/vr-webspider.github.io/auth/index.html)
1. **Sign Up Screen**:
   - Add the "Continue with Facebook" button below the "Continue with Google" button:
     ```html
     <button class="btn btn-ghost" onclick="openFacebookPicker()" style="display:flex;align-items:center;justify-content:center;gap:8px;width:100%;margin-bottom:12px;">
       <span style="font-size:1.2rem;">📘</span> Continue with Facebook
     </button>
     ```
2. **Sign In Screen**:
   - Add the "Continue with Facebook" button below the "Continue with Google" button.
3. **Facebook OAuth Handler**:
   - Add the `openFacebookPicker()` function:
     ```javascript
     function openFacebookPicker() {
       supabaseClient.auth.signInWithOAuth({
         provider: 'facebook',
         options: {
           redirectTo: window.location.origin + window.location.pathname
         }
       });
     }
     ```

---

### Component: Aqua Sort (Flutter App)

#### [MODIFY] [login_screen.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/auth/screens/login_screen.dart)
- Under the Google login `GlowButton`, add a Facebook login `GlowButton` mapped to `OAuthProvider.facebook`:
  ```dart
  const SizedBox(height: 12),
  GlowButton(
    label: 'Continue with Facebook',
    icon: Icons.facebook,
    outlined: true,
    onTap: () async {
      try {
        await ref.read(authProvider.notifier).signInWithSocial(OAuthProvider.facebook);
        if (mounted) context.go('/lobby');
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Facebook Sign-In failed: ${e.toString()}'), backgroundColor: Colors.redAccent),
          );
        }
      }
    },
  ),
  ```

#### [MODIFY] [register_screen.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/auth/screens/register_screen.dart)
- Similarly, add a Facebook sign-up `GlowButton` mapped to `OAuthProvider.facebook` under the Google button.

---

## Verification Plan

### Automated Tests
- Run `flutter analyze` inside `aqua-sort-flutter` to ensure clean compilation.

### Manual Verification
1. **UI Layout Checks**:
   - Load the Web Player Portal and verify that "Continue with Facebook" button is rendered correctly.
   - Load the Flutter App login and sign-up screens and verify the visual presence of the Facebook login buttons.
2. **OAuth Redirection Check**:
   - Click the Facebook buttons on both Web and Flutter and verify that they trigger the Supabase OAuth flow redirecting towards Facebook.
