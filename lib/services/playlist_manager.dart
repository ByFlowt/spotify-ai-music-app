import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/track_model.dart';

class PlaylistManager extends ChangeNotifier {
  List<Track> _myPlaylist = [];
  List<Track> _aiGeneratedPlaylist = []; // Separate list for AI-generated tracks
  List<Track> _identifiedSongs = []; // List for Shazam-identified songs
  
  List<Track> get playlist => _myPlaylist;
  List<Track> get aiPlaylist => _aiGeneratedPlaylist;
  List<Track> get identifiedSongs => _identifiedSongs;
  
  PlaylistManager() {
    _loadPlaylist();
  }

  // Public method to reload playlists from storage
  Future<void> loadPlaylistsFromStorage() async {
    await _loadPlaylist();
  }

  // Load playlist from local storage
  Future<void> _loadPlaylist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load main playlist
      final playlistJson = prefs.getString('my_playlist');
      if (playlistJson != null) {
        final List<dynamic> decoded = jsonDecode(playlistJson);
        _myPlaylist = decoded.map((item) => Track.fromJson(item)).toList();
      }
      
      // Load AI playlist
      final aiPlaylistJson = prefs.getString('ai_playlist');
      if (aiPlaylistJson != null) {
        final List<dynamic> decoded = jsonDecode(aiPlaylistJson);
        _aiGeneratedPlaylist = decoded.map((item) => Track.fromJson(item)).toList();
      }
      
      // Load identified songs
      final identifiedJson = prefs.getString('identified_songs');
      if (identifiedJson != null) {
        final List<dynamic> decoded = jsonDecode(identifiedJson);
        _identifiedSongs = decoded.map((item) => Track.fromJson(item)).toList();
      }
      
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading playlist: $e');
      }
    }
  }

  // Save playlist to local storage
  Future<void> _savePlaylist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save main playlist
      final playlistJson = jsonEncode(
        _myPlaylist.map((track) => track.toJson()).toList(),
      );
      await prefs.setString('my_playlist', playlistJson);
      
      // Save AI playlist
      final aiPlaylistJson = jsonEncode(
        _aiGeneratedPlaylist.map((track) => track.toJson()).toList(),
      );
      await prefs.setString('ai_playlist', aiPlaylistJson);
      
      // Save identified songs
      final identifiedJson = jsonEncode(
        _identifiedSongs.map((track) => track.toJson()).toList(),
      );
      await prefs.setString('identified_songs', identifiedJson);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving playlist: $e');
      }
    }
  }

  // Add track to main playlist
  Future<void> addTrack(Track track) async {
    if (!_myPlaylist.any((t) => t.id == track.id)) {
      _myPlaylist.add(track);
      await _savePlaylist();
      notifyListeners();
    }
  }

  // Add track to AI playlist
  Future<void> addTrackToAI(Track track) async {
    if (!_aiGeneratedPlaylist.any((t) => t.id == track.id)) {
      _aiGeneratedPlaylist.add(track);
      await _savePlaylist();
      notifyListeners();
    }
  }

  // Add multiple tracks to AI playlist
  Future<void> addTracksToAI(List<Track> tracks) async {
    for (var track in tracks) {
      if (!_aiGeneratedPlaylist.any((t) => t.id == track.id)) {
        _aiGeneratedPlaylist.add(track);
      }
    }
    await _savePlaylist();
    notifyListeners();
  }

  // Add track to identified songs
  Future<void> addIdentifiedSong(Track track) async {
    // Add timestamp to track if not already present
    if (!_identifiedSongs.any((t) => t.id == track.id)) {
      _identifiedSongs.insert(0, track); // Add to beginning (most recent first)
      await _savePlaylist();
      notifyListeners();
    }
  }

  // Remove track from identified songs
  Future<void> removeIdentifiedSong(String trackId) async {
    _identifiedSongs.removeWhere((track) => track.id == trackId);
    await _savePlaylist();
    notifyListeners();
  }

  // Clear identified songs
  Future<void> clearIdentifiedSongs() async {
    _identifiedSongs.clear();
    await _savePlaylist();
    notifyListeners();
  }

  // Check if track is in identified songs
  bool isIdentifiedSong(String trackId) {
    return _identifiedSongs.any((track) => track.id == trackId);
  }

  // Remove track from main playlist
  Future<void> removeTrack(String trackId) async {
    _myPlaylist.removeWhere((track) => track.id == trackId);
    await _savePlaylist();
    notifyListeners();
  }

  // Remove track from AI playlist
  Future<void> removeTrackFromAI(String trackId) async {
    _aiGeneratedPlaylist.removeWhere((track) => track.id == trackId);
    await _savePlaylist();
    notifyListeners();
  }

  // Check if track is in main playlist
  bool isInPlaylist(String trackId) {
    return _myPlaylist.any((track) => track.id == trackId);
  }

  // Check if track is in AI playlist
  bool isInAIPlaylist(String trackId) {
    return _aiGeneratedPlaylist.any((track) => track.id == trackId);
  }

  // Clear main playlist
  Future<void> clearPlaylist() async {
    _myPlaylist.clear();
    await _savePlaylist();
    notifyListeners();
  }

  // Clear AI playlist
  Future<void> clearAIPlaylist() async {
    _aiGeneratedPlaylist.clear();
    await _savePlaylist();
    notifyListeners();
  }

  // Get main playlist count
  int get count => _myPlaylist.length;
  
  // Get AI playlist count
  int get aiCount => _aiGeneratedPlaylist.length;
  
  // Get identified songs count
  int get identifiedCount => _identifiedSongs.length;
}
