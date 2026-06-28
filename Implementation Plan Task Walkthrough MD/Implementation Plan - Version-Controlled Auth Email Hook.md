# Implementation Plan - Version-Controlled Auth Email Hook

This plan details the changes required to move your email templates entirely to your GitHub repository and configure Supabase Auth to route all verification emails through your Deno Edge Function using Supabase's **Send Email Auth Hook**.

---

## 🏗️ Architectural Overview

By moving templates to GitHub and using Auth Hooks, we eliminate manual copy-pasting. Here is the new data flow:

```mermaid
graph TD
    User([Player Client]) -->|1. Sign Up / Login / Reset| SupaAuth[Supabase Auth Server]
    
    subgraph Supabase Cloud
        SupaAuth -->|2. Intercepts Email Event| EmailHook{{Send Email Hook}}
        EmailHook -->|3. HTTP POST Payload| EdgeFunc[send-security-email Edge Function]
    end
    
    subgraph Deno Edge Function (Git / GitHub)
        EdgeFunc -->|4. Reads Game Metadata| ThemeEngine[Theme & Color Engine]
        ThemeEngine -->|5. Compiles HTML Template| ResendAPI[Resend API Gateway]
    end
    
    ResendAPI -->|6. Sends beautifully branded email| Mailbox([Player Inbox])
```

---

## 🛠️ Proposed Changes

### 1. Update Deno Edge Function
We will update the existing `send-security-email` Edge Function to handle two types of incoming HTTP POST requests:
1. **Custom Purity Challenges**: Requests containing a `record` field (triggered by PostgreSQL table inserts).
2. **GoTrue Auth Hook Events**: Requests containing a `user` and `email_action_type` field (triggered by Supabase Auth).

#### [MODIFY] [index.ts](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/supabase/functions/send-security-email/index.ts)
The function will:
* Check the request payload for `email_action_type` (which indicates GoTrue is calling it).
* Dynamically resolve the game name from the user's metadata (`user.user_metadata.game`).
* Render custom branded email templates for:
  - `signup` (Registration OTP)
  - `magiclink` (Passwordless Login link)
  - `recovery` (Reset password code/link)
  - `email_change` (Email change token)
  - `invite` (User invitations)
* Deliver the email using the Resend API.

---

## 📋 Supabase Dashboard Configuration Steps

Once the Edge Function is deployed, you will configure it in the Supabase Dashboard:

1. Navigate to **Authentication > Hooks** in your Supabase Dashboard.
2. Select **Send Email** hook.
3. Change the toggle to **Enabled**.
4. Choose **HTTPS** as the hook type.
5. Set the endpoint URL to:
   `https://zpwwjdiwcucwfuzyuiqu.supabase.co/functions/v1/send-security-email`
6. Click **Generate Secret** (save this secret in your Supabase Vault or as Deno environment variable `SEND_EMAIL_HOOK_SECRET` for signature verification).
7. Save the settings.

---

## 🧪 Verification Plan

### Automated Tests
* We will verify the Edge Function compiles cleanly by running `supabase functions serve` locally.

### Manual Verification
1. Register a new account in **Aqua Sort**.
2. Verify that:
   - Supabase Auth intercepts the signup and routes it to the Edge Function.
   - An email is received containing the **6-digit OTP code** beautifully styled in Aqua Sort cyan branding.
   - No default plain text magic links are sent.
3. Test a password recovery request and verify that the recovery code/link is received with matching branding.
