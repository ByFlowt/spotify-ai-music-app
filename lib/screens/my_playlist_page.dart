import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../models/track_model.dart';
import '../services/playlist_manager.dart';
import '../services/spotify_service.dart';
import '../services/spotify_auth_service.dart';
import 'track_detail_page.dart';

class MyPlaylistPage extends StatefulWidget {
  const MyPlaylistPage({super.key});

  @override
  State<MyPlaylistPage> createState() => _MyPlaylistPageState();
}

class _MyPlaylistPageState extends State<MyPlaylistPage>
    with WidgetsBindingObserver {
  bool _showMainPlaylist = true;
  bool _showAIPlaylist = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Refresh playlist data when page is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshPlaylists();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh when app comes to foreground
    if (state == AppLifecycleState.resumed) {
      _refreshPlaylists();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _refreshPlaylists() async {
    final playlistManager = context.read<PlaylistManager>();
    // Force reload from storage
    await playlistManager.loadPlaylistsFromStorage();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final playlistManager = context.watch<PlaylistManager>();
    
    final totalTracks = playlistManager.count + playlistManager.aiCount;
    
    // Debug logging
    if (kDebugMode) {
      print('🎵 [MY PLAYLIST] Building page - Main: ${playlistManager.count}, AI: ${playlistManager.aiCount}, Total: $totalTracks');
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Playlists'),
        elevation: 0,
        actions: [
          if (totalTracks > 0)
            IconButton(
              onPressed: () {
                _showClearAllDialog(context, playlistManager);
              },
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Clear All Playlists',
            ),
        ],
      ),
      body: totalTracks == 0
          ? _buildEmptyState(context)
          : RefreshIndicator(
              onRefresh: _refreshPlaylists,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Overall Header
                    Container(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  colorScheme.primaryContainer,
                                  colorScheme.secondaryContainer,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.playlist_play_rounded,
                              size: 32,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Your Collection',
                                  style: textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '$totalTracks ${totalTracks == 1 ? 'song' : 'songs'}',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Main Playlist Section
                    if (playlistManager.count > 0)
                      _buildPlaylistSection(
                        context,
                        'My Playlist',
                        playlistManager.playlist,
                        Icons.playlist_play_rounded,
                        _showMainPlaylist,
                        (value) => setState(() => _showMainPlaylist = value),
                        playlistManager,
                        onClear: () => _showClearDialog(context, playlistManager, 'main'),
                      ),

                    // AI Playlist Section (Folder)
                    if (playlistManager.aiCount > 0)
                      _buildPlaylistSection(
                        context,
                        'AI Playlist',
                        playlistManager.aiPlaylist,
                        Icons.auto_awesome_rounded,
                        _showAIPlaylist,
                        (value) => setState(() => _showAIPlaylist = value),
                        playlistManager,
                        isAIPlaylist: true,
                        onClear: () => _showClearDialog(context, playlistManager, 'ai'),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPlaylistSection(
    BuildContext context,
    String title,
    List<dynamic> tracks,
    IconData icon,
    bool isExpanded,
    Function(bool) onExpandChanged,
    PlaylistManager playlistManager, {
    bool isAIPlaylist = false,
    VoidCallback? onClear,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: colorScheme.outlineVariant,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Folder Header with Export Button
          InkWell(
            onTap: () => onExpandChanged(!isExpanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isAIPlaylist
                          ? colorScheme.secondary.withOpacity(0.2)
                          : colorScheme.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      size: 24,
                      color: isAIPlaylist ? colorScheme.secondary : colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${tracks.length} ${tracks.length == 1 ? 'song' : 'songs'}',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (tracks.isNotEmpty)
                    IconButton(
                      onPressed: () => _exportToSpotify(context, title, tracks),
                      icon: const Icon(Icons.upload_rounded),
                      tooltip: 'Export to Spotify',
                    ),
                  if (onClear != null)
                    IconButton(
                      onPressed: onClear,
                      icon: Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: colorScheme.error,
                      ),
                    ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          
          // Tracks List (Expandable)
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: List.generate(
                  tracks.length,
                  (index) => _buildTrackCard(
                    context,
                    tracks[index],
                    index + 1,
                    playlistManager,
                    isAIPlaylist: isAIPlaylist,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.playlist_add_rounded,
                size: 80,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Your Playlists are Empty',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Search for songs, explore artists, or generate AI playlists to build your collection',
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackCard(
    BuildContext context,
    track,
    int position,
    PlaylistManager playlistManager, {
    bool isAIPlaylist = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TrackDetailPage(track: track),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Position Number
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary,
                      colorScheme.secondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '$position',
                    style: textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Album Cover
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: colorScheme.surfaceContainerHighest,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: track.imageUrl != null
                      ? Image.network(
                          track.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.music_note_rounded,
                            size: 24,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        )
                      : Icon(
                          Icons.music_note_rounded,
                          size: 24,
                          color: colorScheme.onSurfaceVariant,
                        ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Track Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.name,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      track.artistName,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              // Duration and Remove Button
              Column(
                children: [
                  Text(
                    track.durationFormatted,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      if (isAIPlaylist) {
                        playlistManager.removeTrackFromAI(track.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Removed from AI Playlist'),
                            backgroundColor: Colors.orange,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      } else {
                        playlistManager.removeTrack(track.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Removed from playlist'),
                            backgroundColor: Colors.orange,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    icon: Icon(
                      Icons.remove_circle_outline,
                      color: colorScheme.error,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showClearDialog(
    BuildContext context,
    PlaylistManager playlistManager,
    String playlistType,
  ) {
    final isAI = playlistType == 'ai';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear ${isAI ? 'AI ' : ''}Playlist?'),
        content: Text(
          'Are you sure you want to remove all songs from your ${isAI ? 'AI ' : ''}playlist? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (isAI) {
                playlistManager.clearAIPlaylist();
              } else {
                playlistManager.clearPlaylist();
              }
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${isAI ? 'AI ' : ''}Playlist cleared'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showClearAllDialog(BuildContext context, PlaylistManager playlistManager) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Playlists?'),
        content: const Text(
          'Are you sure you want to remove all songs from all playlists? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              playlistManager.clearPlaylist();
              playlistManager.clearAIPlaylist();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All playlists cleared'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportToSpotify(BuildContext context, String playlistName, List<dynamic> tracks) async {
    final authService = context.read<SpotifyAuthService>();
    final spotifyService = context.read<SpotifyService>();
    
    if (!authService.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login with Spotify first to export playlists'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Creating Spotify playlist...'),
          ],
        ),
      ),
    );

    try {
      // Get user profile
      final userProfile = authService.userProfile;
      if (userProfile == null) {
        Navigator.pop(context);
        throw Exception('User profile not available');
      }

      final userId = userProfile['id'] as String;
      final accessToken = authService.accessToken!;

      // Convert Track objects to Spotify URIs
      final trackUris = tracks
          .map((track) {
            if (track is Track) {
              return 'spotify:track:${track.id}';
            }
            return null;
          })
          .whereType<String>()
          .toList();

      if (trackUris.isEmpty) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No valid tracks to export'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      // Create playlist
      final playlistId = await spotifyService.createPlaylist(
        userAccessToken: accessToken,
        userId: userId,
        playlistName: playlistName,
        description: 'Exported from Spotify AI Music App',
        isPublic: false,
      );

      if (playlistId == null) {
        Navigator.pop(context);
        throw Exception('Failed to create playlist');
      }

      // Add tracks to playlist
      final success = await spotifyService.addTracksToPlaylist(
        userAccessToken: accessToken,
        playlistId: playlistId,
        trackUris: trackUris,
      );

      Navigator.pop(context);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Playlist "$playlistName" exported to Spotify!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        throw Exception('Failed to add tracks to playlist');
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

