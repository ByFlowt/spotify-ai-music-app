import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../models/track_model.dart';
import '../services/playlist_manager.dart';

class TrackDetailPage extends StatefulWidget {
  final Track track;

  const TrackDetailPage({super.key, required this.track});

  @override
  State<TrackDetailPage> createState() => _TrackDetailPageState();
}

class _TrackDetailPageState extends State<TrackDetailPage> {
  bool _isAddedToPlaylist = false;

  @override
  void initState() {
    super.initState();
    _checkIfInPlaylist();
  }

  Future<void> _checkIfInPlaylist() async {
    final playlistManager = context.read<PlaylistManager>();
    setState(() {
      _isAddedToPlaylist = playlistManager.isInPlaylist(widget.track.id);
    });
  }

  Future<void> _addToPlaylist() async {
    final playlistManager = context.read<PlaylistManager>();
    
    try {
      await playlistManager.addTrack(widget.track);
      
      if (mounted) {
        setState(() {
          _isAddedToPlaylist = true;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('${widget.track.name} added to your playlist'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      _showErrorSnackbar('Failed to add track: ${e.toString()}');
    }
  }

  Future<void> _removeFromPlaylist() async {
    final playlistManager = context.read<PlaylistManager>();
    
    try {
      await playlistManager.removeTrack(widget.track.id);
      
      if (mounted) {
        setState(() {
          _isAddedToPlaylist = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('${widget.track.name} removed from playlist'),
                ),
              ],
            ),
            backgroundColor: Colors.blue,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      _showErrorSnackbar('Failed to remove track: ${e.toString()}');
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _openInSpotify() async {
    if (widget.track.spotifyUrl != null) {
      final uri = Uri.parse(widget.track.spotifyUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showErrorSnackbar('Could not open Spotify');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // App Bar with Album Art
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            stretch: true,
            stretchTriggerOffset: 100,
            onStretchTrigger: () async {
              Navigator.pop(context);
            },
            backgroundColor: colorScheme.surface,
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.blurBackground,
              ],
              background: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (widget.track.imageUrl != null)
                        Image.network(
                          widget.track.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: colorScheme.surfaceContainerHighest,
                            child: Icon(
                              Icons.music_note_rounded,
                              size: 80,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      else
                        Container(
                          color: colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.music_note_rounded,
                            size: 80,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.8),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Track Info
                  Text(
                    widget.track.name,
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.track.artistName,
                    style: textTheme.titleLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (widget.track.albumName != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.track.albumName!,
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Track Stats
                  Row(
                    children: [
                      _buildStatChip(
                        Icons.trending_up_rounded,
                        '${widget.track.popularity}% Popular',
                        colorScheme,
                      ),
                      const SizedBox(width: 12),
                      _buildStatChip(
                        Icons.timer_outlined,
                        widget.track.durationFormatted,
                        colorScheme,
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Action Buttons
                  Row(
                    children: [
                      // Add to Playlist Button
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: _isAddedToPlaylist ? _removeFromPlaylist : _addToPlaylist,
                          icon: Icon(
                            _isAddedToPlaylist ? Icons.check_rounded : Icons.add_rounded,
                          ),
                          label: Text(
                            _isAddedToPlaylist ? 'In Playlist' : 'Add to Playlist',
                          ),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: _isAddedToPlaylist
                                ? colorScheme.primaryContainer
                                : colorScheme.secondaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Open in Spotify Button
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: _openInSpotify,
                          icon: const Icon(Icons.open_in_new_rounded),
                          label: const Text('Spotify'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: const Color(0xFF1DB954).withOpacity(0.2),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // QR Code Section
                  if (widget.track.spotifyUrl != null) ...[
                    Center(
                      child: Column(
                        children: [
                          Text(
                            'Scan to Listen on Spotify',
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Open your camera app and scan this QR code',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),

                          // QR Code
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.shadow.withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: QrImageView(
                              data: widget.track.spotifyUrl!,
                              version: QrVersions.auto,
                              size: 240,
                              backgroundColor: Colors.white,
                              eyeStyle: const QrEyeStyle(
                                eyeShape: QrEyeShape.square,
                                color: Colors.black,
                              ),
                              dataModuleStyle: const QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.square,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSecondaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}
