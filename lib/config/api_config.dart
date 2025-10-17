import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized API configuration
/// Loads all API keys from environment variables (.env file)
class ApiConfig {
  // Spotify API
  static String get spotifyClientId =>
      dotenv.env['ce1797970d2d4ec8852fa68a54fe8a8f'] ?? '';
  
  static String get spotifyClientSecret =>
      dotenv.env['2eb0d963befb41f0998ddd703c8a8b7a'] ?? '';

  // Google Gemini AI
  static String get geminiApiKey =>
      dotenv.env['AIzaSyDaKqVBlnGR6UXq5XQjxo7mJDfgVZ9t0NU'] ?? '';

  // AUDD Audio Recognition
  static String get auddApiKey =>
      dotenv.env['3cb567377b824e96657c208fcf07d2bf'] ?? '';

  /// Validate that all required API keys are configured
  static List<String> validateConfiguration() {
    final missing = <String>[];

    if (spotifyClientId.isEmpty) {
      missing.add('ce1797970d2d4ec8852fa68a54fe8a8f');
    }
    if (spotifyClientSecret.isEmpty) {
      missing.add('2eb0d963befb41f0998ddd703c8a8b7a');
    }
    if (geminiApiKey.isEmpty) {
      missing.add('AIzaSyDaKqVBlnGR6UXq5XQjxo7mJDfgVZ9t0NU');
    }
    if (auddApiKey.isEmpty) {
      missing.add('3cb567377b824e96657c208fcf07d2bf');
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
