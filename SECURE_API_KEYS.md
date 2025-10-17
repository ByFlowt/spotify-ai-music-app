# 🔐 Secure API Key Management for GitHub Pages

## The Problem

**You CANNOT securely store API keys on GitHub Pages!**

- ❌ GitHub Pages = Static files only
- ❌ No server-side processing
- ❌ All JavaScript is visible in browser
- ❌ Any "encryption" key would also be visible
- ❌ Attackers can extract keys from compiled code

## The Solution: Backend Proxy

### Architecture

```
┌─────────────────┐
│  Flutter App    │  (GitHub Pages)
│  (Public)       │  No API keys stored
└────────┬────────┘
         │ HTTP Request (no keys)
         ▼
┌─────────────────┐
│  Vercel Proxy   │  (Serverless Functions)
│  (Private)      │  API keys in env vars
└────────┬────────┘
         │ HTTP Request (with keys)
         ▼
┌─────────────────┐
│  External APIs  │  (Gemini, AUDD, etc.)
└─────────────────┘
```

## Quick Start

### 1. Deploy the Proxy (5 minutes)

```bash
# Install Vercel CLI
npm install -g vercel

# Login to Vercel
vercel login

# Deploy
cd backend-proxy-example
vercel --prod
```

### 2. Add API Keys to Vercel

1. Go to https://vercel.com/dashboard
2. Select your project
3. Settings → Environment Variables
4. Add:
   - `GEMINI_API_KEY`
   - `AUDD_API_KEY`
   - `SPOTIFY_CLIENT_SECRET` (if needed)

### 3. Update Flutter Code

Replace direct API calls with proxy calls:

```dart
// OLD - Direct call (INSECURE)
final response = await http.post(
  Uri.parse('https://api.gemini.com/...'),
  headers: {'Authorization': 'Bearer $apiKey'}, // ❌ Key visible!
);

// NEW - Proxy call (SECURE)
final response = await ApiProxyService.callGemini(
  prompt: 'Generate playlist...',
); // ✅ No key exposed!
```

### 4. Update Proxy URL

Edit `lib/services/api_proxy_service.dart`:

```dart
static const String _vercelProxyUrl = 'https://YOUR-APP.vercel.app';
```

## Alternative Solutions

### Option A: OAuth Only (Current Setup)
- ✅ FREE
- ✅ Users authenticate themselves
- ❌ Limited features (no AI, no audio recognition)
- **Good for:** Spotify-only features

### Option B: Backend Proxy (Recommended)
- ✅ All features work
- ✅ API keys secure
- ✅ FREE tier available (Vercel, Cloudflare)
- ⚠️ Requires separate deployment
- **Good for:** Full-featured production app

### Option C: Rate-Limited Public Keys
- ✅ Simple setup
- ❌ Keys can be stolen and abused
- ❌ You pay for attacker's usage
- **Good for:** Demos only, NOT production

### Option D: Firebase/Supabase
- ✅ All-in-one backend solution
- ✅ Database + auth + functions
- ⚠️ More complex setup
- **Good for:** Large apps with database needs

## Cost Comparison

| Service | Free Tier | Paid Plans |
|---------|-----------|------------|
| **Vercel** | 100GB bandwidth, unlimited functions | $20/mo (Pro) |
| **Cloudflare Workers** | 100k requests/day | $5/mo (10M requests) |
| **Firebase Functions** | 2M invocations/month | Pay-as-you-go |
| **Railway** | $5 credit/month | $5+/mo |

**Recommendation:** Start with Vercel free tier - it's more than enough!

## Security Best Practices

### ✅ DO:
- Use backend proxy for secret keys
- Store keys in environment variables
- Enable CORS restrictions
- Add rate limiting
- Monitor usage/costs
- Rotate keys regularly

### ❌ DON'T:
- Embed keys in frontend code
- Commit `.env` files to git
- Use "encryption" in frontend (it's visible!)
- Ignore usage monitoring
- Share keys in chat/screenshots

## Testing Your Setup

```dart
// Test the proxy is working
final isHealthy = await ApiProxyService.checkProxyHealth();
print('Proxy status: ${isHealthy ? "✅" : "❌"}');
```

## Troubleshooting

**Proxy not responding?**
- Check Vercel deployment logs
- Verify environment variables are set
- Check CORS configuration

**Keys not working?**
- Ensure they're saved in Vercel dashboard
- Redeploy after adding env vars
- Check for typos in variable names

**CORS errors?**
- Update `vercel.json` with your GitHub Pages URL
- Ensure headers are correctly configured

## Files Included

- `backend-proxy-example/` - Complete Vercel proxy setup
- `lib/services/api_proxy_service.dart` - Flutter proxy client
- `BACKEND_PROXY_GUIDE.md` - Quick reference
- This file - Complete guide

## Next Steps

1. ✅ Deploy proxy to Vercel
2. ✅ Add environment variables
3. ✅ Update Flutter app to use proxy
4. ✅ Test with API calls
5. ✅ Deploy Flutter app to GitHub Pages
6. ✅ Monitor usage and costs

---

**Remember:** There is NO way to truly hide API keys in static frontend code. A backend proxy is the ONLY secure solution! 🔒
