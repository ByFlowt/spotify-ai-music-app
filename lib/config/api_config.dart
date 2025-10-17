import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized API configuration
/// Loads all API keys from environment variables (.env file)
class ApiConfig {
  // Spotify API
  static String get spotifyClientId =>
      dotenv.env['SPOTIFY_CLIENT_ID'] ?? '';
  
  static String get spotifyClientSecret =>
      dotenv.env['SPOTIFY_CLIENT_SECRET'] ?? '';

  // Google Gemini AI
  static String get geminiApiKey =>
      dotenv.env['GEMINI_API_KEY'] ?? '';

  // AUDD Audio Recognition
  static String get auddApiKey =>
      dotenv.env['AUDD_API_KEY'] ?? '';

  /// Validate that all required API keys are configured
  static List<String> validateConfiguration() {
    final missing = <String>[];

    if (spotifyClientId.isEmpty) {
      missing.add('SPOTIFY_CLIENT_ID');
    }
    if (spotifyClientSecret.isEmpty) {
      missing.add('SPOTIFY_CLIENT_SECRET');
    }
    if (geminiApiKey.isEmpty) {
      missing.add('GEMINI_API_KEY');
    }
    if (auddApiKey.isEmpty) {
      missing.add('AUDD_API_KEY (optional for audio search)');
    }

    return missing;
  }

  /// Log configuration status (for debugging)
  static void logStatus() {
    print('=== API Configuration Status ===');
    print('Spotify Client ID: ${spotifyClientId.isEmpty ? '❌ MISSING' : '✅ Configured'}');
    print('Spotify Client Secret: ${spotifyClientSecret.isEmpty ? '❌ MISSING' : '✅ Configured'}');
    print('Gemini API Key: ${geminiApiKey.isEmpty ? '❌ MISSING' : '✅ Configured'}');
    print('AUDD API Key: ${auddApiKey.isEmpty ? '⚠️  Optional' : '✅ Configured'}');
    print('================================');
  }
}
