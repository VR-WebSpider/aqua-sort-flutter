# Implementation Plan - Dynamic Universal Authentication System

This plan details the architecture and step-by-step changes required to establish the dynamic, game-specific branded email notifications and secure player profile isolation under the central **WebSpider Studios Hub**.

---

## 🗺️ Workspace Map & Directory Structure

Here is a color-coded map of the files and directories inside `F:\.gemini\antigravity\scratch` relating to the authentication and email templates:

- **<span style="color:#00E5FF">🟢 aqua-sort-flutter/</span>**: The main Flutter codebase for the **Aqua Sort** game client, including auth providers, local game state, and UI.
- **<span style="color:#FFD700">🟡 chess_app/</span>**: The Flutter codebase for the **Chess Royale** game client.
- **<span style="color:#9B5DE5">🟣 auth-system/</span>**: Repository for the universal auth web interface and login hub.
- **<span style="color:#00F5D4">🔵 email_viewer.html</span>**: Interactive HTML helper utility listing subjects and body templates for the 12 dynamic Supabase emails.
- **<span style="color:#F15BB5">📄 Multi-Game Dynamic Email Branding Blueprint[2]</span>**: Detailed logic plans mapping Go-template conditions for dynamic email restyling.
- **<style="color:#F15BB5">📄 Universal Email Template Migration Plan</style>**: Styling design blueprint for dark-space themed (`#090E17`) glassmorphic emails.
- **<span style="color:#F15BB5">📄 Implementation Plan – Version-controlled Email Templates</span>**: Initial plan for Edge Function template routing.
- **<span style="color:#F15BB5">📄 WebSpider Studios Hub Branding Evolution Walkthrough</span>**: walkthough of project milestones achieved during database migration and database renaming.
- **<span style="color:#A3B18A">📁 JDK/</span> and <span style="color:#A3B18A">📁 AndroidSDK_writable/</span>**: Local compiler toolchains used to build the Android `.apk`.
- **<span style="color:#E63946">📦 app-release.apk</span>**: Compiled production-ready Android binary for Aqua Sort.

---

## 🎨 System Architecture & Data Flow

Below is the dynamic visual flow demonstrating how the shared Supabase authentication layer interacts with dynamically branded email notifications and isolated game databases:

```mermaid
graph TD
    User([Player Client]) -->|1. Sign Up / Auth Action| SupabaseAuth[Supabase Auth Server]
    User -->|2. Save Game Stats| DB[(Supabase Postgres Database)]
    
    subgraph Shared Authentication
        SupabaseAuth -->|Reads Metadata| GoTemplate{Go Template System}
        GoTemplate -->|If game == 'Aqua Sort'| AquaEmail[Aqua Sort Theme: Cyan/Blue 💧]
        GoTemplate -->|If game == 'Chess Royale'| ChessEmail[Chess Royale Theme: Regal Gold ♟️]
        GoTemplate -->|Default| WebSpiderEmail[WebSpider Central Hub Theme: Neon Violet 🕸️]
    end
    
    subgraph Data Isolation (Schemas/Tables)
        DB -->|Maps via user_id| Profiles[public.profiles <br> isolated Aqua Sort data]
        DB -->|Maps via user_id| PlayerProfiles[public.player_profiles <br> isolated Chess Royale data]
    end
    
    subgraph Custom Security Flow (Resend API)
        User -->|3. Trigger Challenge| PurityTable[public.purity_challenges]
        PurityTable -->|4. AFTER INSERT Trigger| WebhookFunc[DB Trigger Function]
        WebhookFunc -->|5. HTTP POST| EdgeFunc[send-security-email Edge Function]
        EdgeFunc -->|6. Send Dynamic Email| ResendAPI[Resend API]
        ResendAPI -->|7. Deliver Code| Mailbox[User Mailbox]
    end
```

---

## 🛠️ Proposed Changes

### 1. Database Migrations (Supabase SQL)
To resolve the name collision on the `security_challenges` table (which is currently used for game room multiplayer puzzles) and enable the security challenge mail triggers, we will deploy a dedicated `public.purity_challenges` table:

```sql
-- 1. Create a dedicated table for security codes
CREATE TABLE IF NOT EXISTS public.purity_challenges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    code TEXT NOT NULL,
    target_email TEXT NOT NULL,
    challenge_type TEXT NOT NULL,
    game TEXT NOT NULL DEFAULT 'WebSpider Studios',
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 2. Protect with RLS
ALTER TABLE public.purity_challenges ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own purity challenges." ON public.purity_challenges
    FOR ALL USING (auth.uid() = user_id);

-- 3. Create db trigger function to invoke send-security-email Edge Function
CREATE OR REPLACE FUNCTION public.send_security_challenge_email()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM net.http_post(
    url := 'https://zpwwjdiwcucwfuzyuiqu.supabase.co/functions/v1/send-security-email',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key')
    ),
    body := jsonb_build_object('record', row_to_json(NEW))
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Set trigger
DROP TRIGGER IF EXISTS tr_send_security_challenge_email ON public.purity_challenges;
CREATE TRIGGER tr_send_security_challenge_email
AFTER INSERT ON public.purity_challenges
FOR EACH ROW EXECUTE PROCEDURE public.send_security_challenge_email();
```

---

### 2. Deno Edge Function Update
#### [MODIFY] [send-security-email/index.ts](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/supabase/functions/send-security-email/index.ts)
Dynamically restyle the email sender, subject, and body text based on the calling game identity:

```typescript
// Replace lines 9 to 38 in index.ts with:
    const game = record.game || "WebSpider Studios";
    let subject = `${game} Security Challenge`;
    let html = "";

    if (record.challenge_type === 'OLD_EMAIL') {
      subject = `[${game}] 🛡️ Identity Swap Alert`;
      html = getSwapAlertTemplate(record.code, game);
    } else if (record.challenge_type === 'NEW_EMAIL') {
      subject = `[${game}] 📧 New Identity Verification`;
      html = getNewEmailTemplate(record.code, game);
    } else {
      subject = `[${game}] 🔐 Security Challenge Code`;
      html = getPurityChallengeTemplate(record.code, game);
    }

    const res = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${RESEND_API_KEY}`,
      },
      body: JSON.stringify({
        from: `${game} Security <security@webspiderstudios.com>`,
        to: [record.target_email],
        subject: subject,
        html: html,
      }),
    });
```
*Note: Update the template helpers (`getSwapAlertTemplate`, `getNewEmailTemplate`, `getPurityChallengeTemplate`) to take `game` as a parameter and output it dynamically in the HTML body.*

---

### 3. Flutter Client Update
#### [MODIFY] [auth_provider.dart (Aqua Sort)](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/auth/providers/auth_provider.dart)
- Inject metadata `'game': 'Aqua Sort'` during user registration:
  ```dart
  await _supabase.auth.signUp(
    email: email, 
    password: password,
    data: {'game': 'Aqua Sort'},
  );
  ```
- Change queries targeting the `security_challenges` table to `purity_challenges` (and include the dynamic `game` attribute):
  - In `initiatePurityChallenge()`:
    ```dart
    await _supabase.from('purity_challenges').delete().eq('user_id', user.id);
    await _supabase.from('purity_challenges').insert({
      'user_id': user.id,
      'code': challengeCode,
      'target_email': user.email,
      'challenge_type': 'PURITY_CHECK',
      'game': 'Aqua Sort',
      'expires_at': DateTime.now().add(const Duration(minutes: 10)).toIso8601String(),
    });
    ```
  - In `initiateEmailSwap(String newEmail)`:
    ```dart
    await _supabase.from('purity_challenges').insert([
      {
        'user_id': user.id,
        'code': codeA,
        'challenge_type': 'OLD_EMAIL',
        'target_email': user.email,
        'game': 'Aqua Sort',
        'expires_at': DateTime.now().add(const Duration(minutes: 15)).toIso8601String(),
      },
      {
        'user_id': user.id,
        'code': codeB,
        'challenge_type': 'NEW_EMAIL',
        'target_email': newEmail,
        'game': 'Aqua Sort',
        'expires_at': DateTime.now().add(const Duration(minutes: 15)).toIso8601String(),
      }
    ]);
    ```
  - In `verifyEmailSwap(...)` and `verifyPurityChallenge(...)`:
    Change references from `security_challenges` to `purity_challenges`.

---

## 🧪 Verification Plan

### Database & Function Deploy
1. Deploy SQL migration script using `execute_sql` tool.
2. Deploy the updated `send-security-email` Edge Function using `deploy_edge_function` tool (or via local terminal if CLI is configured).

### Automated Checks
- Run `flutter analyze` inside the project to verify that code builds correctly.

### Manual Verification
1. Register a new test user inside Aqua Sort. Verify that:
   - The user's `raw_user_meta_data` contains `game: 'Aqua Sort'`.
   - The Welcome/OTP Verification email received is branded with the **Aqua Sort** CSS theme and terminology.
2. Trigger a Purity Challenge (e.g., initiating profile change) and verify that:
   - A new row is successfully inserted into the `purity_challenges` table.
   - The DB trigger fires and invokes the Deno edge function.
   - The received code verification email is dynamically branded as **Aqua Sort** with the security code.
