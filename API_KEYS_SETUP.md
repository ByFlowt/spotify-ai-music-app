# API Keys Setup Guide

This document explains how to configure API keys for the Spotify AI Music App, including Spotify OAuth, Gemini AI, and AUDD audio recognition.

## Overview

The app uses multiple APIs:
- **Spotify Web API** - For music search and playlist management
- **Google Gemini AI** - For intelligent playlist generation
- **AUDD.io** - For audio recognition and song identification

---

## 1. Spotify Web API Configuration

### Setup Location
`lib/services/spotify_auth_service.dart` and `lib/services/spotify_service.dart`

### Steps

1. Go to [Spotify Developer Dashboard](https://developer.spotify.com/dashboard)
2. Create an app or use existing one
3. Get your **Client ID** and **Client Secret**
4. Add Redirect URI: `com.example.spotify_search_app://callback` (for mobile) or your web domain

### Configuration in App

Currently, these values should be set in:
```dart
// In spotify_auth_service.dart
const String clientId = 'YOUR_CLIENT_ID';
const String clientSecret = 'YOUR_CLIENT_SECRET';
```

### Better Practice (Environment Variables)

For production, use environment variables or a secure config:

```dart
// Create a new file: lib/config/api_config.dart
const String spotifyClientId = String.fromEnvironment('SPOTIFY_CLIENT_ID');
const String spotifyClientSecret = String.fromEnvironment('SPOTIFY_CLIENT_SECRET');
```

Then build with:
```bash
flutter build web --release -DSPOTIFY_CLIENT_ID=your_id -DSPOTIFY_CLIENT_SECRET=your_secret
```

---

## 2. Google Gemini AI Configuration

### Setup Location
`lib/services/gemini_ai_service.dart`

### Steps

1. Go to [Google AI Studio](https://aistudio.google.com/app/apikey)
2. Create a new API key
3. Enable Generative Language API in your Google Cloud project

### Configuration in App

Currently, the API key is passed in the URL:
```dart
// In gemini_ai_service.dart
Future<List<Track>> generatePlaylist(String prompt) async {
  final String apiKey = 'YOUR_GEMINI_API_KEY';
  
  final response = await http.post(
    Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$apiKey'),
    // ...
  );
}
```

### Better Practice (Using .env file)

1. Add `flutter_dotenv` to `pubspec.yaml`:
```yaml
dependencies:
  flutter_dotenv: ^5.1.0
```

2. Create `.env` file in project root:
```
GEMINI_API_KEY=your_api_key_here
```

3. Update `gemini_ai_service.dart`:
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiAIService extends ChangeNotifier {
  late final String _apiKey;
  
  GeminiAIService() {
    _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  }
  
  Future<List<Track>> generatePlaylist(String prompt) async {
    final response = await http.post(
      Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$_apiKey'),
      // ...
    );
  }
}
```

4. Update `main.dart`:
```dart
void main() async {
  await dotenv.load(fileName: '.env');
  runApp(const MyApp());
}
```

---

## 3. AUDD Audio Recognition API Configuration

### Setup Location
`lib/services/shazam_service.dart`

### Steps

1. Go to [AUDD.io](https://audd.io)
2. Sign up for a free account
3. Get your API key from the dashboard
4. Note: Free tier allows ~3000 requests per month

### Configuration in App

#### Current Implementation
The service uses AUDD API but needs the key added:

```dart
// In shazam_service.dart
Future<List<Track>> recognizeAudio(String audioUrl) async {
  final String apiKey = 'YOUR_AUDD_API_KEY';
  
  final response = await http.post(
    Uri.parse('$_baseUrl/?method=recognizeSong&return=spotify&file_url=$audioUrl&api_token=$apiKey'),
    // ...
  );
}
```

#### Recommended: Secure Configuration

**Option A: Using .env file (Recommended)**

1. Add to `.env`:
```
AUDD_API_KEY=your_api_key_here
```

2. Update `shazam_service.dart`:
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ShazamService extends ChangeNotifier {
  static const String _baseUrl = 'https://api.audd.io';
  final String _apiKey = dotenv.env['AUDD_API_KEY'] ?? '';
  
  Future<List<Track>> recognizeAudio(String audioUrl) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/?method=recognizeSong&return=spotify&file_url=$audioUrl&api_token=$_apiKey'),
      // ...
    );
  }
}
```

**Option B: Alternative Free APIs**

If you prefer not to use AUDD, alternatives include:
- **ACRCloud** - Audio fingerprinting (free tier available)
- **MusicBrainz** - Free metadata API (no audio recognition)
- **Last.fm API** - Free music data API

---

## 4. Web Deployment Configuration

### GitHub Pages Setup

Your app is deployed to: `https://byflowt.github.io/spotify-ai-music-app/`

#### Web-Specific Configuration

For web builds, you may need to configure CORS and API access differently:

1. **Update `web/index.html`** to add base href:
```html
<base href="/spotify-ai-music-app/">
```

2. **API Keys in Web** - Never put sensitive keys in web builds!
   - Use backend proxy for API calls
   - Use Firebase for secure configuration
   - Use environment-based configuration

### Environment-Specific Builds

Create separate configurations:

```bash
# Development build
flutter run -d chrome

# Production web build (current)
flutter build web --release

# Build with environment variables
flutter build web --release \
  -DGEMINI_API_KEY=your_key \
  -DAUDD_API_KEY=your_key
```

---

## 5. Secure API Key Management Best Practices

### ✅ DO:
- Store API keys in environment variables or `.env` files (NOT in git)
- Use different keys for development and production
- Rotate keys regularly
- Use Firebase Secrets or similar for sensitive data
- Implement rate limiting on backend

### ❌ DON'T:
- Hardcode API keys in source code
- Commit API keys to git repository
- Expose keys in client-side web builds
- Use the same key across all environments

### .gitignore Setup

Make sure `.env` is in your `.gitignore`:
```
# .gitignore
.env
.env.local
.env.*.local
```

---

## 6. Current Implementation Status

### ✅ Working:
- Spotify OAuth authentication
- Spotify API searches and playlist creation
- Gemini AI prompt-based playlist generation
- SharedPreferences for offline playlist storage

### 🟡 In Progress:
- AUDD API key integration (needs `dotenv` setup)
- Audio recognition feature (UI ready, backend needs key)
- Audio search dialog (implemented, awaiting API configuration)

### 🟠 Recommended Next Steps:
1. Add `flutter_dotenv` package to handle environment variables
2. Create `.env` file template for developers
3. Update all three services to use `.env` configuration
4. Add instructions to README for contributors
5. Set up GitHub Actions to inject secrets during deployment

---

## 7. Testing API Connections

### Test Spotify Connection
```dart
// In home_page.dart or test file
final spotify = SpotifyService();
final results = await spotify.searchArtists('Drake');
print('Found ${results.length} artists');
```

### Test Gemini AI Connection
```dart
final gemini = GeminiAIService();
final tracks = await gemini.generatePlaylist('upbeat dance songs');
print('Generated ${tracks.length} tracks');
```

### Test AUDD Audio Recognition
```dart
final shazam = ShazamService();
final tracks = await shazam.recognizeAudio('https://example.com/song.mp3');
print('Recognized: ${tracks.map((t) => t.name).join(', ')}');
```

---

## 8. Deployment Checklist

- [ ] Add `flutter_dotenv` to pubspec.yaml
- [ ] Create `.env` file with all API keys
- [ ] Update all services to use environment variables
- [ ] Test all API integrations locally
- [ ] Run `flutter build web --release`
- [ ] Verify build in `docs/` folder
- [ ] Commit changes (excluding `.env`)
- [ ] Push to GitHub
- [ ] Verify web app at GitHub Pages URL
- [ ] Test audio recognition in production

---

## 9. Troubleshooting

### "API Key Not Found" Error
- Check `.env` file exists in project root
- Ensure `flutter_dotenv` is initialized in `main()`
- Verify `pubspec.yaml` includes `flutter_dotenv` dependency

### CORS Errors on Web
- AUDD API supports CORS for web requests
- If issues occur, consider using a backend proxy
- Check browser console for specific error messages

### Spotify Login Issues
- Verify Redirect URI matches configuration in Spotify Dashboard
- Check Client ID and Secret are correct
- Ensure `flutter_web_auth_2` package is properly configured

---

For questions or issues, check the GitHub Issues or README.
