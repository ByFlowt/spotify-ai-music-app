# Backend Proxy Setup Guide

## Why You Need This

**GitHub Pages cannot securely store API keys!** Any key in your JavaScript can be extracted. This backend proxy keeps your keys safe on a server.

## Setup Steps (Vercel - FREE)

### 1. Install Vercel CLI

```bash
npm install -g vercel
```

### 2. Deploy the Proxy

```bash
cd backend-proxy-example
vercel login
vercel
```

### 3. Add Environment Variables

In Vercel Dashboard (https://vercel.com/dashboard):
- Go to your project → Settings → Environment Variables
- Add:
  - `GEMINI_API_KEY` = your_gemini_key
  - `AUDD_API_KEY` = your_audd_key
  - `SPOTIFY_CLIENT_SECRET` = your_spotify_secret (if needed)

### 4. Update Your Flutter App

Change API calls from direct to proxied:

**Before:**
```dart
// Direct call - INSECURE!
final response = await http.post(
  Uri.parse('https://generativelanguage.googleapis.com/v1/...'),
  headers: {'Authorization': 'Bearer $GEMINI_API_KEY'}, // ❌ Exposed!
);
```

**After:**
```dart
// Proxied call - SECURE!
final response = await http.post(
  Uri.parse('https://your-app.vercel.app/api/gemini'), // ✅ No key exposed
  body: json.encode({'prompt': 'Generate playlist...'}),
);
```

### 5. Update api_config.dart

Add proxy URLs:

```dart
class ApiConfig {
  static const String proxyBaseUrl = kIsWeb 
    ? 'https://your-app.vercel.app'
    : 'http://localhost:3000'; // For local testing
    
  static String get geminiProxyUrl => '$proxyBaseUrl/api/gemini';
  static String get auddProxyUrl => '$proxyBaseUrl/api/audd';
}
```

## Alternative: Rate Limiting (Simple Protection)

If you still want to embed keys (not recommended), at least add rate limiting:

1. Use Cloudflare (free) in front of your app
2. Set rate limits per IP
3. Add domain verification in your code

But **a backend proxy is still the best solution**! 🔒

## Cost Comparison

| Service | Free Tier | Best For |
|---------|-----------|----------|
| **Vercel** | 100GB bandwidth, unlimited serverless functions | Simple APIs, fast deploy |
| **Cloudflare Workers** | 100k requests/day | High traffic, edge computing |
| **Firebase Functions** | 2M invocations/month | If using Firebase already |
| **Railway** | $5 free credit/month | Full backend server |

## Security Checklist

✅ API keys only in backend environment variables  
✅ CORS configured to only allow your domain  
✅ Rate limiting enabled  
✅ Input validation on all endpoints  
✅ HTTPS only  
❌ Never commit `.env` files  
❌ Never embed API keys in frontend code  
