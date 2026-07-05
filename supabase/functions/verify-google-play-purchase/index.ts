import { serve } from "https://deno.land/std@0.177.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.4"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      { auth: { persistSession: false } }
    )

    // Get user from auth header
    const authHeader = req.headers.get('Authorization')!
    const { data: { user }, error: authError } = await supabaseClient.auth.getUser(
      authHeader.replace('Bearer ', '')
    )

    if (authError || !user) {
      throw new Error('Unauthorized')
    }

    const { purchaseToken, productId, packageName, isSubscription } = await req.json()

    if (!purchaseToken || !productId || !packageName) {
      throw new Error('Missing required fields')
    }

    // NOTE: In a real production environment, you would use googleapis package 
    // and the GOOGLE_PLAY_SERVICE_ACCOUNT_JSON secret to authenticate and call 
    // the Google Play Developer API (androidpublisher.v3) to verify the purchaseToken.
    // 
    // Example:
    // const auth = new google.auth.GoogleAuth({ ... })
    // const androidPublisher = google.androidpublisher({ version: 'v3', auth })
    // const res = await androidPublisher.purchases.products.get({ ... })

    console.log(`[Mock Verification] Verifying ${productId} for user ${user.id}`)
    
    // Simulate API delay
    await new Promise(resolve => setTimeout(resolve, 800))

    // Mock validation success
    const isValid = true 
    
    if (!isValid) {
      return new Response(JSON.stringify({ success: false, error: 'Invalid purchase receipt' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      })
    }

    // Deliver product
    if (isSubscription) {
      // Update profile with premium status
      await supabaseClient
        .from('profiles')
        .update({ is_premium: true })
        .eq('id', user.id)
    } else {
      // Parse coin amount from productId (e.g. com.webspider.aqua.coins.100 -> 100)
      const coinMatch = productId.match(/\.coins\.(\d+)$/)
      if (coinMatch && coinMatch[1]) {
        const amount = parseInt(coinMatch[1], 10)
        
        // Use RPC to safely increment coins
        await supabaseClient.rpc('increment_webspider_coins', { 
          user_id: user.id, 
          amount: amount 
        })
      }
    }

    // Log purchase
    await supabaseClient.from('purchases').insert({
      user_id: user.id,
      product_id: productId,
      purchase_token: purchaseToken,
      platform: 'google_play',
      status: 'completed'
    })

    return new Response(JSON.stringify({ success: true }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    })
  } catch (error: any) {
    console.error('Purchase verification error:', error.message)
    return new Response(JSON.stringify({ success: false, error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 500,
    })
  }
})
