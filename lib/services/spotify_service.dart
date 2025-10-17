import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/artist_model.dart';
import '../models/track_model.dart';

class SpotifyService extends ChangeNotifier {
  String? _accessToken;
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  // Note: In production, store these securely and use a backend proxy
  // For this demo, you'll need to get your own credentials from Spotify Developer Dashboard
  // Visit: https://developer.spotify.com/dashboard
  static const String clientId = 'ce1797970d2d4ec8852fa68a54fe8a8f';
  static const String clientSecret = '2eb0d963befb41f0998ddd703c8a8b7a';

  // Get access token using Client Credentials Flow
  Future<void> _getAccessToken() async {
    if (kIsWeb) {
      html.window.console.log('🎵 [SPOTIFY] Getting access token for guest mode...');
    }
    
    try {
      final credentials = base64Encode(utf8.encode('$clientId:$clientSecret'));
      
      if (kIsWeb) {
        html.window.console.log('🎵 [SPOTIFY] Requesting token from Spotify API...');
      }
      
      final response = await http.post(
        Uri.parse('https://accounts.spotify.com/api/token'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': 'Basic $credentials',
        },
        body: {'grant_type': 'client_credentials'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['access_token'];
        _error = null;
        
        if (kIsWeb) {
          html.window.console.log('✅ [SPOTIFY] Access token obtained successfully');
        }
      } else {
        final errorData = jsonDecode(response.body);
        _error = 'Spotify API Error: ${errorData['error_description'] ?? 'Invalid credentials'}';
        
        if (kIsWeb) {
          html.window.console.error('❌ [SPOTIFY] API Error: $_error');
        }
        
        notifyListeners();
        throw Exception('Failed to get access token: ${response.statusCode}');
      }
    } catch (e) {
      if (_error == null) {
        _error = 'Connection error: Please check your internet connection';
      }
      
      if (kIsWeb) {
        html.window.console.error('❌ [SPOTIFY] Exception: $e');
      }
      
      notifyListeners();
      rethrow;
    }
  }

  // Search for artists
  Future<List<Artist>> searchArtists(String query) async {
    if (query.trim().isEmpty) return [];

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Get token if not available
      if (_accessToken == null) {
        await _getAccessToken();
      }

      final response = await http.get(
        Uri.parse(
          'https://api.spotify.com/v1/search?q=${Uri.encodeComponent(query)}&type=artist&limit=20',
        ),
        headers: {
          'Authorization': 'Bearer $_accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final artistsJson = data['artists']['items'] as List;
        final artists = artistsJson.map((json) => Artist.fromJson(json)).toList();
        
        _isLoading = false;
        notifyListeners();
        return artists;
      } else if (response.statusCode == 401) {
        // Token expired, get new one and retry
        _accessToken = null;
        await _getAccessToken();
        return searchArtists(query);
      } else {
        throw Exception('Failed to search artists');
      }
    } catch (e) {
      _error = 'Search error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return [];
    }
  }

  // Get artist's top tracks with optimized preview availability
  Future<List<Track>> getArtistTopTracks(String artistId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (_accessToken == null) {
        await _getAccessToken();
      }

      // Try multiple markets to find previews
      // Markets are ordered by preview availability (US usually has best availability)
      final markets = ['US', 'GB', 'CA', 'AU', 'DE', 'FR', 'ES', 'SE', 'BR', 'MX'];
      List<Track> bestTracks = [];
      int maxPreviewCount = 0;
      
      // Try first few markets and pick the one with most previews
      for (var market in markets.take(5)) {
        final response = await http.get(
          Uri.parse(
            'https://api.spotify.com/v1/artists/$artistId/top-tracks?market=$market',
          ),
          headers: {
            'Authorization': 'Bearer $_accessToken',
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final tracksJson = data['tracks'] as List;
          final tracks = tracksJson.map((json) => Track.fromJson(json)).toList();
          
          // Count tracks with previews
          final previewCount = tracks.where((t) => t.previewUrl != null).length;
          
          if (kDebugMode) {
            print('Market $market: $previewCount/${tracks.length} tracks with previews');
          }
          
          // Keep the best result so far
          if (previewCount > maxPreviewCount) {
            maxPreviewCount = previewCount;
            bestTracks = tracks;
          }
          
          // If we have previews for most tracks, stop searching
          if (previewCount >= 7) {
            break;
          }
        } else if (response.statusCode == 401) {
          _accessToken = null;
          await _getAccessToken();
          return getArtistTopTracks(artistId);
        }
        
        // Small delay to avoid rate limiting
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      _isLoading = false;
      notifyListeners();
      return bestTracks;
    } catch (e) {
      _error = 'Error loading tracks: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return [];
    }
  }

  // Get artist details
  Future<Artist?> getArtistDetails(String artistId) async {
    try {
      if (_accessToken == null) {
        await _getAccessToken();
      }

      final response = await http.get(
        Uri.parse('https://api.spotify.com/v1/artists/$artistId'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Artist.fromJson(data);
      } else if (response.statusCode == 401) {
        _accessToken = null;
        await _getAccessToken();
        return getArtistDetails(artistId);
      }
    } catch (e) {
      _error = 'Error loading artist: ${e.toString()}';
      notifyListeners();
    }
    return null;
  }

  // Search for tracks by name with better preview availability
  Future<List<Track>> searchTracks(String query, {String? market}) async {
    if (query.trim().isEmpty) return [];

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (_accessToken == null) {
        await _getAccessToken();
      }

      // Use specific market for better preview availability
      final marketParam = market ?? 'US';
      
      final response = await http.get(
        Uri.parse(
          'https://api.spotify.com/v1/search?q=${Uri.encodeComponent(query)}&type=track&limit=20&market=$marketParam',
        ),
        headers: {
          'Authorization': 'Bearer $_accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final tracksJson = data['tracks']['items'] as List;
        final tracks = tracksJson.map((json) => Track.fromJson(json)).toList();
        
        _isLoading = false;
        notifyListeners();
        return tracks;
      } else if (response.statusCode == 401) {
        _accessToken = null;
        await _getAccessToken();
        return searchTracks(query, market: market);
      } else {
        throw Exception('Failed to search tracks');
      }
    } catch (e) {
      _error = 'Track search error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return [];
    }
  }

  // Get recommendations based on seed artists, tracks, and genres
  Future<List<Track>> getRecommendations({
    List<String>? seedArtists,
    List<String>? seedTracks,
    List<String>? seedGenres,
    int limit = 20,
    String market = 'US',
  }) async {
    try {
      if (_accessToken == null) {
        await _getAccessToken();
      }

      final params = <String, String>{
        'limit': limit.toString(),
        'market': market,
      };

      if (seedArtists != null && seedArtists.isNotEmpty) {
        params['seed_artists'] = seedArtists.take(2).join(',');
      }
      if (seedTracks != null && seedTracks.isNotEmpty) {
        params['seed_tracks'] = seedTracks.take(2).join(',');
      }
      if (seedGenres != null && seedGenres.isNotEmpty) {
        params['seed_genres'] = seedGenres.take(1).join(',');
      }

      final uri = Uri.https(
        'api.spotify.com',
        '/v1/recommendations',
        params,
      );

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $_accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final tracksJson = data['tracks'] as List;
        return tracksJson.map((json) => Track.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        _accessToken = null;
        await _getAccessToken();
        return getRecommendations(
          seedArtists: seedArtists,
          seedTracks: seedTracks,
          seedGenres: seedGenres,
          limit: limit,
          market: market,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting recommendations: $e');
      }
    }
    return [];
  }

  // Get available genre seeds
  Future<List<String>> getAvailableGenres() async {
    try {
      if (_accessToken == null) {
        await _getAccessToken();
      }

      final response = await http.get(
        Uri.parse('https://api.spotify.com/v1/recommendations/available-genre-seeds'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data['genres']);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting genres: $e');
      }
    }
    return [];
  }

  // Get audio features for tracks (for AI analysis)
  Future<Map<String, dynamic>?> getAudioFeatures(String trackId) async {
    try {
      if (_accessToken == null) {
        await _getAccessToken();
      }

      final response = await http.get(
        Uri.parse('https://api.spotify.com/v1/audio-features/$trackId'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting audio features: $e');
      }
    }
    return null;
  }

  // Simulate getting user's top genres (in real app, would use user authentication)
  List<String> getSimulatedTopGenres() {
    return [
      'pop',
      'rock',
      'hip-hop',
      'electronic',
      'indie',
      'r-n-b',
      'dance',
      'jazz',
    ];
  }

  // ===== USER AUTHENTICATED ENDPOINTS =====
  // These require user OAuth token from SpotifyAuthService
  
  // Get user's top tracks (requires user auth)
  Future<List<Track>> getUserTopTracks({
    required String userAccessToken,
    String timeRange = 'medium_term',  // short_term, medium_term, long_term
    int limit = 20,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.spotify.com/v1/me/top/tracks?time_range=$timeRange&limit=$limit',
        ),
        headers: {
          'Authorization': 'Bearer $userAccessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final tracksJson = data['items'] as List;
        return tracksJson.map((json) => Track.fromJson(json)).toList();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user top tracks: $e');
      }
    }
    return [];
  }

  // Get user's recently played tracks (requires user auth)
  Future<List<Track>> getUserRecentlyPlayed({
    required String userAccessToken,
    int limit = 50,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.spotify.com/v1/me/player/recently-played?limit=$limit',
        ),
        headers: {
          'Authorization': 'Bearer $userAccessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = data['items'] as List;
        return items.map((item) => Track.fromJson(item['track'])).toList();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting recently played: $e');
      }
    }
    return [];
  }

  // Get user's top artists (requires user auth)
  Future<List<Artist>> getUserTopArtists({
    required String userAccessToken,
    String timeRange = 'medium_term',
    int limit = 20,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.spotify.com/v1/me/top/artists?time_range=$timeRange&limit=$limit',
        ),
        headers: {
          'Authorization': 'Bearer $userAccessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final artistsJson = data['items'] as List;
        return artistsJson.map((json) => Artist.fromJson(json)).toList();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user top artists: $e');
      }
    }
    return [];
  }

  // Extract genres from user's top artists
  Future<List<String>> getUserTopGenres({
    required String userAccessToken,
  }) async {
    final artists = await getUserTopArtists(
      userAccessToken: userAccessToken,
      limit: 50,
    );
    
    final Map<String, int> genreCount = {};
    for (var artist in artists) {
      for (var genre in artist.genres) {
        genreCount[genre] = (genreCount[genre] ?? 0) + 1;
      }
    }
    
    // Sort by frequency and return top genres
    final sortedGenres = genreCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedGenres.take(10).map((e) => e.key).toList();
  }
}

