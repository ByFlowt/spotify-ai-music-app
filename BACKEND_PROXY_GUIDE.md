# API Proxy Backend for Spotify AI App

## Why You Need This

GitHub Pages is static hosting - any API keys in the JavaScript can be extracted by users. This backend securely stores your API keys and proxies requests.

## Quick Setup Options

### Option A: Vercel Serverless Functions (FREE & EASY)

1. Create a new repository for the backend
2. Add this structure:

```
api-proxy/
├── api/
│   ├── gemini.js
│   ├── audd.js
│   └── spotify.js
├── vercel.json
└── package.json
```

3. Add API keys to Vercel environment variables
4. Deploy: `vercel --prod`
5. Your Flutter app calls: `https://your-api.vercel.app/api/gemini`

### Option B: Cloudflare Workers (FREE)

Similar to Vercel but uses Cloudflare's edge network.

### Option C: Firebase Cloud Functions

Integrates well with Flutter, free tier available.

## Example Vercel Setup

See `/backend-proxy-example/` folder for complete code.

## How It Works

```
Flutter App (Public) 
    ↓ (no API keys)
Backend Proxy (Vercel/Cloudflare)
    ↓ (with API keys)
External APIs (Gemini, AUDD, etc.)
```

Your API keys stay on the server, never exposed to users!
