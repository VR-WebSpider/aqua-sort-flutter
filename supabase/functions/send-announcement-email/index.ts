import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY');
const SUPABASE_URL = Deno.env.get('SUPABASE_URL');
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

serve(async (req) => {
  try {
    const { record } = await req.json();
    
    // Check if send_email is true
    if (!record || !record.send_email) {
      return new Response(JSON.stringify({ message: "Skipping email: send_email is false" }), { status: 200 });
    }

    const title = record.title;
    const content = record.content;
    const imageUrl = record.image_url;

    // Extract coupon code if present
    const couponMatch = RegExp(/\[COUPON:\s*([A-Z0-9_]+)\]/i).exec(content);
    const couponCode = couponMatch ? couponMatch[1] : null;
    const cleanContent = content.replace(/\[COUPON:\s*[A-Z0-9_]+\]/i, '').trim();

    console.log(`Sending announcement email: ${title}`);

    // Fetch all user emails from the profiles table
    const profilesRes = await fetch(`${SUPABASE_URL.replace(/\/$/, '')}/rest/v1/profiles?select=email_lookup`, {
      headers: {
        'apikey': SUPABASE_SERVICE_ROLE_KEY,
        'Authorization': `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
      }
    });
    
    if (!profilesRes.ok) {
      throw new Error(`Failed to fetch profiles: ${await profilesRes.text()}`);
    }

    const profiles = await profilesRes.json();
    const emails = Array.from(new Set(
      profiles
        .map((p: any) => p.email_lookup)
        .filter((email: any) => email && email.includes('@'))
    )) as string[];

    if (emails.length === 0) {
      return new Response(JSON.stringify({ message: "No email contacts found to notify" }), { status: 200 });
    }

    console.log(`Found ${emails.length} email contacts. Delivering...`);

    // Prepare email HTML using the WebSpider themed design
    const emailHtml = `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <style>
          body { font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; background-color: #021829; color: #ffffff; padding: 20px; margin: 0; }
          .card { background-color: #032138; border: 1px solid #00D4E8; border-radius: 16px; padding: 30px; max-width: 600px; margin: 0 auto; box-shadow: 0 8px 32px rgba(0, 212, 232, 0.15); }
          .title { color: #00D4E8; font-size: 24px; font-weight: bold; margin-bottom: 20px; text-align: center; }
          .body { font-size: 15px; line-height: 1.6; color: #e2e8f0; margin-bottom: 25px; }
          .banner { width: 100%; border-radius: 8px; margin-bottom: 20px; max-height: 250px; object-fit: cover; }
          .coupon-box { background: rgba(0, 212, 232, 0.1); border: 2px dashed #00D4E8; border-radius: 8px; padding: 15px; text-align: center; margin: 25px 0; }
          .coupon-label { font-size: 11px; letter-spacing: 2px; color: #00e5ff; font-weight: bold; margin-bottom: 6px; }
          .coupon-code { font-size: 22px; font-weight: bold; letter-spacing: 3px; color: #ffffff; }
          .footer { text-align: center; font-size: 12px; color: #64748b; margin-top: 30px; }
        </style>
      </head>
      <body>
        <div class="card">
          ${imageUrl ? `<img src="${imageUrl}" class="banner" />` : ''}
          <div class="title">${title}</div>
          <div class="body">${cleanContent}</div>
          ${couponCode ? `
            <div class="coupon-box">
              <div class="coupon-label">PROMO COUPON CODE</div>
              <div class="coupon-code">${couponCode}</div>
            </div>
          ` : ''}
          <div class="footer">
            © 2026 WebSpider Studios • Aqua Sort
          </div>
        </div>
      </body>
      </html>
    `;

    // Send emails in batches via Resend API (up to 50 recipients per request)
    const batchSize = 45;
    for (let i = 0; i < emails.length; i += batchSize) {
      const batch = emails.slice(i, i + batchSize);
      
      const res = await fetch('https://api.resend.com/emails', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${RESEND_API_KEY}`,
        },
        body: JSON.stringify({
          from: 'Aqua Sort News <news@webspiderstudios.com>',
          to: batch,
          subject: `[Aqua Sort] ${title}`,
          html: emailHtml,
        }),
      });

      if (!res.ok) {
        console.error(`Resend send failure for batch starting at ${i}: ${await res.text()}`);
      }
    }

    return new Response(JSON.stringify({ message: `Successfully sent announcement emails to ${emails.length} players!` }), { 
      status: 200,
      headers: { "Content-Type": "application/json" }
    });

  } catch (error) {
    console.error(`Edge Function Error: ${error.message}`);
    return new Response(JSON.stringify({ error: error.message }), { status: 500 });
  }
})
