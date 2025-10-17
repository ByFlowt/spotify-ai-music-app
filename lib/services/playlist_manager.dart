import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/track_model.dart';

class PlaylistManager extends ChangeNotifier {
  List<Track> _myPlaylist = [];
  
  List<Track> get playlist => _myPlaylist;
  
  PlaylistManager() {
    _loadPlaylist();
  }

  // Load playlist from local storage
  Future<void> _loadPlaylist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final playlistJson = prefs.getString('my_playlist');
      
      if (playlistJson != null) {
        final List<dynamic> decoded = jsonDecode(playlistJson);
        _myPlaylist = decoded.map((item) => Track.fromJson(item)).toList();
        notifyListeners();
      }
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
      final playlistJson = jsonEncode(
        _myPlaylist.map((track) => track.toJson()).toList(),
      );
      await prefs.setString('my_playlist', playlistJson);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving playlist: $e');
      }
    }
  }

  // Add track to playlist
  Future<void> addTrack(Track track) async {
    if (!_myPlaylist.any((t) => t.id == track.id)) {
      _myPlaylist.add(track);
      await _savePlaylist();
      notifyListeners();
    }
  }

  // Remove track from playlist
  Future<void> removeTrack(String trackId) async {
    _myPlaylist.removeWhere((track) => track.id == trackId);
    await _savePlaylist();
    notifyListeners();
  }

  // Check if track is in playlist
  bool isInPlaylist(String trackId) {
    return _myPlaylist.any((track) => track.id == trackId);
  }

  // Clear entire playlist
  Future<void> clearPlaylist() async {
    _myPlaylist.clear();
    await _savePlaylist();
    notifyListeners();
  }

  // Get playlist count
  int get count => _myPlaylist.length;
}
