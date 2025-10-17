import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/artist_model.dart';
import '../models/track_model.dart';
import '../config/api_config.dart';

class SpotifyService extends ChangeNotifier {
  String? _accessToken;
  String? _userAccessToken;
  String? _userId;
  bool _isLoading = false;
  String? _error;
  
  // Search history
  final List<Artist> _lastSearchedArtists = [];
  final List<Track> _lastSearchedTracks = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Artist> get lastSearchedArtists => _lastSearchedArtists;
  List<Track> get lastSearchedTracks => _lastSearchedTracks;
  String? get userId => _userId;

  /// Get access token using Client Credentials Flow
  Future<void> _getAccessToken() async {
    if (kIsWeb) {
      html.window.console.log('🎵 [SPOTIFY] Getting access token for guest mode...');
    }
    
    try {
      final clientId = ApiConfig.spotifyClientId;
      final clientSecret = ApiConfig.spotifyClientSecret;
      
      // On web, if client secret is not available, skip guest mode
      // User must authenticate via OAuth instead
      if (kIsWeb && clientSecret.isEmpty) {
        if (kIsWeb) {
          html.window.console.log('⚠️ [SPOTIFY] Client credentials not available on web - user authentication required');
        }
        _error = 'Please login with Spotify to use this feature';
        notifyListeners();
        return;
      }
      
      if (clientId.isEmpty || clientSecret.isEmpty) {
        throw Exception('Spotify API keys not configured. Please set SPOTIFY_CLIENT_ID and SPOTIFY_CLIENT_SECRET in .env');
      }
      
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
      _error ??= 'Connection error: Please check your internet connection';
      
      if (kIsWeb) {
        html.window.console.error('❌ [SPOTIFY] Exception: $e');
      }
      
      notifyListeners();
      rethrow;
    }
  }

  /// Set user ID (called after login)
  void setUserId(String userId) {
    _userId = userId;
    notifyListeners();
  }

  /// Set user access token (called after login)
  void setUserAccessToken(String token) {
    _userAccessToken = token;
    notifyListeners();
  }

  /// Search for artists
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
        
        // Store in search history (keep last 5)
        if (artists.isNotEmpty) {
          for (final artist in artists.take(3)) {
            if (!_lastSearchedArtists.any((a) => a.id == artist.id)) {
              _lastSearchedArtists.insert(0, artist);
            }
          }
          if (_lastSearchedArtists.length > 5) {
            _lastSearchedArtists.removeRange(5, _lastSearchedArtists.length);
          }
        }
        
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
      final markets = ['US', 'GB', 'CA', 'AU', 'DE', 'FR', 'ES', 'SE', 'BR', 'MX', 'NL'];
      List<Track> bestTracks = [];
      int maxPreviewCount = 0;
      
      // Try first few markets and pick the one with most previews
      for (var market in markets.take(7)) {
        try {
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
              print('Artist $artistId - Market $market: $previewCount/${tracks.length} tracks with previews');
            }
            
            // Keep the best result so far (even if no previews)
            if (tracks.isNotEmpty && (tracks.length > bestTracks.length || previewCount > maxPreviewCount)) {
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
          } else {
            if (kDebugMode) {
              print('Market $market failed with status ${response.statusCode}');
            }
          }
        } catch (marketError) {
          if (kDebugMode) {
            print('Error trying market $market: $marketError');
          }
          // Continue to next market
        }
        
        // Small delay to avoid rate limiting
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      if (kDebugMode) {
        print('Final result for artist $artistId: ${bestTracks.length} tracks');
      }
      
      _isLoading = false;
      notifyListeners();
      return bestTracks;
    } catch (e) {
      _error = 'Error loading tracks: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      if (kDebugMode) {
        print('Error in getArtistTopTracks: $e');
      }
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
        
        // Store in search history (keep last 5)
        if (tracks.isNotEmpty) {
          for (final track in tracks.take(3)) {
            if (!_lastSearchedTracks.any((t) => t.id == track.id)) {
              _lastSearchedTracks.insert(0, track);
            }
          }
          if (_lastSearchedTracks.length > 5) {
            _lastSearchedTracks.removeRange(5, _lastSearchedTracks.length);
          }
        }
        
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
        // Clean genre names - remove any special characters that might cause issues
        final cleanGenres = seedGenres
            .take(1)
            .map((g) => g.toLowerCase().replaceAll(RegExp(r'[^a-z0-9-]'), ''))
            .where((g) => g.isNotEmpty)
            .toList();
        if (cleanGenres.isNotEmpty) {
          params['seed_genres'] = cleanGenres.join(',');
        }
      }

      final uri = Uri.https(
        'api.spotify.com',
        '/v1/recommendations',
        params,
      );
      
      if (kDebugMode) {
        print('Recommendations URL: $uri');
      }

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

  // Get current user's profile
  Future<Map<String, dynamic>?> getCurrentUserProfile({
    required String userAccessToken,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.spotify.com/v1/me'),
        headers: {
          'Authorization': 'Bearer $userAccessToken',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        if (kDebugMode) {
          print('Error getting user profile: ${response.statusCode}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user profile: $e');
      }
      return null;
    }
  }

  // Create a new playlist on user's Spotify account
  Future<String?> createPlaylist({
    required String userAccessToken,
    required String userId,
    required String playlistName,
    String description = '',
    bool isPublic = false,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.spotify.com/v1/users/$userId/playlists'),
        headers: {
          'Authorization': 'Bearer $userAccessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': playlistName,
          'description': description,
          'public': isPublic,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['id']; // Return playlist ID
      } else {
        if (kDebugMode) {
          print('Error creating playlist: ${response.statusCode} - ${response.body}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error creating playlist: $e');
      }
      return null;
    }
  }

  // Add tracks to a Spotify playlist
  Future<bool> addTracksToPlaylist({
    required String userAccessToken,
    required String playlistId,
    required List<String> trackUris,
  }) async {
    try {
      // Spotify API allows max 100 tracks per request
      final batches = <List<String>>[];
      for (var i = 0; i < trackUris.length; i += 100) {
        batches.add(
          trackUris.sublist(
            i,
            i + 100 > trackUris.length ? trackUris.length : i + 100,
          ),
        );
      }

      for (var batch in batches) {
        final response = await http.post(
          Uri.parse('https://api.spotify.com/v1/playlists/$playlistId/tracks'),
          headers: {
            'Authorization': 'Bearer $userAccessToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'uris': batch,
          }),
        );

        if (response.statusCode != 200 && response.statusCode != 201) {
          if (kDebugMode) {
            print('Error adding tracks to playlist: ${response.statusCode} - ${response.body}');
          }
          return false;
        }
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error adding tracks to playlist: $e');
      }
      return false;
    }
  }
}

