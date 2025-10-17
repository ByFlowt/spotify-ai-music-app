import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';

class GeminiAIService {
  // Get your free Gemini API key from: https://makersuite.google.com/app/apikey
  // No cost - Gemini 2.0 Flash is free with generous limits!
  static const String apiKey = 'AIzaSyDaKqVBlnGR6UXq5XQjxo7mJDfgVZ9t0NU';

  late final GenerativeModel _model;
  DateTime? _lastRequestTime;
  static const _minRequestInterval = Duration(seconds: 2); // Rate limiting

  GeminiAIService() {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash', // Latest Gemini 2.5 Flash model
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.8, // Slightly less creative for more consistent results
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 2048,
      ),
    );
  }

  // Rate limiting helper
  Future<void> _waitForRateLimit() async {
    if (_lastRequestTime != null) {
      final elapsed = DateTime.now().difference(_lastRequestTime!);
      if (elapsed < _minRequestInterval) {
        final waitTime = _minRequestInterval - elapsed;
        if (kDebugMode) {
          print('⏳ Rate limiting: waiting ${waitTime.inMilliseconds}ms...');
        }
        await Future.delayed(waitTime);
      }
    }
    _lastRequestTime = DateTime.now();
  }

  // Analyze listening history and generate intelligent recommendations
  Future<Map<String, dynamic>> analyzeListeningHistory({
    required List<Map<String, dynamic>> topTracks,
    required List<Map<String, dynamic>> recentTracks,
    required List<String> topGenres,
    String mood = 'balanced',
  }) async {
    try {
      // Build comprehensive prompt for Gemini
      final prompt =
          _buildAnalysisPrompt(topTracks, recentTracks, topGenres, mood);

      if (kDebugMode) {
        print('Sending prompt to Gemini AI...');
      }

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      if (response.text == null) {
        throw Exception('No response from Gemini AI');
      }

      // Parse AI response
      final analysis = _parseAIResponse(response.text!);

      if (kDebugMode) {
        print('Gemini Analysis Complete: ${analysis.keys}');
      }

      return analysis;
    } catch (e) {
      if (kDebugMode) {
        print('Gemini AI Error: $e');
      }

      // Fallback to basic analysis
      return _fallbackAnalysis(topTracks, topGenres, mood);
    }
  }

  String _buildAnalysisPrompt(
    List<Map<String, dynamic>> topTracks,
    List<Map<String, dynamic>> recentTracks,
    List<String> topGenres,
    String mood,
  ) {
    final topTrackNames = topTracks
        .take(10)
        .map((t) => '${t['name']} by ${t['artist']}')
        .join(', ');
    final recentTrackNames = recentTracks
        .take(10)
        .map((t) => '${t['name']} by ${t['artist']}')
        .join(', ');

    return '''
You are an expert music analyst and DJ. Analyze this user's Spotify listening history and provide intelligent recommendations.

TOP TRACKS (all-time favorites):
$topTrackNames

RECENTLY PLAYED:
$recentTrackNames

GENRES: ${topGenres.join(', ')}

REQUESTED MOOD: $mood

Based on this data, provide a JSON response with:
1. "mood_profile": Describe their overall music taste in 1-2 sentences
2. "recommended_genres": Array of 3-5 genre strings to explore
3. "energy_level": Number 0-100 representing preferred energy
4. "diversity_score": Number 0-100 (how diverse their taste is)
5. "discovery_potential": Number 0-100 (how open they are to new music)
6. "search_queries": Array of 3-5 search terms for finding similar music
7. "mood_keywords": Array of 5-8 descriptive keywords for the $mood mood

Respond ONLY with valid JSON, no additional text.
''';
  }

  Map<String, dynamic> _parseAIResponse(String response) {
    try {
      final parsed = jsonDecode(_cleanJsonBlock(response));

      return {
        'mood_profile': parsed['mood_profile'] ?? 'Eclectic music lover',
        'recommended_genres': List<String>.from(
          parsed['recommended_genres'] ?? ['pop', 'rock'],
        ),
        'energy_level': (parsed['energy_level'] ?? 60).toInt(),
        'diversity_score': (parsed['diversity_score'] ?? 50).toInt(),
        'discovery_potential': (parsed['discovery_potential'] ?? 60).toInt(),
        'search_queries': List<String>.from(
          parsed['search_queries'] ?? ['popular hits'],
        ),
        'mood_keywords': List<String>.from(
          parsed['mood_keywords'] ?? ['upbeat', 'energetic'],
        ),
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing AI response: $e');
        print('Response was: $response');
      }
      return _getFallbackData();
    }
  }

  Map<String, dynamic> _fallbackAnalysis(
    List<Map<String, dynamic>> topTracks,
    List<String> topGenres,
    String mood,
  ) {
    return {
      'mood_profile': 'Diverse music lover with eclectic taste',
      'recommended_genres': topGenres.take(3).toList(),
      'energy_level': mood == 'energetic'
          ? 90
          : mood == 'chill'
              ? 30
              : 60,
      'diversity_score': 65,
      'discovery_potential': 70,
      'search_queries': topTracks.take(3).map((t) => t['artist']).toList(),
      'mood_keywords': _getMoodKeywords(mood),
    };
  }

  String _cleanJsonBlock(String response) {
    String cleaned = response.trim();
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    }
    if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    return cleaned.trim();
  }

  Map<String, dynamic> _getFallbackData() {
    return {
      'mood_profile': 'Music enthusiast',
      'recommended_genres': ['pop', 'rock', 'indie'],
      'energy_level': 60,
      'diversity_score': 50,
      'discovery_potential': 60,
      'search_queries': ['popular music', 'top hits'],
      'mood_keywords': ['upbeat', 'melodic', 'catchy'],
    };
  }

  List<String> _getMoodKeywords(String mood) {
    switch (mood) {
      case 'energetic':
        return [
          'high-energy',
          'upbeat',
          'intense',
          'powerful',
          'driving',
          'pumped'
        ];
      case 'chill':
        return [
          'relaxed',
          'mellow',
          'smooth',
          'laid-back',
          'calming',
          'peaceful'
        ];
      case 'party':
        return [
          'danceable',
          'fun',
          'celebratory',
          'vibrant',
          'groovy',
          'festive'
        ];
      case 'focus':
        return [
          'instrumental',
          'ambient',
          'minimal',
          'calm',
          'steady',
          'concentrated'
        ];
      default:
        return [
          'melodic',
          'balanced',
          'harmonious',
          'pleasant',
          'enjoyable',
          'versatile'
        ];
    }
  }

  // Generate playlist description using AI
  Future<String> generatePlaylistDescription({
    required String mood,
    required int trackCount,
    required List<String> topArtists,
  }) async {
    try {
      final prompt = '''
Create a catchy, engaging playlist description (max 100 words) for a $mood playlist with $trackCount songs.
Top artists include: ${topArtists.take(3).join(', ')}.
Make it personal and exciting. No quotes or titles, just the description text.
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      return response.text ??
          'Your personalized $mood playlist, curated just for you.';
    } catch (e) {
      return 'Your personalized $mood playlist with $trackCount carefully selected tracks.';
    }
  }

  // Generate specific song recommendations based on listening history
  Future<List<Map<String, String>>> generateSongRecommendations({
    required List<Map<String, dynamic>> topTracks,
    required List<Map<String, dynamic>> topArtists,
    required List<Map<String, dynamic>> recentTracks,
    required String mood,
    int targetCount = 30,
  }) async {
    try {
      // Rate limiting
      await _waitForRateLimit();

      // Build context for Gemini
      final topTracksList = topTracks
          .take(10)
          .map((t) => '${t['name']} by ${t['artist']}')
          .join('\n');
      final topArtistsList =
          topArtists.take(10).map((a) => a['name']).join(', ');
      final recentTracksList = recentTracks
          .take(5)
          .map((t) => '${t['name']} by ${t['artist']}')
          .join('\n');

      final prompt = '''
You are an expert music curator. Based on this user's Spotify listening history, recommend exactly $targetCount songs that match their taste and the "$mood" mood.

USER'S TOP TRACKS:
$topTracksList

TOP ARTISTS: $topArtistsList

RECENTLY PLAYED:
$recentTracksList

REQUESTED MOOD: $mood

Generate $targetCount song recommendations that:
1. Match their music taste and preferred genres
2. Fit the "$mood" mood perfectly
3. Include a mix of popular and lesser-known tracks
4. Are real, existing songs that can be found on Spotify

Respond with a JSON array of objects with "title" and "artist" fields. Format:
[
  {"title": "Song Name", "artist": "Artist Name"},
  {"title": "Song Name 2", "artist": "Artist Name 2"}
]

Respond ONLY with the JSON array, no additional text or markdown.
''';

      if (kDebugMode) {
        print('🎵 Asking Gemini for $targetCount song recommendations...');
      }

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      if (response.text == null) {
        throw Exception('No response from Gemini');
      }

      if (kDebugMode) {
        print('📝 Gemini response received, parsing...');
      }

      // Parse the recommendations
      final recommendations = _parseSongRecommendations(response.text!);

      if (kDebugMode) {
        print(
            '✅ Got ${recommendations.length} song recommendations from Gemini');
      }

      return recommendations;
    } on Exception catch (e) {
      final errorMsg = e.toString();

      if (kDebugMode) {
        print('❌ Gemini API Error: $errorMsg');
      }

      // Check if it's a rate limit error
      if (errorMsg.contains('429') ||
          errorMsg.contains('Too Many Requests') ||
          errorMsg.contains('quota')) {
        if (kDebugMode) {
          print(
              '⚠️  Rate limit reached. Using fallback recommendations based on your listening history.');
        }
      }

      // Fallback: use artists from their top tracks
      return _generateFallbackRecommendations(
          topTracks, topArtists, targetCount);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Unexpected error: $e');
      }

      // Fallback: use artists from their top tracks
      return _generateFallbackRecommendations(
          topTracks, topArtists, targetCount);
    }
  }

  Future<List<String>> suggestArtistsForGenre(String genre) async {
    final prompt = '''
You are an expert music curator. List exactly 5 internationally recognized artists known for the music genre "$genre".
Respond ONLY with valid JSON:
{
  "artists": ["Artist 1", "Artist 2", "Artist 3", "Artist 4", "Artist 5"]
}
''';

    try {
      await _waitForRateLimit();
      if (kDebugMode) {
        print('✨ [Gemini] Suggesting artists for genre: $genre');
      }

      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text;
      if (text == null) {
        throw Exception('Empty response from Gemini');
      }

      final parsed = jsonDecode(_cleanJsonBlock(text));
      final artists = (parsed['artists'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .where((name) => name.trim().isNotEmpty)
              .toList() ??
          [];

      if (artists.isNotEmpty) {
        return artists;
      }
      return _fallbackArtistsForGenre(genre);
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [Gemini] Genre suggestion error ($genre): $e');
      }
      return _fallbackArtistsForGenre(genre);
    }
  }

  List<String> _fallbackArtistsForGenre(String genre) {
    final lower = genre.toLowerCase();
    const fallback = {
      'hardstyle': [
        'Headhunterz',
        'Brennan Heart',
        'Sub Zero Project',
        'Noisecontrollers',
        'Sound Rush',
      ],
      'edm': [
        'Martin Garrix',
        'David Guetta',
        'Armin van Buuren',
        'Marshmello',
        'Tiesto',
      ],
      'techno': [
        'Charlotte de Witte',
        'Adam Beyer',
        'Amelie Lens',
        'Carl Cox',
        'Nina Kraviz',
      ],
      'pop': [
        'Taylor Swift',
        'Dua Lipa',
        'Billie Eilish',
        'Harry Styles',
        'Ariana Grande',
      ],
      'rock': [
        'Foo Fighters',
        'Imagine Dragons',
        'Red Hot Chili Peppers',
        'Muse',
        'Linkin Park',
      ],
      'hip-hop': [
        'Kendrick Lamar',
        'Drake',
        'J. Cole',
        'Nicki Minaj',
        'Travis Scott',
      ],
      'electronic': [
        'Deadmau5',
        'Skrillex',
        'Disclosure',
        'Flume',
        'Porter Robinson',
      ],
      'classical': [
        'Ludovico Einaudi',
        'Lang Lang',
        'Yo-Yo Ma',
        'Martha Argerich',
        'Itzhak Perlman',
      ],
      'jazz': [
        'Kamasi Washington',
        'Diana Krall',
        'Herbie Hancock',
        'Esperanza Spalding',
        'Snarky Puppy',
      ],
      'r&b': [
        'The Weeknd',
        'H.E.R.',
        'SZA',
        'Frank Ocean',
        'Jorja Smith',
      ],
      'country': [
        'Luke Combs',
        'Kacey Musgraves',
        'Chris Stapleton',
        'Carrie Underwood',
        'Morgan Wallen',
      ],
      'latin': [
        'Bad Bunny',
        'Karol G',
        'J Balvin',
        'Rosalía',
        'Maluma',
      ],
    };

    return fallback[lower] ??
        [
          'Trending $genre Artists',
          'Top $genre Acts',
          '$genre Rising Stars',
          'Best of $genre',
          'Essential $genre',
        ];
  }

  List<Map<String, String>> _parseSongRecommendations(String response) {
    try {
      // Clean up the response
      String cleaned = response.trim();

      // Remove markdown code blocks
      if (cleaned.startsWith('```json')) {
        cleaned = cleaned.substring(7);
      }
      if (cleaned.startsWith('```')) {
        cleaned = cleaned.substring(3);
      }
      if (cleaned.endsWith('```')) {
        cleaned = cleaned.substring(0, cleaned.length - 3);
      }

      cleaned = cleaned.trim();

      // Parse JSON
      final List<dynamic> parsed = jsonDecode(cleaned);

      return parsed
          .map((item) {
            return {
              'title': item['title']?.toString() ?? '',
              'artist': item['artist']?.toString() ?? '',
            };
          })
          .where(
              (item) => item['title']!.isNotEmpty && item['artist']!.isNotEmpty)
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing song recommendations: $e');
        print('Response was: $response');
      }
      return [];
    }
  }

  List<Map<String, String>> _generateFallbackRecommendations(
    List<Map<String, dynamic>> topTracks,
    List<Map<String, dynamic>> topArtists,
    int count,
  ) {
    if (kDebugMode) {
      print('⚠️  Using fallback: searching for songs by your favorite artists');
    }

    // Create smart recommendations based on their top artists
    final recommendations = <Map<String, String>>[];

    // Strategy 1: Top songs by their favorite artists (most likely to match taste)
    for (var artist in topArtists.take(count ~/ 2)) {
      recommendations.add({
        'title': 'popular', // Will search for popular songs by this artist
        'artist': artist['name'].toString(),
      });
    }

    // Strategy 2: Similar artists search terms
    for (var artist in topArtists.skip(count ~/ 2).take(count ~/ 4)) {
      recommendations.add({
        'title': 'best songs',
        'artist': artist['name'].toString(),
      });
    }

    // Strategy 3: Include some of their actual top tracks
    for (var track in topTracks.take(count ~/ 4)) {
      recommendations.add({
        'title': track['name'].toString(),
        'artist': track['artist'].toString(),
      });
    }

    if (kDebugMode) {
      print('📋 Generated ${recommendations.length} fallback recommendations');
    }

    return recommendations.take(count).toList();
  }
}
