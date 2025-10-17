# Spotify AI Music App 🎵# Spotify AI Music App 🎵# Spotify AI Music App 🎵# Spotify Artist Search App 🎵



A beautiful, modern Flutter application that combines Spotify's music database with AI-powered playlist generation using Google Gemini. Built with Material Design 3 for an expressive and delightful user experience.



## Features ✨Flutter app with Spotify API integration and AI-powered playlist generation.



✅ **Spotify Authentication** - Secure OAuth login  

✅ **Artist Search** - Find artists with real-time suggestions  

✅ **Track Details** - View songs with previews and QR codes  ## Features ✨Flutter app with Spotify API integration and AI-powered playlist generation.A beautiful, modern Flutter application that lets you search for artists and discover their top tracks using the Spotify API. Built with Material Design 3 (Material You) for an expressive and delightful user experience.

✅ **Audio Preview** - Listen to 30-second track previews  

✅ **Custom Playlists** - Create and manage your own playlists  

✅ **AI Playlists** - Generate intelligent playlists with Gemini AI  

✅ **Audio Recognition** - Identify songs using audio (Shazam-like feature)  ✅ **Search** - Find artists & songs  

✅ **Material 3 Design** - Beautiful, modern UI with smooth animations  

✅ **Offline Support** - Playlists persist locally with SharedPreferences  ✅ **Track Details** - View songs with QR codes  

✅ **Web & Mobile** - Cross-platform Flutter support  

✅ **Audio Preview** - Listen to 30-second previews  ## Quick Setup## Features ✨

## 🚀 Quick Start

✅ **Playlists** - Create & manage custom playlists  

### Prerequisites

✅ **Spotify Login** - OAuth authentication  

- Flutter SDK (3.0.0 or higher)

- Dart SDK✅ **AI Playlists** - Generate playlists with Gemini AI  

- A Spotify Developer Account

- Google AI Studio account (free tier available)### 1. Add API Keys- **Welcoming Home Page**: A friendly introduction explaining how the app works



### 1. Clone & Setup## Quick Setup 🚀



```bash- **Intelligent Search**: Real-time artist search with smart suggestions

git clone https://github.com/ByFlowt/spotify-ai-music-app.git

cd spotify-ai-music-app### 1. Add Your API Keys

flutter pub get

```**Spotify Credentials** (`lib/services/spotify_service.dart`):- **Beautiful UI**: Modern Material 3 design with smooth animations



### 2. Configure API KeysYou'll need to add your own API keys to these files:



**Copy the example environment file:**```dart- **Artist Details**: View comprehensive artist information including:

```bash

cp .env.example .env- **Spotify API** → `lib/services/spotify_service.dart` (lines 8-9)

```

  - Get from: https://developer.spotify.com/dashboardstatic const String clientId = 'YOUR_CLIENT_ID';  - Follower count

**Edit `.env` and add your API keys:**

```

SPOTIFY_CLIENT_ID=your_spotify_client_id_here

SPOTIFY_CLIENT_SECRET=your_spotify_client_secret_here- **Gemini AI** → `lib/services/gemini_ai_service.dart` (line 9)static const String clientSecret = 'YOUR_CLIENT_SECRET';  - Popularity metrics

GEMINI_API_KEY=your_gemini_api_key_here

AUDD_API_KEY=your_audd_api_key_here  # Optional, for audio recognition  - Get from: https://makersuite.google.com/app/apikey

```

```  - Music genres

**Get your API keys:**

### 2. Deploy (Required for Login)

- **Spotify**: https://developer.spotify.com/dashboard

  - Create an app and copy Client ID & SecretGet from: https://developer.spotify.com/dashboard  - Artist images

  - Add redirect URI: `com.example.spotify_search_app://callback` (mobile) or your web URL

The app is configured to auto-deploy via GitHub Actions to GitHub Pages.

- **Gemini AI**: https://aistudio.google.com/app/apikey

  - Create a new API key (free tier available)- **Top Tracks**: Discover an artist's most popular songs with:



- **AUDD.io** (optional): https://audd.ioYour live URL will be:

  - Free tier: ~3000 requests/month

  - For audio recognition feature```**Gemini AI Key** (`lib/services/gemini_ai_service.dart`):  - Album artwork



### 3. Run the Apphttps://byflowt.github.io/spotify-ai-music-app/



**Mobile/Desktop:**``````dart  - Track duration

```bash

flutter run

```

### 3. Configure Spotify OAuthstatic const String apiKey = 'YOUR_GEMINI_API_KEY';  - Popularity rankings

**Web:**

```bash

flutter run -d chrome

```1. Go to [Spotify Dashboard](https://developer.spotify.com/dashboard)```- **Responsive Design**: Works seamlessly on different screen sizes



### 4. Build for Production2. Your app → **Edit Settings**



**Web Release (deployed to GitHub Pages):**3. **Redirect URIs** → Add:Get from: https://makersuite.google.com/app/apikey

```bash

flutter build web --release   ```

```

   https://byflowt.github.io/spotify-ai-music-app/## Screenshots

This automatically copies to `docs/` folder for GitHub Pages deployment.

   ```

## 📁 Project Structure

4. Click **Save**### 2. Deploy for OAuth (Required for Login)

```

lib/

├── main.dart                 # App entry point

├── config/### 4. Update Redirect URI in CodeThe app features:

│   └── api_config.dart      # Centralized API key management

├── models/

│   ├── artist_model.dart

│   ├── track_model.dartEdit `lib/services/spotify_auth_service.dart` line 4:Spotify requires HTTPS for OAuth. Deploy your app:- A welcoming home page with Material 3 styling

│   └── playlist_model.dart

├── screens/```dart

│   ├── home_page.dart

│   ├── login_page.dartstatic const String redirectUri = 'https://byflowt.github.io/spotify-ai-music-app/';- Intelligent search with artist suggestions

│   ├── search_page.dart

│   ├── track_detail_page.dart```

│   ├── my_playlist_page.dart

│   ├── ai_playlist_page.dart**Option A: Vercel (Recommended)**- Detailed artist pages with top tracks

│   └── song_search_page.dart

├── services/Then push:

│   ├── spotify_auth_service.dart

│   ├── spotify_service.dart```bash```bash- Smooth animations and transitions

│   ├── playlist_manager.dart

│   ├── ai_playlist_service.dartgit add .

│   ├── gemini_ai_service.dart

│   └── shazam_service.dartgit commit -m "Update redirect URI"flutter build web

├── utils/

│   └── [utility functions]git push origin main

└── widgets/

    └── [reusable components]```# Upload build/web folder to https://vercel.com## Getting Started 🚀

```



## 🔧 API Configuration

GitHub Actions will automatically rebuild and deploy! 🎉```

See [API_KEYS_SETUP.md](API_KEYS_SETUP.md) for detailed setup instructions including:



- Spotify Web API authentication

- Google Gemini AI integration## Tech Stack 💻### Prerequisites

- AUDD audio recognition setup

- Environment variable management with `.env`

- Secure API key practices

- Deployment configuration- **Flutter** - Cross-platform framework**Option B: GitHub Pages**



## 🌐 Live Demo- **Spotify Web API** - Music data & auth



**Web App**: https://byflowt.github.io/spotify-ai-music-app/- **Google Gemini AI** - Intelligent playlists```bash- Flutter SDK (3.0.0 or higher)



Deployed automatically to GitHub Pages on every push to main.- **Material 3** - Modern design system



## 📦 Dependencies- **GitHub Pages** - Free HTTPS hostingflutter build web- Dart SDK



### Core

- `flutter` - UI framework

- `provider` - State management## Developmentcd build/web- A Spotify Developer Account

- `http` - HTTP requests

- `google_generative_ai` - Gemini AI integration



### AuthenticationRun locally:git init && git add . && git commit -m "Deploy"

- `flutter_web_auth_2` - OAuth for web

- `flutter_secure_storage` - Secure storage```bash

- `shared_preferences` - Local storage

flutter pub getgit push -f https://github.com/USERNAME/repo.git main:gh-pages### Installation

### Audio & Media

- `audioplayers` - Audio playbackflutter run -d chrome

- `url_launcher` - Open URLs

``````

### UI

- `google_fonts` - Custom fonts

- `qr_flutter` - QR code generation

- `shimmer` - Loading animationsBuild for production:1. **Clone or navigate to the project directory**



### Configuration```bash

- `flutter_dotenv` - Environment variables

flutter build web --release### 3. Configure OAuth Redirect

## 🛠️ Development

```

### Run Tests

```bash2. **Get Spotify API Credentials**

flutter test

```---



### Format Code1. Add your HTTPS URL to `lib/services/spotify_auth_service.dart`:   - Visit [Spotify Developer Dashboard](https://developer.spotify.com/dashboard)

```bash

dart format lib/Made with ❤️ using Flutter & Spotify API

```

   ```dart   - Log in or create an account

### Analyze

```bash   static const String redirectUri = 'https://your-app.vercel.app/';   - Click "Create an App"

flutter analyze

```   ```   - Fill in the app name and description



### Build APK (Android)   - Copy your `Client ID` and `Client Secret`

```bash

flutter build apk --release2. Add same URL to Spotify Dashboard:

```

   - Go to https://developer.spotify.com/dashboard3. **Configure API Credentials**

### Build iOS

```bash   - Your app → Edit Settings → Redirect URIs   

flutter build ios --release

```   - Add: `https://your-app.vercel.app/`   Open `lib/services/spotify_service.dart` and replace the placeholders:



## 🚢 Deployment   - Save   



### Web (GitHub Pages)   ```dart



1. **Build release:**### 4. Run   static const String clientId = 'YOUR_CLIENT_ID_HERE';

   ```bash

   flutter build web --release   static const String clientSecret = 'YOUR_CLIENT_SECRET_HERE';

   ```

```bash   ```

2. **Deploy (automatic via GitHub Actions or manual):**

   ```bashflutter run -d chrome

   git add .

   git commit -m "Deploy: [version]"```4. **Install Dependencies**

   git push

   ```   



3. **Access your app:**## Features   ```bash

   ```

   https://byflowt.github.io/spotify-ai-music-app/   flutter pub get

   ```

✅ Search artists & songs     ```

### Web (Alternative: Vercel)

✅ View track details with QR codes  

1. **Build web:**

   ```bash✅ Audio preview player  5. **Run the App**

   flutter build web

   ```✅ Create & manage playlists     



2. **Deploy to Vercel:**✅ Spotify OAuth login     ```bash

   ```bash

   vercel deploy build/web✅ AI-powered playlist generation using Gemini     flutter run

   ```

   ```

### Android (Google Play)

## Tech Stack

1. **Create signed APK:**

   ```bash## Project Structure 📁

   flutter build apk --release

   ```- **Flutter** - Cross-platform UI framework



2. **Upload to Google Play Console**- **Spotify Web API** - Music data & authentication```



## 🔐 Security Notes- **Google Gemini AI** - Playlist intelligencelib/



- **Never commit `.env` file** - It contains your API keys- **Material 3** - Modern design system├── main.dart                 # App entry point with Material 3 theme

- Use environment variables for all sensitive data

- Spotify Client Secret should never be exposed in client code├── models/

- For production web, use a backend proxy for API calls│   ├── artist_model.dart    # Artist data model

- Rotate API keys regularly│   └── track_model.dart     # Track data model

- Use different keys for development and production├── screens/

│   ├── home_page.dart       # Welcome page with app introduction

## 📝 License│   ├── search_page.dart     # Artist search interface

│   └── artist_detail_page.dart  # Artist details and top tracks

[Add your license here]└── services/

    └── spotify_service.dart # Spotify API integration

## 🤝 Contributing```



Contributions are welcome! Please feel free to submit a Pull Request.## Dependencies 📦



## 📧 Contact- **flutter**: Core framework

- **google_fonts**: Beautiful typography (Inter font)

For questions or feedback, please open an issue on GitHub.- **provider**: State management

- **http**: API requests

---- **cached_network_image**: Efficient image loading and caching

- **shimmer**: Loading animations

**Built with ❤️ using Flutter**- **intl**: Internationalization


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
