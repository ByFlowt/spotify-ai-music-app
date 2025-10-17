# Deploy to Vercel - Quick Guide

## Method 1: Vercel Website (Easiest - No CLI)

### Step 1: Deploy
1. Go to **https://vercel.com**
2. **Sign in** with GitHub (use your ByFlowt account)
3. Click **"Add New"** → **"Project"**
4. Click **"Import"** on your `spotify-ai-music-app` repository
5. **Build Settings:**
   - Framework Preset: **Other**
   - Build Command: `flutter build web --release`
   - Output Directory: `build/web`
6. Click **"Deploy"**

### Step 2: Get Your URL
After deployment (2-3 minutes), you'll get a URL like:
```
https://spotify-ai-music-app.vercel.app
```

Or with your custom domain:
```
https://spotify-ai-music-app-byflowtproject.vercel.app
```

---

## Method 2: Manual Upload (Super Easy)

Since your app is already built:

1. Go to **https://vercel.com/new**
2. **Drag and drop** the `build/web` folder
3. Click **Deploy**
4. Done! Get your URL

---

## Update Your Code with Vercel URL

Once you have your Vercel URL (e.g., `https://spotify-ai-music-app.vercel.app`):

### 1. Update Flutter Code

**File: `lib/services/spotify_auth_service.dart`**
```dart
static const String redirectUri = 'https://spotify-ai-music-app.vercel.app/';
```

### 2. Update Spotify Dashboard

1. Go to **https://developer.spotify.com/dashboard**
2. Click your app → **Edit Settings**
3. **Redirect URIs** section → Add:
   ```
   https://spotify-ai-music-app.vercel.app/
   ```
4. Click **Save**

### 3. Rebuild & Redeploy

```bash
flutter build web --release
```

Then either:
- Push to GitHub (Vercel auto-deploys)
- Or drag-drop new `build/web` folder to Vercel

---

## Your Complete Redirect URI

After deployment, your **Redirect URI** will be:

```
https://your-app-name.vercel.app/
```

**Important:** Must include the trailing slash `/`

---

## Test Your App

1. Go to your Vercel URL
2. Click "Login with Spotify"
3. Authorize the app
4. You should be redirected back and logged in! ✅
