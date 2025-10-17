import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/track_model.dart';
import '../config/api_config.dart';

class ShazamService extends ChangeNotifier {
  static const String _baseUrl = 'https://api.audd.io';
  
  bool _isLoading = false;
  String? _error;
  
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Search songs by audio (using file or URL)
  /// Requires AUDD_API_KEY to be configured in .env
  Future<List<Track>> recognizeAudio(String audioUrl) async {
    final apiKey = ApiConfig.auddApiKey;
    
    if (apiKey.isEmpty) {
      _error = 'AUDD API key not configured. Please set AUDD_API_KEY in .env file';
      notifyListeners();
      return [];
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/?method=recognizeSong&return=spotify&file_url=$audioUrl&api_token=$apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['status'] == 'success' && data['result'] != null) {
          final result = data['result'];
          
          // Extract track information
          final track = Track(
            id: result['spotify_id'] ?? result['title']?.replaceAll(' ', '_') ?? 'unknown',
            name: result['title'] ?? 'Unknown Track',
            artistName: result['artist'] ?? 'Unknown Artist',
            albumName: result['album'],
            imageUrl: result['spotify']?['image'],
            spotifyUrl: 'https://open.spotify.com/track/${result['spotify_id']}',
            previewUrl: result['preview_url'],
            popularity: 75, // Default popularity
            durationMs: result['duration'] ?? 0,
          );
          
          _isLoading = false;
          notifyListeners();
          return [track];
        }
      }
      
      _error = 'Could not recognize audio';
      _isLoading = false;
      notifyListeners();
      return [];
      
    } catch (e) {
      _error = 'Error recognizing audio: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      if (kDebugMode) {
        print('🎵 [SHAZAM] Error: $e');
      }
      return [];
    }
  }
  
  /// Search songs by title and artist (simple search)
  Future<List<Track>> searchByAudio(String title, String artist) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Using a free music API as alternative (MusixMatch, Last.fm, or MusicBrainz)
      final query = '$title $artist'.replaceAll(' ', '+');
      
      // Example using a free API endpoint
      final response = await http.get(
        Uri.parse('https://musicbrainz.org/ws/2/recording?query=$query&limit=5&fmt=json'),
        headers: {
          'User-Agent': 'SpotifyAI/1.0',
        },
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        _isLoading = false;
        notifyListeners();
        // Parse MusicBrainz response and return tracks
        return [];
      }
      
      _error = 'Could not search for audio';
      _isLoading = false;
      notifyListeners();
      return [];
      
    } catch (e) {
      _error = 'Error searching: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      if (kDebugMode) {
        print('🎵 [AUDIO SEARCH] Error: $e');
      }
      return [];
    }
  }
  
  /// Get song info from audio fingerprint
  /// Note: This would require actual Shazam API credentials from RapidAPI
  Future<Map<String, dynamic>> getAudioFingerprint(String audioFile) async {
    try {
      // In production, this would use actual Shazam API
      // For now, returning a placeholder
      if (kDebugMode) {
        print('🎵 [AUDIO FINGERPRINT] Processing: $audioFile');
      }
      
      return {
        'title': 'Unknown',
        'artist': 'Unknown',
        'album': null,
      };
    } catch (e) {
      if (kDebugMode) {
        print('🎵 [AUDIO FINGERPRINT] Error: $e');
      }
      return {};
    }
  }
}
