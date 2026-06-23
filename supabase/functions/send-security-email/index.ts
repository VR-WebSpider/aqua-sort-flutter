import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY');

serve(async (req) => {
  try {
    const body = await req.json();
    
    let game = "WebSpider Studios";
    let targetEmail = "";
    let subject = "";
    let html = "";
    
    // Check if request is from Supabase GoTrue Auth Hook or custom database trigger
    if (body.email_action_type && body.user) {
      // --- CASE 1: GoTrue Send Email Hook ---
      const user = body.user;
      targetEmail = user.email;
      game = user.user_metadata?.game || "WebSpider Studios";
      const theme = getThemeColors(game);
      
      const actionType = body.email_action_type;
      const token = body.token;
      const tokenHash = body.token_hash;
      const redirectTo = body.redirect_to;
      const siteUrl = body.site_url;
      
      // Construct confirmation URL
      const confirmUrl = `${siteUrl}/auth/v1/verify?token=${tokenHash}&type=${actionType}&redirect_to=${encodeURIComponent(redirectTo)}`;
      
      if (actionType === 'signup') {
        subject = `[${game}] 💧 Alchemist Purity Verification`;
        html = getSignupOtpTemplate(token, theme);
      } else if (actionType === 'magiclink') {
        subject = `[${game}] 🚀 Instant Portal Entry`;
        html = getMagicLinkTemplate(confirmUrl, theme);
      } else if (actionType === 'recovery') {
        subject = `[${game}] 🔐 Reset Your Password`;
        html = getRecoveryTemplate(token, confirmUrl, theme);
      } else if (actionType === 'email_change') {
        subject = `[${game}] 📧 Confirm Email Change`;
        html = getEmailChangeTemplate(token, confirmUrl, theme);
      } else if (actionType === 'invite') {
        subject = `[${game}] 🧪 Summoned to the Laboratory`;
        html = getInviteTemplate(confirmUrl, theme);
      } else {
        subject = `[${game}] Secure Notification`;
        html = getGenericAuthNotificationTemplate(actionType, confirmUrl, theme);
      }
      
    } else if (body.record) {
      // --- CASE 2: Custom Purity Challenge Trigger ---
      const record = body.record;
      game = record.game || "WebSpider Studios";
      targetEmail = record.target_email;
      const theme = getThemeColors(game);
      
      if (record.challenge_type === 'OLD_EMAIL') {
        subject = `[${game}] 🛡️ Identity Swap Alert`;
        html = getSwapAlertTemplate(record.code, theme);
      } else if (record.challenge_type === 'NEW_EMAIL') {
        subject = `[${game}] 📧 New Identity Verification`;
        html = getNewEmailTemplate(record.code, theme);
      } else {
        subject = `[${game}] 🔐 Security Challenge Code`;
        html = getPurityChallengeTemplate(record.code, theme);
      }
    } else {
      return new Response(JSON.stringify({ error: "Invalid payload structure" }), { status: 400 });
    }

    // Deliver email via Resend API
    const res = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${RESEND_API_KEY}`,
      },
      body: JSON.stringify({
        from: `${game} Security <security@webspiderstudios.com>`,
        to: [targetEmail],
        subject: subject,
        html: html,
      }),
    });

    const data = await res.json();
    return new Response(JSON.stringify(data), { status: 200 });

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), { status: 500 });
  }
})

// --- Theme Helper ---
interface Theme {
  accent: string;
  bg: string;
  glow: string;
  border: string;
  badge: string;
  buttonGrad: string;
}

function getThemeColors(game: string): Theme {
  if (game === 'Chess Royale') {
    return {
      accent: '#FFD700',
      bg: '#16120E',
      glow: 'rgba(255, 215, 0, 0.08)',
      border: 'rgba(255, 215, 0, 0.25)',
      badge: '♟️ Chess Royale',
      buttonGrad: 'linear-gradient(135deg, #FFD700 0%, #FF8C00 100%)'
    };
  } else if (game === 'Aqua Sort') {
    return {
      accent: '#00E5FF',
      bg: '#0E1524',
      glow: 'rgba(0, 229, 255, 0.08)',
      border: 'rgba(0, 229, 255, 0.25)',
      badge: '💧 Aqua Sort',
      buttonGrad: 'linear-gradient(135deg, #00E5FF 0%, #0055FF 100%)'
    };
  } else {
    return {
      accent: '#9B5DE5',
      bg: '#0E0B16',
      glow: 'rgba(155, 93, 229, 0.08)',
      border: 'rgba(155, 93, 229, 0.25)',
      badge: `🕸️ ${game}`,
      buttonGrad: 'linear-gradient(135deg, #9B5DE5 0%, #F15BB5 100%)'
    };
  }
}

// --- Common Wrapper HTML ---
function getCommonWrapper(title: string, theme: Theme, contentHtml: string) {
  return `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <style>
        body { margin: 0; padding: 0; background-color: #090E17; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; color: #ffffff; }
        .wrapper { width: 100%; background-color: #090E17; padding: 40px 0; }
        .container { background-color: ${theme.bg}; border: 1px solid rgba(255, 255, 255, 0.06); max-width: 500px; margin: 0 auto; border-radius: 16px; overflow: hidden; box-shadow: 0 20px 40px rgba(0, 0, 0, 0.5); }
        .glow-bar { height: 4px; background: ${theme.buttonGrad}; width: 100%; }
        .header { padding: 40px 30px 20px 30px; text-align: center; }
        .logo-text { font-size: 13px; text-transform: uppercase; letter-spacing: 3px; color: #8A9CB8; font-weight: 700; margin-bottom: 8px; }
        .game-badge { display: inline-block; font-size: 12px; font-weight: bold; text-transform: uppercase; letter-spacing: 1.5px; padding: 5px 14px; border-radius: 20px; background: rgba(255, 255, 255, 0.05); margin-bottom: 14px; border: 1px solid rgba(255, 255, 255, 0.08); color: ${theme.accent}; }
        .headline { font-size: 24px; font-weight: 800; margin: 0; color: #FFFFFF; }
        .content { padding: 0 35px 30px 35px; text-align: center; }
        .text-body { font-size: 15px; line-height: 1.65; color: #A5B4CD; margin-bottom: 30px; }
        .otp-box { padding: 20px 35px; border-radius: 12px; display: inline-block; margin-bottom: 20px; background: ${theme.glow}; border: 1px solid ${theme.border}; }
        .otp-code { font-size: 32px; font-weight: 800; letter-spacing: 6px; font-family: monospace; color: ${theme.accent}; }
        .footer { padding: 30px 35px; text-align: center; border-top: 1px solid rgba(255, 255, 255, 0.05); }
        .footer-text { font-size: 12px; color: #5D6B82; line-height: 1.6; }
      </style>
    </head>
    <body>
      <div class="wrapper">
        <div class="container">
          <div class="glow-bar"></div>
          <div class="header">
            <div class="logo-text">WebSpider Studios</div>
            <div class="game-badge">${theme.badge}</div>
            <h1 class="headline">${title}</h1>
          </div>
          <div class="content">
            ${contentHtml}
          </div>
          <div class="footer">
            <div class="footer-text">
              &copy; 2026 WebSpider Studios.<br>
              This is an automated security communication. Do not reply.
            </div>
          </div>
        </div>
      </div>
    </body>
    </html>
  `;
}

// --- Specific Templates (Auth Hook) ---

function getSignupOtpTemplate(token: string, theme: Theme) {
  const content = `
    <p class="text-body">
      Welcome to the grid! To secure your gaming profile and activate shared cloud savings, please verify your identity by entering the following authorization code:
    </p>
    <div class="otp-box">
      <div class="otp-code">${token}</div>
    </div>
    <p class="text-body" style="font-size: 13px; color: #8A9CB8; margin-top: 10px;">
      This verification token will expire in 1 hour.
    </p>
  `;
  return getCommonWrapper("Identity Verification", theme, content);
}

function getMagicLinkTemplate(confirmUrl: string, theme: Theme) {
  const textColor = theme.accent === '#FFD700' ? '#000000' : '#FFFFFF';
  const content = `
    <p class="text-body">
      Bypass traditional password entry! Access your account instantly by clicking the portal entry key below:
    </p>
    <div style="margin: 30px 0;">
      <a href="${confirmUrl}" style="display: inline-block; font-weight: 700; text-decoration: none; padding: 16px 40px; border-radius: 30px; font-size: 15px; background: ${theme.buttonGrad}; color: ${textColor} !important; box-shadow: 0 8px 25px rgba(0, 229, 255, 0.25);">Execute Portal Entry</a>
    </div>
    <p class="text-body" style="font-size: 13px; color: #8A9CB8; margin-top: 10px;">
      If you did not request this link, you can safely ignore this email.
    </p>
  `;
  return getCommonWrapper("Instant Entry Portal", theme, content);
}

function getRecoveryTemplate(token: string, confirmUrl: string, theme: Theme) {
  const textColor = theme.accent === '#FFD700' ? '#000000' : '#FFFFFF';
  const content = `
    <p class="text-body">
      A password reset request was initiated for your profile. You can reset your password by entering the code below inside the application:
    </p>
    <div class="otp-box">
      <div class="otp-code">${token}</div>
    </div>
    <p class="text-body">
      Alternatively, you can click the button below to complete the reset procedure directly in your browser:
    </p>
    <div style="margin: 30px 0;">
      <a href="${confirmUrl}" style="display: inline-block; font-weight: 700; text-decoration: none; padding: 16px 40px; border-radius: 30px; font-size: 15px; background: ${theme.buttonGrad}; color: ${textColor} !important; box-shadow: 0 8px 25px rgba(0, 229, 255, 0.25);">Reset Password</a>
    </div>
  `;
  return getCommonWrapper("Password Reset Request", theme, content);
}

function getEmailChangeTemplate(token: string, confirmUrl: string, theme: Theme) {
  const textColor = theme.accent === '#FFD700' ? '#000000' : '#FFFFFF';
  const content = `
    <p class="text-body">
      To verify and activate your email address update, please enter the following authorization code:
    </p>
    <div class="otp-box">
      <div class="otp-code">${token}</div>
    </div>
    <p class="text-body">
      Or confirm directly by selecting the button below:
    </p>
    <div style="margin: 30px 0;">
      <a href="${confirmUrl}" style="display: inline-block; font-weight: 700; text-decoration: none; padding: 16px 40px; border-radius: 30px; font-size: 15px; background: ${theme.buttonGrad}; color: ${textColor} !important; box-shadow: 0 8px 25px rgba(0, 229, 255, 0.25);">Confirm Change</a>
    </div>
  `;
  return getCommonWrapper("Confirm Contact Change", theme, content);
}

function getInviteTemplate(confirmUrl: string, theme: Theme) {
  const textColor = theme.accent === '#FFD700' ? '#000000' : '#FFFFFF';
  const content = `
    <p class="text-body">
      You have been officially invited to join the testing network. Setup your profile credentials and initialize your player portal by selecting below:
    </p>
    <div style="margin: 30px 0;">
      <a href="${confirmUrl}" style="display: inline-block; font-weight: 700; text-decoration: none; padding: 16px 40px; border-radius: 30px; font-size: 15px; background: ${theme.buttonGrad}; color: ${textColor} !important; box-shadow: 0 8px 25px rgba(0, 229, 255, 0.25);">Accept Invitation</a>
    </div>
  `;
  return getCommonWrapper("Laboratory Invitation", theme, content);
}

function getGenericAuthNotificationTemplate(actionType: string, confirmUrl: string, theme: Theme) {
  const textColor = theme.accent === '#FFD700' ? '#000000' : '#FFFFFF';
  const content = `
    <p class="text-body">
      An action of type <span style="font-family: monospace; background: rgba(255,255,255,0.05); padding: 2px 6px; border-radius: 4px;">${actionType}</span> was executed on your profile.
    </p>
    <div style="margin: 30px 0;">
      <a href="${confirmUrl}" style="display: inline-block; font-weight: 700; text-decoration: none; padding: 16px 40px; border-radius: 30px; font-size: 15px; background: ${theme.buttonGrad}; color: ${textColor} !important; box-shadow: 0 8px 25px rgba(0, 229, 255, 0.25);">Acknowledge Action</a>
    </div>
  `;
  return getCommonWrapper("Security Alert", theme, content);
}

// --- Specific Templates (DB Trigger Custom Security) ---

function getSwapAlertTemplate(code: string, theme: Theme) {
  const content = `
    <p class="text-body">
      A change of identity (email address) was requested for your account. Enter the verification code below on your original address to authorize this action:
    </p>
    <div class="otp-box">
      <div class="otp-code">${code}</div>
    </div>
    <p class="text-body" style="font-size: 13px; color: #8A9CB8; margin-top: 10px;">
      If you did not request this, please secure your account immediately.
    </p>
  `;
  return getCommonWrapper("Identity Swap Alert", theme, content);
}

function getNewEmailTemplate(code: string, theme: Theme) {
  const content = `
    <p class="text-body">
      To verify and activate your new identity (this email address), please enter the following verification code:
    </p>
    <div class="otp-box">
      <div class="otp-code">${code}</div>
    </div>
  `;
  return getCommonWrapper("Confirm New Identity", theme, content);
}

function getPurityChallengeTemplate(code: string, theme: Theme) {
  const content = `
    <p class="text-body">
      Please verify your identity to authorize the requested profile change. Your 6-digit challenge code is:
    </p>
    <div class="otp-box">
      <div class="otp-code">${code}</div>
    </div>
  `;
  return getCommonWrapper("Security Purity Challenge", theme, content);
}
