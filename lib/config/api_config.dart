import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Centralized API configuration
/// Loads all API keys from environment variables (.env file)
class ApiConfig {
  // Helper to safely get env variables
  static String _getEnv(String key, {String webDefault = ''}) {
    try {
      return dotenv.env[key] ?? webDefault;
    } catch (e) {
      // On web, dotenv may not be initialized - use web defaults
      if (kIsWeb) {
        return webDefault;
      }
      rethrow;
    }
  }

  // Spotify API
  // NOTE: Client ID is safe to expose (public), but Client Secret should NEVER be in web builds
  // For web: Users must use Spotify OAuth (user authentication) instead of Client Credentials
  static String get spotifyClientId => _getEnv(
    'SPOTIFY_CLIENT_ID',
    webDefault: kIsWeb ? 'ce1797970d2d4ec8852fa68a54fe8a8f' : '',
  );
  
  // SECURITY: Client Secret should NEVER be exposed on web
  // This will be empty on web - app must use user authentication instead
  static String get spotifyClientSecret => _getEnv(
    'SPOTIFY_CLIENT_SECRET',
    webDefault: '', // Empty on web for security
  );

  // Google Gemini AI - Not safe to expose, will be empty on web
  static String get geminiApiKey => _getEnv('GEMINI_API_KEY');

  // AUDD Audio Recognition - Not safe to expose, will be empty on web
  static String get auddApiKey => _getEnv('AUDD_API_KEY');

  /// Validate that all required API keys are configured
  static List<String> validateConfiguration() {
    final missing = <String>[];

    if (spotifyClientId.isEmpty) {
      missing.add('SPOTIFY_CLIENT_ID');
    }
    // On web, Client Secret should be empty (users authenticate via OAuth)
    if (!kIsWeb && spotifyClientSecret.isEmpty) {
      missing.add('SPOTIFY_CLIENT_SECRET');
    }
    // Gemini and AUDD are optional on web (features won't work without them)
    if (!kIsWeb && geminiApiKey.isEmpty) {
      missing.add('GEMINI_API_KEY');
    }
    if (!kIsWeb && auddApiKey.isEmpty) {
      missing.add('AUDD_API_KEY');
    }

    return missing;
  }

  /// Log configuration status (for debugging)
  static void logStatus() {
    print('=== API Configuration Status ===');
    print('Platform: ${kIsWeb ? 'Web' : 'Native'}');
    print('Spotify Client ID: ${spotifyClientId.isEmpty ? '❌ MISSING' : '✅ Configured'}');
    if (!kIsWeb) {
      print('Spotify Client Secret: ${spotifyClientSecret.isEmpty ? '❌ MISSING' : '✅ Configured'}');
      print('Gemini API Key: ${geminiApiKey.isEmpty ? '❌ MISSING' : '✅ Configured'}');
      print('AUDD API Key: ${auddApiKey.isEmpty ? '⚠️  Optional' : '✅ Configured'}');
    } else {
      print('Spotify Client Secret: [Hidden for security - OAuth used]');
      print('Gemini API Key: ${geminiApiKey.isEmpty ? '⚠️  Not available (AI features disabled)' : '✅ Configured'}');
      print('AUDD API Key: ${auddApiKey.isEmpty ? '⚠️  Not available (audio recognition disabled)' : '✅ Configured'}');
    }
    print('================================');
  }
}
