import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Secure API Proxy Service
/// Routes API calls through a backend proxy when on web to hide API keys
class ApiProxyService {
  // Your Vercel deployment URL (without https://) - stable production domain
  static const String _vercelProxyUrl = 'backendproxy.vercel.app';
  
  // For local development
  static const String _localProxyUrl = 'http://localhost:3000';
  
  /// Get the proxy base URL
  static String get baseUrl {
    // In production web build, use Vercel
    // In development or native, use local or direct API calls
    if (kIsWeb && const bool.fromEnvironment('dart.vm.product')) {
      return 'https://$_vercelProxyUrl';
    }
    return _localProxyUrl;
  }
  
  /// Check if proxy should be used (web production builds)
  static bool get useProxy {
    return kIsWeb && const bool.fromEnvironment('dart.vm.product');
  }

  /// Call Gemini AI through proxy
  /// 
  /// Example:
  /// ```dart
  /// final result = await ApiProxyService.callGemini(
  ///   prompt: 'Create a chill playlist',
  /// );
  /// ```
  static Future<Map<String, dynamic>> callGemini({
    required String prompt,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/gemini'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'prompt': prompt,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Gemini API error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to call Gemini API: $e');
    }
  }

  /// Call AUDD audio recognition through proxy
  /// 
  /// Example:
  /// ```dart
  /// final result = await ApiProxyService.recognizeAudio(
  ///   audioBase64: base64AudioData,
  /// );
  /// ```
  static Future<Map<String, dynamic>> recognizeAudio({
    required String audioBase64,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/audd'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'audio': audioBase64,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('AUDD API error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to recognize audio: $e');
    }
  }

  /// Exchange Spotify authorization code for tokens through proxy
  /// 
  /// Example:
  /// ```dart
  /// final tokens = await ApiProxyService.exchangeSpotifyCode(
  ///   code: authCode,
  ///   redirectUri: 'https://byflowt.github.io/spotify-ai-music-app/',
  ///   codeVerifier: pkceVerifier,
  /// );
  /// ```
  static Future<Map<String, dynamic>> exchangeSpotifyCode({
    required String code,
    required String redirectUri,
    required String codeVerifier,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://$_vercelProxyUrl/api/spotify-token'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'grant_type': 'authorization_code',
          'code': code,
          'redirect_uri': redirectUri,
          'code_verifier': codeVerifier,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception('Spotify token exchange error: ${error['error'] ?? response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to exchange Spotify code: $e');
    }
  }

  /// Refresh Spotify access token through proxy
  /// 
  /// Example:
  /// ```dart
  /// final newTokens = await ApiProxyService.refreshSpotifyToken(
  ///   refreshToken: userRefreshToken,
  /// );
  /// ```
  static Future<Map<String, dynamic>> refreshSpotifyToken({
    required String refreshToken,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://$_vercelProxyUrl/api/spotify-token'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception('Spotify token refresh error: ${error['error'] ?? response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to refresh Spotify token: $e');
    }
  }

  /// Health check for the proxy service
  static Future<bool> checkProxyHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/health'),
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
