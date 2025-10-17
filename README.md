# Spotify AI Music App 🎵# Spotify AI Music App 🎵# Spotify Artist Search App 🎵



Flutter app with Spotify API integration and AI-powered playlist generation.



## Features ✨Flutter app with Spotify API integration and AI-powered playlist generation.A beautiful, modern Flutter application that lets you search for artists and discover their top tracks using the Spotify API. Built with Material Design 3 (Material You) for an expressive and delightful user experience.



✅ **Search** - Find artists & songs  

✅ **Track Details** - View songs with QR codes  

✅ **Audio Preview** - Listen to 30-second previews  ## Quick Setup## Features ✨

✅ **Playlists** - Create & manage custom playlists  

✅ **Spotify Login** - OAuth authentication  

✅ **AI Playlists** - Generate playlists with Gemini AI  

### 1. Add API Keys- **Welcoming Home Page**: A friendly introduction explaining how the app works

## Quick Setup 🚀

- **Intelligent Search**: Real-time artist search with smart suggestions

### 1. Add Your API Keys

**Spotify Credentials** (`lib/services/spotify_service.dart`):- **Beautiful UI**: Modern Material 3 design with smooth animations

You'll need to add your own API keys to these files:

```dart- **Artist Details**: View comprehensive artist information including:

- **Spotify API** → `lib/services/spotify_service.dart` (lines 8-9)

  - Get from: https://developer.spotify.com/dashboardstatic const String clientId = 'YOUR_CLIENT_ID';  - Follower count



- **Gemini AI** → `lib/services/gemini_ai_service.dart` (line 9)static const String clientSecret = 'YOUR_CLIENT_SECRET';  - Popularity metrics

  - Get from: https://makersuite.google.com/app/apikey

```  - Music genres

### 2. Deploy (Required for Login)

Get from: https://developer.spotify.com/dashboard  - Artist images

The app is configured to auto-deploy via GitHub Actions to GitHub Pages.

- **Top Tracks**: Discover an artist's most popular songs with:

Your live URL will be:

```**Gemini AI Key** (`lib/services/gemini_ai_service.dart`):  - Album artwork

https://byflowt.github.io/spotify-ai-music-app/

``````dart  - Track duration



### 3. Configure Spotify OAuthstatic const String apiKey = 'YOUR_GEMINI_API_KEY';  - Popularity rankings



1. Go to [Spotify Dashboard](https://developer.spotify.com/dashboard)```- **Responsive Design**: Works seamlessly on different screen sizes

2. Your app → **Edit Settings**

3. **Redirect URIs** → Add:Get from: https://makersuite.google.com/app/apikey

   ```

   https://byflowt.github.io/spotify-ai-music-app/## Screenshots

   ```

4. Click **Save**### 2. Deploy for OAuth (Required for Login)



### 4. Update Redirect URI in CodeThe app features:



Edit `lib/services/spotify_auth_service.dart` line 4:Spotify requires HTTPS for OAuth. Deploy your app:- A welcoming home page with Material 3 styling

```dart

static const String redirectUri = 'https://byflowt.github.io/spotify-ai-music-app/';- Intelligent search with artist suggestions

```

**Option A: Vercel (Recommended)**- Detailed artist pages with top tracks

Then push:

```bash```bash- Smooth animations and transitions

git add .

git commit -m "Update redirect URI"flutter build web

git push origin main

```# Upload build/web folder to https://vercel.com## Getting Started 🚀



GitHub Actions will automatically rebuild and deploy! 🎉```



## Tech Stack 💻### Prerequisites



- **Flutter** - Cross-platform framework**Option B: GitHub Pages**

- **Spotify Web API** - Music data & auth

- **Google Gemini AI** - Intelligent playlists```bash- Flutter SDK (3.0.0 or higher)

- **Material 3** - Modern design system

- **GitHub Pages** - Free HTTPS hostingflutter build web- Dart SDK



## Developmentcd build/web- A Spotify Developer Account



Run locally:git init && git add . && git commit -m "Deploy"

```bash

flutter pub getgit push -f https://github.com/USERNAME/repo.git main:gh-pages### Installation

flutter run -d chrome

``````



Build for production:1. **Clone or navigate to the project directory**

```bash

flutter build web --release### 3. Configure OAuth Redirect

```

2. **Get Spotify API Credentials**

---

1. Add your HTTPS URL to `lib/services/spotify_auth_service.dart`:   - Visit [Spotify Developer Dashboard](https://developer.spotify.com/dashboard)

Made with ❤️ using Flutter & Spotify API

   ```dart   - Log in or create an account

   static const String redirectUri = 'https://your-app.vercel.app/';   - Click "Create an App"

   ```   - Fill in the app name and description

   - Copy your `Client ID` and `Client Secret`

2. Add same URL to Spotify Dashboard:

   - Go to https://developer.spotify.com/dashboard3. **Configure API Credentials**

   - Your app → Edit Settings → Redirect URIs   

   - Add: `https://your-app.vercel.app/`   Open `lib/services/spotify_service.dart` and replace the placeholders:

   - Save   

   ```dart

### 4. Run   static const String clientId = 'YOUR_CLIENT_ID_HERE';

   static const String clientSecret = 'YOUR_CLIENT_SECRET_HERE';

```bash   ```

flutter run -d chrome

```4. **Install Dependencies**

   

## Features   ```bash

   flutter pub get

✅ Search artists & songs     ```

✅ View track details with QR codes  

✅ Audio preview player  5. **Run the App**

✅ Create & manage playlists     

✅ Spotify OAuth login     ```bash

✅ AI-powered playlist generation using Gemini     flutter run

   ```

## Tech Stack

## Project Structure 📁

- **Flutter** - Cross-platform UI framework

- **Spotify Web API** - Music data & authentication```

- **Google Gemini AI** - Playlist intelligencelib/

- **Material 3** - Modern design system├── main.dart                 # App entry point with Material 3 theme

├── models/
│   ├── artist_model.dart    # Artist data model
│   └── track_model.dart     # Track data model
├── screens/
│   ├── home_page.dart       # Welcome page with app introduction
│   ├── search_page.dart     # Artist search interface
│   └── artist_detail_page.dart  # Artist details and top tracks
└── services/
    └── spotify_service.dart # Spotify API integration
```

## Dependencies 📦

- **flutter**: Core framework
- **google_fonts**: Beautiful typography (Inter font)
- **provider**: State management
- **http**: API requests
- **cached_network_image**: Efficient image loading and caching
- **shimmer**: Loading animations
- **intl**: Internationalization

## Features Explained 🎯

### Home Page
- Friendly greeting message
- Feature cards explaining app capabilities
- Step-by-step guide on how to use the app
- Material 3 design with gradient effects

### Search Page
- Real-time artist search
- Search suggestions for popular artists
- Artist cards with images, genres, and stats
- Empty state guidance
- Error handling with user-friendly messages

### Artist Detail Page
- Hero animation for smooth transitions
- Full-screen artist image header
- Statistics dashboard (followers, popularity, track count)
- Top tracks list with:
  - Position rankings
  - Album artwork
  - Track duration
  - Popularity metrics

## Design Philosophy 🎨

This app follows **Google's Material Design 3 (Material You)** guidelines:

- **Dynamic Color**: Color scheme based on Spotify's brand color (#1DB954)
- **Expressive Typography**: Using Inter font family
- **Smooth Animations**: Fade-ins, hero transitions, and curved animations
- **Modern Components**: Cards, chips, and navigation bars
- **Responsive Layout**: Adapts to different screen sizes
- **Dark Mode Support**: Automatic theme switching

## API Integration 🔌

The app uses Spotify's Web API with the Client Credentials Flow:

- **Authentication**: Automatic token management
- **Search Endpoint**: Artist search with intelligent filtering
- **Artist Endpoint**: Detailed artist information
- **Top Tracks Endpoint**: Artist's most popular songs

## Notes ⚠️

- The app uses the Client Credentials Flow, which is suitable for public data access
- For production apps, consider implementing a backend proxy to secure API credentials
- The app requires an internet connection to fetch data
- API rate limits apply based on your Spotify Developer account

## Customization 🛠️

### Changing Colors

Edit the color scheme in `lib/main.dart`:

```dart
colorScheme: ColorScheme.fromSeed(
  seedColor: const Color(0xFF1DB954), // Change this color
  brightness: Brightness.light,
),
```

### Changing Fonts

Modify the font family in `lib/main.dart`:

```dart
textTheme: GoogleFonts.yourFontTextTheme(),
```

## Troubleshooting 🔧

**"Failed to authenticate with Spotify"**
- Verify your Client ID and Client Secret are correct
- Ensure they're properly set in `spotify_service.dart`

**"No artists found"**
- Check your internet connection
- Try a different search term
- Verify API credentials are valid

**Build errors**
- Run `flutter clean` and `flutter pub get`
- Ensure Flutter SDK is up to date

## Future Enhancements 💡

Potential features to add:
- Audio preview playback
- Favorite artists list
- Album browsing
- Related artists recommendations
- Share functionality
- Offline caching

## License 📄

This project is for educational and personal use. Spotify API usage is subject to [Spotify's Developer Terms of Service](https://developer.spotify.com/terms).

## Credits 👏

- **Spotify API**: For providing the music data
- **Google Fonts**: For the Inter font family
- **Material Design 3**: For design guidelines
- **Flutter Team**: For the amazing framework

---

Built with ❤️ using Flutter and Material Design 3

Enjoy exploring music! 🎶
