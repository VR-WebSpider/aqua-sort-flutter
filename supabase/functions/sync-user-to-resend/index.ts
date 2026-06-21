import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY');

// Centralized "WebSpider Studios" Player Sync
// This function adds registered users to your Resend contacts automatically.

serve(async (req) => {
  try {
    // Parse the incoming record from the Supabase trigger
    const { record } = await req.json();
    
    // Extract info from your 'profiles' table columns
    const email = record.email_lookup; 
    const firstName = record.first_name || 'Player';
    const lastName = record.last_name || '';

    if (!email) {
      return new Response(JSON.stringify({ error: 'No email provided in record' }), { status: 400 });
    }

    console.log(`Syncing centralized identity: ${email} (${firstName})`);

    // Call Resend API to add/update the contact
    const res = await fetch('https://api.resend.com/contacts', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${RESEND_API_KEY}`,
      },
      body: JSON.stringify({
        email: email,
        firstName: firstName,
        lastName: lastName,
        unsubscribed: false,
        // Tagging them for future segmentation
        tags: [
          { name: 'Source', value: 'Aqua Sort' },
          { name: 'Studio', value: 'WebSpider Studios' }
        ]
      }),
    });

    const data = await res.json();
    
    if (!res.ok) {
      // If contact already exists, Resend might return an error - we handle that gracefully
      console.warn(`Resend API Note: ${JSON.stringify(data)}`);
    }

    return new Response(JSON.stringify({ message: "Centralization Successful", data }), { 
      status: 200,
      headers: { "Content-Type": "application/json" }
    });

  } catch (error) {
    console.error(`Sync Error: ${error.message}`);
    return new Response(JSON.stringify({ error: error.message }), { status: 500 });
  }
})
