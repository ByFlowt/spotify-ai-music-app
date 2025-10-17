# ✅ Vercel Deployment Successful!

Your backend proxy is now deployed at:
**https://backendproxy-edfpf6fnh-byflowt-prod-tests-projects.vercel.app**

## Next Steps:

### 1. Add Environment Variables in Vercel Dashboard

Go to: https://vercel.com/byflowt-prod-tests-projects/backend_proxy/settings/environment-variables

Add these environment variables:

| Variable Name | Value |
|---------------|-------|
| `GEMINI_API_KEY` | Your Google Gemini API key |
| `AUDD_API_KEY` | Your AUDD.io API key |
| `SPOTIFY_CLIENT_ID` | Your Spotify Client ID |
| `SPOTIFY_CLIENT_SECRET` | **REQUIRED** - Your Spotify Client Secret |

**Important:** After adding variables, you need to redeploy:
```bash
vercel --prod
```

**Note:** The `SPOTIFY_CLIENT_SECRET` is **required** for the proxy to work. The backend proxy securely handles Spotify OAuth token exchange and refresh operations that require the client secret, keeping it safe from the frontend code.

### 2. Update Your Flutter App

Edit `lib/services/api_proxy_service.dart`:

```dart
static const String _vercelProxyUrl = 'https://backendproxy-edfpf6fnh-byflowt-prod-tests-projects.vercel.app';
```

Or set up a custom domain (recommended):
1. Go to: https://vercel.com/byflowt-prod-tests-projects/backend_proxy/settings/domains
2. Add a custom domain (e.g., `api.yourdomain.com`)
3. Update the URL in your Flutter app

### 3. Test Your Endpoints

```bash
# Test health check
curl https://backendproxy-edfpf6fnh-byflowt-prod-tests-projects.vercel.app/api/health

# Should return: {"status":"healthy","timestamp":"...","service":"spotify-ai-proxy"}
```

### 4. Update CORS if Needed

If your GitHub Pages URL changes, update `vercel.json`:
```json
"Access-Control-Allow-Origin": "https://byflowt.github.io"
```

## Quick Commands

```bash
# Deploy updates
vercel --prod

# View logs
vercel logs

# Check project info
vercel ls

# Remove old deployment
vercel rm backend_proxy
```

## Environment Variables You Need

From your `.env` file:
- ✅ GEMINI_API_KEY=AIzaSyDaKqVBlnGR6UXq5XQjxo7mJDfgVZ9t0NU
- ✅ AUDD_API_KEY=3cb567377b824e96657c208fcf07d2bf
- ✅ SPOTIFY_CLIENT_ID=ce1797970d2d4ec8852fa68a54fe8a8f
- ⚠️ **SPOTIFY_CLIENT_SECRET=2eb0d963befb41f0998ddd703c8a8b7a** (REQUIRED - don't skip this!)

**Remember:** Don't commit these values to git!

## New Endpoint: Spotify Token Management

The proxy now includes `/api/spotify-token` endpoint for secure OAuth operations:

**Token Exchange (after OAuth login):**
```bash
curl -X POST https://backendproxy-edfpf6fnh-byflowt-prod-tests-projects.vercel.app/api/spotify-token \
  -H "Content-Type: application/json" \
  -d '{
    "grant_type": "authorization_code",
    "code": "AUTH_CODE_FROM_SPOTIFY",
    "redirect_uri": "https://byflowt.github.io/spotify-ai-music-app/",
    "code_verifier": "PKCE_CODE_VERIFIER"
  }'
```

**Token Refresh:**
```bash
curl -X POST https://backendproxy-edfpf6fnh-byflowt-prod-tests-projects.vercel.app/api/spotify-token \
  -H "Content-Type: application/json" \
  -d '{
    "grant_type": "refresh_token",
    "refresh_token": "USER_REFRESH_TOKEN"
  }'
```
