/**
 * Spotify Token Exchange and Refresh Proxy
 * Securely handles Spotify OAuth token operations requiring client_secret
 * 
 * Usage from Flutter:
 * POST https://your-app.vercel.app/api/spotify-token
 * 
 * For token exchange:
 * Body: { 
 *   "grant_type": "authorization_code",
 *   "code": "auth_code_from_spotify",
 *   "redirect_uri": "https://byflowt.github.io/spotify-ai-music-app/",
 *   "code_verifier": "pkce_code_verifier"
 * }
 * 
 * For token refresh:
 * Body: { 
 *   "grant_type": "refresh_token",
 *   "refresh_token": "user_refresh_token"
 * }
 */

const fetch = require('node-fetch');

module.exports = async (req, res) => {
  // Handle CORS preflight request
  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }

  // Only allow POST requests
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  // Get credentials from environment variables (set in Vercel dashboard)
  const SPOTIFY_CLIENT_ID = process.env.SPOTIFY_CLIENT_ID;
  const SPOTIFY_CLIENT_SECRET = process.env.SPOTIFY_CLIENT_SECRET;
  
  if (!SPOTIFY_CLIENT_ID || !SPOTIFY_CLIENT_SECRET) {
    console.error('Spotify credentials not configured');
    return res.status(500).json({ error: 'Spotify credentials not configured' });
  }

  try {
    const { grant_type, code, redirect_uri, code_verifier, refresh_token } = req.body;
    
    if (!grant_type) {
      return res.status(400).json({ error: 'grant_type is required' });
    }

    let requestBody;

    if (grant_type === 'authorization_code') {
      // Token exchange from authorization code
      if (!code || !redirect_uri || !code_verifier) {
        return res.status(400).json({ 
          error: 'code, redirect_uri, and code_verifier are required for authorization_code grant' 
        });
      }

      requestBody = new URLSearchParams({
        grant_type: 'authorization_code',
        code: code,
        redirect_uri: redirect_uri,
        client_id: SPOTIFY_CLIENT_ID,
        client_secret: SPOTIFY_CLIENT_SECRET,
        code_verifier: code_verifier
      });

      console.log('Processing authorization code exchange');

    } else if (grant_type === 'refresh_token') {
      // Token refresh
      if (!refresh_token) {
        return res.status(400).json({ 
          error: 'refresh_token is required for refresh_token grant' 
        });
      }

      requestBody = new URLSearchParams({
        grant_type: 'refresh_token',
        refresh_token: refresh_token,
        client_id: SPOTIFY_CLIENT_ID,
        client_secret: SPOTIFY_CLIENT_SECRET
      });

      console.log('Processing token refresh');

    } else {
      return res.status(400).json({ 
        error: `Unsupported grant_type: ${grant_type}` 
      });
    }

    // Make request to Spotify token endpoint
    const response = await fetch('https://accounts.spotify.com/api/token', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: requestBody.toString()
    });

    const data = await response.json();

    if (response.ok) {
      console.log('Spotify token operation successful');
      // Return the token response to the Flutter app
      return res.status(200).json(data);
    } else {
      console.error('Spotify token operation failed:', data);
      return res.status(response.status).json(data);
    }

  } catch (error) {
    console.error('Error in Spotify token proxy:', error);
    return res.status(500).json({ 
      error: 'Internal server error',
      message: error.message 
    });
  }
};
