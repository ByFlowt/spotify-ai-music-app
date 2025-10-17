import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/track_model.dart';
import '../models/artist_model.dart';
import 'spotify_service.dart';
import 'playlist_manager.dart';
import 'spotify_auth_service.dart';
import 'gemini_ai_service.dart';

class AIPlaylistService extends ChangeNotifier {
  final SpotifyService _spotifyService;
  final PlaylistManager _playlistManager;
  final SpotifyAuthService _authService;
  final GeminiAIService _geminiService;
  
  bool _isGenerating = false;
  double _progress = 0.0;
  String _currentStep = '';
  List<Track> _generatedTracks = [];
  Map<String, double> _genrePreferences = {};
  
  bool get isGenerating => _isGenerating;
  double get progress => _progress;
  String get currentStep => _currentStep;
  List<Track> get generatedTracks => _generatedTracks;
  Map<String, double> get genrePreferences => _genrePreferences;

  AIPlaylistService(
    this._spotifyService,
    this._playlistManager,
    this._authService,
    this._geminiService,
  );

  // Simulate listening history analysis (in production, use real user data)
  Future<Map<String, dynamic>> analyzeListeningHistory() async {
    _currentStep = 'Analyzing your listening history...';
    _progress = 0.1;
    notifyListeners();
    
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Simulate user's listening patterns
    final listeningHistory = _playlistManager.playlist;
    
    // Extract genres from playlist
    final Map<String, int> genreCounts = {};
    for (var _ in listeningHistory) {
      // Simulate genre extraction (in real app, use artist info)
      final simulatedGenres = ['pop', 'rock', 'electronic', 'hip-hop', 'indie'];
      final genre = simulatedGenres[Random().nextInt(simulatedGenres.length)];
      genreCounts[genre] = (genreCounts[genre] ?? 0) + 1;
    }
    
    // Calculate preferences (normalize to 0-1)
    final total = genreCounts.values.fold(0, (sum, count) => sum + count);
    if (total > 0) {
      _genrePreferences = genreCounts.map(
        (genre, count) => MapEntry(genre, count / total),
      );
    } else {
      // Default preferences if no history
      _genrePreferences = {
        'pop': 0.3,
        'rock': 0.2,
        'electronic': 0.2,
        'hip-hop': 0.15,
        'indie': 0.15,
      };
    }
    
    return {
      'totalTracks': listeningHistory.length,
      'topGenres': _genrePreferences.entries
          .toList()
          ..sort((a, b) => b.value.compareTo(a.value)),
      'diversity': _genrePreferences.length,
    };
  }

  // AI-powered smart playlist generation using Gemini AI
  Future<List<Track>> generateSmartPlaylist({
    int targetSize = 30,
    String mood = 'balanced',
    bool includeNewDiscoveries = true,
  }) async {
    _isGenerating = true;
    _generatedTracks = [];
    _progress = 0.0;
    notifyListeners();

    try {
      // Step 1: Get user's listening data from Spotify
      _currentStep = 'Analyzing your music taste...';
      _progress = 0.1;
      notifyListeners();
      
      final userData = await _getUserListeningData();
      
      if (userData == null) {
        throw Exception('Unable to load your listening history. Please log in.');
      }
      
      // Step 2: Ask Gemini AI for song recommendations
      _currentStep = 'Asking AI for personalized recommendations...';
      _progress = 0.3;
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (kDebugMode) {
        print('🤖 Sending listening data to Gemini AI...');
      }
      
      final geminiRecommendations = await _geminiService.generateSongRecommendations(
        topTracks: userData['topTracks'] as List<Map<String, dynamic>>,
        topArtists: userData['topArtists'] as List<Map<String, dynamic>>,
        recentTracks: userData['recentTracks'] as List<Map<String, dynamic>>,
        mood: mood,
        targetCount: targetSize,
      );
      
      if (kDebugMode) {
        print('✅ Received ${geminiRecommendations.length} recommendations');
      }
      
      // If Gemini hit rate limits, we'll get fallback recommendations
      if (geminiRecommendations.isEmpty) {
        throw Exception('Unable to generate recommendations at this time. Please try again in a moment.');
      }
      
      // Step 3: Search Spotify for each recommendation
      _currentStep = 'Finding songs on Spotify...';
      _progress = 0.5;
      notifyListeners();
      
      final foundTracks = <Track>[];
      int searchedCount = 0;
      
      for (final recommendation in geminiRecommendations) {
        try {
          // Update progress
          searchedCount++;
          _progress = 0.5 + (searchedCount / geminiRecommendations.length * 0.4);
          notifyListeners();
          
          // Search Spotify for this song
          final query = '${recommendation['title']} ${recommendation['artist']}';
          final searchResults = await _spotifyService.searchTracks(query, market: 'NL');
          
          if (searchResults.isNotEmpty) {
            // Take the first (best) match
            foundTracks.add(searchResults.first);
            
            if (kDebugMode) {
              print('✅ Found: ${searchResults.first.name} by ${searchResults.first.artistName}');
            }
          } else {
            if (kDebugMode) {
              print('❌ Not found: ${recommendation['title']} by ${recommendation['artist']}');
            }
          }
          
          // Don't spam Spotify API
          await Future.delayed(const Duration(milliseconds: 100));
          
        } catch (e) {
          if (kDebugMode) {
            print('⚠️  Error searching for ${recommendation['title']}: $e');
          }
        }
      }
      
      // Step 4: Remove duplicates and filter
      _currentStep = 'Curating your playlist...';
      _progress = 0.92;
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 300));
      
      _generatedTracks = _removeDuplicates(foundTracks);
      
      // Step 5: Optimize track order
      _currentStep = 'Optimizing playlist flow...';
      _progress = 0.96;
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 300));
      
      _generatedTracks = _optimizeTrackOrder(_generatedTracks);
      
      _currentStep = 'Playlist ready! 🎉';
      _progress = 1.0;
      _isGenerating = false;
      notifyListeners();
      
      if (kDebugMode) {
        print('🎵 Generated playlist with ${_generatedTracks.length} tracks');
      }
      
      return _generatedTracks;
      
    } catch (e) {
      if (kDebugMode) {
        print('Error generating playlist: $e');
      }
      _currentStep = 'Error generating playlist';
      _isGenerating = false;
      notifyListeners();
      return [];
    }
  }

  // Get user's listening data from Spotify
  Future<Map<String, List<Map<String, dynamic>>>?> _getUserListeningData() async {
    try {
      final userToken = _authService.accessToken;
      if (userToken == null || !_authService.isAuthenticated) {
        if (kDebugMode) {
          print('⚠️  User not authenticated');
        }
        return null;
      }
      
      // Fetch user's data in parallel
      final results = await Future.wait([
        _spotifyService.getUserTopTracks(
          userAccessToken: userToken,
          timeRange: 'medium_term',
          limit: 20,
        ),
        _spotifyService.getUserTopArtists(
          userAccessToken: userToken,
          timeRange: 'medium_term',
          limit: 15,
        ),
        _spotifyService.getUserRecentlyPlayed(
          userAccessToken: userToken,
          limit: 20,
        ),
      ]);
      
      final topTracks = results[0] as List<Track>;
      final topArtists = results[1] as List<Artist>;
      final recentTracks = results[2] as List<Track>;
      
      // Convert to format Gemini expects
      return {
        'topTracks': topTracks.map((t) => {
          'name': t.name,
          'artist': t.artistName,
          'id': t.id,
        }).toList(),
        'topArtists': topArtists.map((a) => {
          'name': a.name,
          'id': a.id,
          'genres': a.genres,
        }).toList(),
        'recentTracks': recentTracks.map((t) => {
          'name': t.name,
          'artist': t.artistName,
          'id': t.id,
        }).toList(),
      };
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching user listening data: $e');
      }
      return null;
    }
  }
  
  // Remove duplicate tracks
  List<Track> _removeDuplicates(List<Track> tracks) {
    final seen = <String>{};
    final unique = <Track>[];
    
    for (final track in tracks) {
      if (!seen.contains(track.id)) {
        seen.add(track.id);
        unique.add(track);
      }
    }
    
    // Also remove tracks already in user's playlist
    final userTrackIds = _playlistManager.playlist.map((t) => t.id).toSet();
    return unique.where((t) => !userTrackIds.contains(t.id)).toList();
  }

  Map<String, dynamic> _getMoodParameters(String mood) {
    switch (mood) {
      case 'energetic':
        return {
          'energy': 0.8,
          'valence': 0.7,
          'tempo': 'fast',
          'danceability': 0.7,
        };
      case 'chill':
        return {
          'energy': 0.3,
          'valence': 0.5,
          'tempo': 'slow',
          'acousticness': 0.6,
        };
      case 'focus':
        return {
          'energy': 0.5,
          'valence': 0.4,
          'instrumentalness': 0.5,
          'speechiness': 0.2,
        };
      case 'party':
        return {
          'energy': 0.9,
          'valence': 0.9,
          'danceability': 0.9,
          'tempo': 'fast',
        };
      default: // balanced
        return {
          'energy': 0.5,
          'valence': 0.6,
          'danceability': 0.6,
        };
    }
  }

  Future<Map<String, List<String>>> _getSeedData(Map<String, dynamic> analysis) async {
    // Try to get real user data first
    try {
      final userToken = _authService.accessToken;
      if (userToken != null && _authService.isAuthenticated) {
        final userTopTracks = await _spotifyService.getUserTopTracks(
          userAccessToken: userToken,
          limit: 3,
        );
        final userTopArtists = await _spotifyService.getUserTopArtists(
          userAccessToken: userToken,
          limit: 2,
        );
        
        if (userTopTracks.isNotEmpty || userTopArtists.isNotEmpty) {
          // Use real user data
          final seedTracks = userTopTracks.take(2).map((t) => t.id).toList();
          final seedArtists = userTopArtists.take(2).map((a) => a.id).toList();
          
          // Get genres from top artists and map to valid Spotify genres
          final artistGenres = userTopArtists
              .expand((artist) => artist.genres)
              .toSet()
              .toList();
          
          final topGenres = _mapToValidSpotifyGenres(artistGenres)
              .take(2)
              .toList();
          
          if (kDebugMode) {
            print('Artist genres: $artistGenres');
            print('Mapped to valid genres: $topGenres');
          }
          
          return {
            'genres': topGenres.isNotEmpty ? topGenres : _getDefaultGenres(),
            'tracks': seedTracks,
            'artists': seedArtists,
          };
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Could not fetch user data, using fallback: $e');
      }
    }
    
    // Fallback to simulated data
    final topGenres = (analysis['topGenres'] as List)
        .take(2)
        .map((e) => e.key as String)
        .toList();
    
    // Add discovery genres if needed
    final allGenres = _spotifyService.getSimulatedTopGenres();
    if (topGenres.length < 2) {
      final random = Random();
      while (topGenres.length < 2) {
        final genre = allGenres[random.nextInt(allGenres.length)];
        if (!topGenres.contains(genre)) {
          topGenres.add(genre);
        }
      }
    }
    
    // Get seed tracks from user's playlist
    final userTracks = _playlistManager.playlist;
    final seedTracks = userTracks.isNotEmpty
        ? userTracks.take(2).map((t) => t.id).toList()
        : <String>[];
    
    return {
      'genres': topGenres,
      'tracks': seedTracks,
      'artists': <String>[], // Could extract from user tracks
    };
  }
  
  List<String> _getDefaultGenres() {
    return ['pop', 'rock'];
  }

  List<Track> _selectBestTracks(
    List<Track> candidates,
    int targetSize,
    Map<String, dynamic> moodParams,
    bool includeNewDiscoveries,
  ) {
    // Remove duplicates
    final uniqueTracks = <String, Track>{};
    for (var track in candidates) {
      uniqueTracks[track.id] = track;
    }
    
    // Remove tracks already in user's playlist
    final userTrackIds = _playlistManager.playlist.map((t) => t.id).toSet();
    final filteredTracks = uniqueTracks.values
        .where((track) => !userTrackIds.contains(track.id))
        .toList();
    
    // Score tracks based on preferences and mood
    final scoredTracks = filteredTracks.map((track) {
      double score = Random().nextDouble(); // Simplified scoring
      
      // Prefer tracks with previews
      if (track.previewUrl != null) {
        score += 0.3;
      }
      
      // Prefer popular tracks (but not too popular for discovery)
      final popularity = track.popularity;
      if (includeNewDiscoveries) {
        score += (50 - (popularity - 50).abs()) / 100;
      } else {
        score += popularity / 100;
      }
      
      return {'track': track, 'score': score};
    }).toList();
    
    // Sort by score and take top tracks
    scoredTracks.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));
    
    return scoredTracks
        .take(targetSize)
        .map((item) => item['track'] as Track)
        .toList();
  }

  List<Track> _optimizeTrackOrder(List<Track> tracks) {
    // Simple optimization: alternate between high and medium energy
    // In production, use audio features for better flow
    final optimized = <Track>[];
    final remaining = List<Track>.from(tracks);
    
    while (remaining.isNotEmpty) {
      // Pick a track (in real app, consider tempo, key, energy transitions)
      final index = Random().nextInt(remaining.length);
      optimized.add(remaining.removeAt(index));
    }
    
    return optimized;
  }

  // Save generated playlist to user's library
  Future<void> saveGeneratedPlaylist() async {
    for (var track in _generatedTracks) {
      await _playlistManager.addTrack(track);
    }
  }

  // Quick actions
  Future<List<Track>> generateWorkoutPlaylist() async {
    return generateSmartPlaylist(
      targetSize: 25,
      mood: 'energetic',
      includeNewDiscoveries: false,
    );
  }

  // Map artist genres to valid Spotify recommendation genres
  List<String> _mapToValidSpotifyGenres(List<String> artistGenres) {
    // Valid Spotify genre seeds (verified from API)
    // NOTE: 'hard-rock' and 'hardcore' are NOT valid - use 'metal', 'rock', 'punk' instead
    const validGenres = {
      'pop', 'rock', 'hip-hop', 'edm', 'electronic', 'dance', 'house',
      'techno', 'trance', 'dubstep', 'drum-and-bass', 'indie', 'alternative',
      'metal', 'punk', 'jazz', 'classical', 'r-n-b', 'soul', 'funk',
      'blues', 'country', 'folk', 'reggae', 'latin', 'world-music',
      'ambient', 'chill', 'acoustic', 'piano', 'guitar', 'vocal',
      'party', 'happy', 'sad', 'energetic', 'relaxed', 'sleep',
      'hardstyle', 'industrial', 'grunge', 'disco'
    };
    
    // Genre mapping for common mismatches
    // Map hardcore genres to valid alternatives
    const genreMapping = {
      'frenchcore': 'hardstyle',
      'hardcore': 'hardstyle',
      'speedcore': 'hardstyle',
      'uk hardcore': 'hardstyle',
      'gabber': 'hardstyle',
      'uptempo': 'hardstyle',
      'rawstyle': 'hardstyle',
      'industrial hardcore': 'industrial',
      'terror': 'metal',
      'mainstream hardcore': 'hardstyle',
      'terrorcore': 'metal',
      'breakcore': 'drum-and-bass',
      'hard dance': 'dance',
      'happy hardcore': 'dance',
    };
    
    final mapped = <String>[];
    
    for (final genre in artistGenres) {
      final lowerGenre = genre.toLowerCase();
      
      // Check if it's already a valid genre
      if (validGenres.contains(lowerGenre)) {
        mapped.add(lowerGenre);
        continue;
      }
      
      // Check if we have a mapping
      if (genreMapping.containsKey(lowerGenre)) {
        final mappedGenre = genreMapping[lowerGenre]!;
        if (!mapped.contains(mappedGenre)) {
          mapped.add(mappedGenre);
        }
        continue;
      }
      
      // Try to find partial matches
      for (final validGenre in validGenres) {
        if (lowerGenre.contains(validGenre) || validGenre.contains(lowerGenre)) {
          if (!mapped.contains(validGenre)) {
            mapped.add(validGenre);
            break;
          }
        }
      }
    }
    
    // If no matches found, return some safe defaults based on energy
    if (mapped.isEmpty) {
      if (artistGenres.any((g) => 
          g.toLowerCase().contains('hard') || 
          g.toLowerCase().contains('core') ||
          g.toLowerCase().contains('metal'))) {
        mapped.addAll(['hardstyle', 'metal']);
      } else if (artistGenres.any((g) => 
          g.toLowerCase().contains('electronic') || 
          g.toLowerCase().contains('edm'))) {
        mapped.addAll(['edm', 'electronic']);
      } else {
        mapped.addAll(['pop', 'rock']);
      }
    }
    
    return mapped;
  }

  Future<List<Track>> generateChillPlaylist() async {
    return generateSmartPlaylist(
      targetSize: 30,
      mood: 'chill',
      includeNewDiscoveries: true,
    );
  }

  Future<List<Track>> generatePartyPlaylist() async {
    return generateSmartPlaylist(
      targetSize: 40,
      mood: 'party',
      includeNewDiscoveries: false,
    );
  }

  Future<List<Track>> generateFocusPlaylist() async {
    return generateSmartPlaylist(
      targetSize: 35,
      mood: 'focus',
      includeNewDiscoveries: true,
    );
  }

  void reset() {
    _generatedTracks = [];
    _progress = 0.0;
    _currentStep = '';
    _isGenerating = false;
    notifyListeners();
  }
}
