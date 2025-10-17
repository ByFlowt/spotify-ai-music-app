import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Secure API Proxy Service
/// Routes API calls through a backend proxy when on web to hide API keys
class ApiProxyService {
  // TODO: Replace with your actual Vercel deployment URL
  static const String _vercelProxyUrl = 'https://your-app.vercel.app';
  
  // For local development
  static const String _localProxyUrl = 'http://localhost:3000';
  
  /// Get the proxy base URL
  static String get baseUrl {
    // In production web build, use Vercel
    // In development or native, use local or direct API calls
    if (kIsWeb && const bool.fromEnvironment('dart.vm.product')) {
      return _vercelProxyUrl;
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
