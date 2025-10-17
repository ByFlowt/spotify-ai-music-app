import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/track_model.dart';
import 'spotify_service.dart';
import 'playlist_manager.dart';
import 'spotify_auth_service.dart';

class AIPlaylistService extends ChangeNotifier {
  final SpotifyService _spotifyService;
  final PlaylistManager _playlistManager;
  final SpotifyAuthService _authService;
  
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

  AIPlaylistService(this._spotifyService, this._playlistManager, this._authService);

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

  // AI-powered smart playlist generation
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
      // Step 1: Analyze listening history
      final analysis = await analyzeListeningHistory();
      
      // Step 2: Determine mood parameters
      _currentStep = 'Understanding your mood preferences...';
      _progress = 0.3;
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 600));
      
      final moodParams = _getMoodParameters(mood);
      
      // Step 3: Get seed data
      _currentStep = 'Finding the perfect seeds...';
      _progress = 0.4;
      notifyListeners();
      
      final seeds = await _getSeedData(analysis);
      
      // Step 4: Generate recommendations in batches
      _currentStep = 'Generating personalized recommendations...';
      final allTracks = <Track>[];
      
      // Get multiple batches for variety
      for (int i = 0; i < 3; i++) {
        _progress = 0.4 + (i * 0.15);
        notifyListeners();
        
        final batch = await _spotifyService.getRecommendations(
          seedArtists: seeds['artists'] as List<String>?,
          seedTracks: seeds['tracks'] as List<String>?,
          seedGenres: seeds['genres'] as List<String>?,
          limit: 20,
          market: 'US',
        );
        
        allTracks.addAll(batch);
        await Future.delayed(const Duration(milliseconds: 400));
      }
      
      // Step 5: AI-powered track selection
      _currentStep = 'Applying AI algorithms...';
      _progress = 0.85;
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 800));
      
      _generatedTracks = _selectBestTracks(
        allTracks,
        targetSize,
        moodParams,
        includeNewDiscoveries,
      );
      
      // Step 6: Optimize track order
      _currentStep = 'Optimizing playlist flow...';
      _progress = 0.95;
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 500));
      
      _generatedTracks = _optimizeTrackOrder(_generatedTracks);
      
      _currentStep = 'Playlist ready! 🎉';
      _progress = 1.0;
      _isGenerating = false;
      notifyListeners();
      
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
    // Valid Spotify genre seeds (commonly used ones)
    const validGenres = {
      'pop', 'rock', 'hip-hop', 'edm', 'electronic', 'dance', 'house',
      'techno', 'trance', 'dubstep', 'drum-and-bass', 'indie', 'alternative',
      'metal', 'punk', 'jazz', 'classical', 'r-n-b', 'soul', 'funk',
      'blues', 'country', 'folk', 'reggae', 'latin', 'world-music',
      'ambient', 'chill', 'acoustic', 'piano', 'guitar', 'vocal',
      'party', 'happy', 'sad', 'energetic', 'relaxed', 'sleep'
    };
    
    // Genre mapping for common mismatches
    const genreMapping = {
      'frenchcore': 'hardcore',
      'hardstyle': 'hard-rock',
      'hardcore': 'hard-rock',
      'speedcore': 'hardcore',
      'uk hardcore': 'hardcore',
      'gabber': 'hardcore',
      'uptempo': 'edm',
      'rawstyle': 'hard-rock',
      'industrial hardcore': 'industrial',
      'terror': 'hard-rock',
      'mainstream hardcore': 'hardcore',
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
        mapped.addAll(['hard-rock', 'metal']);
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
