# Supabase Email Templates Guide

To fix the contradiction where the user receives a 6-digit code but the Player Portal doesn't ask for it, you need to update your **Supabase Email Templates**. 

Go to your **Supabase Dashboard** → **Authentication** → **Email Templates**.

## 1. Confirm Signup Template
Keep this as is, but ensure it clearly states the 6-digit code for the app:
**Subject:** 
`Confirm your Aqua Sort account`
**Message Body:**
```html
<h2>Welcome to Aqua Sort!</h2>
<p>Your 6-digit verification code is:</p>
<h1 style="letter-spacing: 5px;">{{ .Token }}</h1>
<p>Enter this code in the app to verify your account.</p>
```

## 2. Reset Password Template
Remove the `{{ .Token }}` from this template completely. Users will click the link, and Supabase will automatically verify the token and redirect them to the Player Portal.
**Subject:** 
`Reset Your Password`
**Message Body:**
```html
<h2>Reset Password</h2>
<p>We received a request to reset your password. Click the button below to choose a new password on the Player Portal:</p>
<p>
  <a href="{{ .ConfirmationURL }}" style="display:inline-block; padding:12px 24px; background-color:#00F0FF; color:#0A1929; text-decoration:none; font-weight:bold; border-radius:8px;">
    Reset Password
  </a>
</p>
<p>If you did not request this, you can safely ignore this email.</p>
```

---

> [!TIP]
> By removing the 6-digit `{{ .Token }}` from the Reset Password email, players will no longer be confused when the website doesn't ask for it. The "Reset Password" button contains a secure link that handles verification automatically!
