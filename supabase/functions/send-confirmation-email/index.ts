import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { corsHeaders, handleCors } from '../_shared/cors.ts';

interface EmailBody {
  email: string;
  token: string;
  room_number: string;
  check_in: string;
  check_out: string;
  total_amount: number;
}

const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY');

serve(async (req: Request) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  try {
    const body = (await req.json()) as EmailBody;

    if (!body.email || !body.token) {
      return new Response(
        JSON.stringify({ success: false, error: 'Missing email or token' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 },
      );
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const confirmUrl = `${supabaseUrl}/functions/v1/confirm-reservation`;

    const html = `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
          body { font-family: 'Georgia', serif; margin: 0; padding: 0; background-color: #f4f4f4; }
          .container { max-width: 600px; margin: 0 auto; padding: 40px 20px; }
          .card { background: white; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 24px rgba(0,0,0,0.08); }
          .header { background: linear-gradient(135deg, #003B5C, #005A8C); padding: 40px; text-align: center; }
          .header h1 { color: #C9A96E; margin: 0; font-size: 28px; }
          .header p { color: rgba(255,255,255,0.8); margin: 8px 0 0; }
          .content { padding: 32px; }
          .details { background: #f8f8f8; border-radius: 12px; padding: 20px; margin: 20px 0; }
          .details table { width: 100%; }
          .details td { padding: 6px 0; font-size: 14px; }
          .details td:last-child { text-align: right; font-weight: 600; }
          .button { display: inline-block; background: #C9A96E; color: white !important; text-decoration: none;
            padding: 16px 48px; border-radius: 50px; font-size: 16px; font-weight: 600; margin: 20px 0; }
          .footer { text-align: center; color: #999; font-size: 12px; padding: 24px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="card">
            <div class="header">
              <h1>La Pirogue</h1>
              <p>Mauritius</p>
            </div>
            <div class="content">
              <h2 style="margin:0;font-size:22px;">Confirm Your Reservation</h2>
              <p style="color:#666;margin:8px 0 0;">Thank you for choosing La Pirogue. Please confirm your booking by clicking the button below.</p>

              <div class="details">
                <table>
                  <tr><td>Room</td><td>${body.room_number}</td></tr>
                  <tr><td>Check-in</td><td>${body.check_in}</td></tr>
                  <tr><td>Check-out</td><td>${body.check_out}</td></tr>
                  <tr><td>Total</td><td>MUR ${body.total_amount.toLocaleString()}</td></tr>
                </table>
              </div>

              <div style="text-align:center;">
                <a class="button" href="${confirmUrl}" target="_blank">Confirm Reservation</a>
              </div>

              <p style="color:#999;font-size:13px;text-align:center;margin-top:16px;">
                If you did not make this reservation, please ignore this email.
              </p>
            </div>
            <div class="footer">
              <p>La Pirogue Mauritius &mdash; A Beachfront Paradise</p>
            </div>
          </div>
        </div>
      </body>
      </html>
    `;

    if (RESEND_API_KEY) {
      const res = await fetch('https://api.resend.com/emails', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${RESEND_API_KEY}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          from: 'La Pirogue <reservations@lapirogue.mu>',
          to: body.email,
          subject: 'Confirm Your Reservation at La Pirogue Mauritius',
          html,
        }),
      });

      if (!res.ok) {
        const err = await res.text();
        console.error('Resend error:', err);
      }
    } else {
      console.log('RESEND_API_KEY not set — email would be sent to:', body.email);
      console.log('Confirmation link:', confirmUrl + ' with token:', body.token);
    }

    return new Response(
      JSON.stringify({ success: true }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 },
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ success: false, error: err.message }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 500 },
    );
  }
});
