import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../models/track_model.dart';
import '../services/spotify_service.dart';
import '../services/playlist_manager.dart';
import '../services/web_audio_recorder.dart';
import '../services/api_proxy_service.dart';
import 'track_detail_page.dart';

class SongSearchPage extends StatefulWidget {
  const SongSearchPage({super.key});

  @override
  State<SongSearchPage> createState() => _SongSearchPageState();
}

class _SongSearchPageState extends State<SongSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<Track> _searchResults = [];
  List<Track> _trendingTracks = [];
  bool _hasSearched = false;
  bool _loadingTrending = false;
  String _sortBy = 'relevance';
  String _filterGenre = 'all';

  @override
  void initState() {
    super.initState();
    _loadTrendingAndTopTracks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadTrendingAndTopTracks() async {
    setState(() => _loadingTrending = true);
    try {
      final spotifyService = context.read<SpotifyService>();
      // Load trending tracks (high popularity)
      final trendingResults = await spotifyService.searchTracks('trending');
      trendingResults.sort((a, b) => (b.popularity).compareTo(a.popularity));

      if (mounted) {
        setState(() {
          _trendingTracks = trendingResults.take(5).toList();
          _loadingTrending = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingTrending = false);
      }
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
      });
      return;
    }

    final spotifyService = context.read<SpotifyService>();
    final results = await spotifyService.searchTracks(query);
    _applySorting(results);

    setState(() {
      _searchResults = results;
      _hasSearched = true;
    });
  }

  void _applySorting(List<Track> results) {
    switch (_sortBy) {
      case 'popularity':
        results.sort((a, b) => (b.popularity).compareTo(a.popularity));
        break;
      case 'newest':
        break;
      case 'relevance':
      default:
        break;
    }
  }

  void _runExampleSearch(String query) {
    _searchController.text = query;
    FocusScope.of(context).unfocus();
    _performSearch(query);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final playlistManager = context.watch<PlaylistManager>();
    context.watch<SpotifyService>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, colorScheme, textTheme),
            Expanded(
              child: Consumer<SpotifyService>(
                builder: (context, service, child) {
                  return _buildResultsView(context, service, playlistManager,
                      colorScheme, textTheme);
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildMicrophoneFAB(context, colorScheme),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildHeader(
      BuildContext context, ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary.withOpacity(0.08),
            colorScheme.secondary.withOpacity(0.04),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withOpacity(0.5),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.music_note_rounded,
                  size: 24,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Song Search',
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.outline.withOpacity(0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onChanged: (value) => setState(() {}),
                    onSubmitted: _performSearch,
                    decoration: InputDecoration(
                      hintText: 'Search songs, artists...',
                      hintStyle: TextStyle(
                        color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchResults = [];
                                  _hasSearched = false;
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 0),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  selected: true,
                  onSelected: (value) => _showSortDialog(context),
                  avatar: Icon(
                    Icons.tune_rounded,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                  label: Text(
                    'Sort: $_sortBy',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  backgroundColor:
                      colorScheme.primaryContainer.withOpacity(0.3),
                  side: BorderSide(
                    color: colorScheme.primary.withOpacity(0.5),
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  selected: true,
                  onSelected: (value) => _showGenreDialog(context),
                  avatar: Icon(
                    Icons.category_rounded,
                    size: 18,
                    color: colorScheme.secondary,
                  ),
                  label: Text(
                    'Genre: $_filterGenre',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  backgroundColor:
                      colorScheme.secondaryContainer.withOpacity(0.3),
                  side: BorderSide(
                    color: colorScheme.secondary.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsView(
    BuildContext context,
    SpotifyService service,
    PlaylistManager playlistManager,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    if (service.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'Searching songs...',
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    if (service.error != null && _hasSearched) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 64, color: colorScheme.error),
              const SizedBox(height: 16),
              Text(
                'Oops! Something went wrong',
                style: textTheme.titleLarge?.copyWith(color: colorScheme.error),
              ),
              const SizedBox(height: 8),
              Text(
                service.error!,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_hasSearched) {
      return _buildEmptyState(context, colorScheme, textTheme);
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded,
                size: 64, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text('No songs found', style: textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Try searching for a different song',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final track = _searchResults[index];
        final isAdded = playlistManager.isInPlaylist(track.id);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: colorScheme.outlineVariant.withOpacity(0.5),
            ),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TrackDetailPage(track: track),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      track.imageUrl ??
                          'https://via.placeholder.com/60?text=No+Image',
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.music_note,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          track.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        Text(
                          track.artistName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () async {
                      if (isAdded) {
                        await playlistManager.removeTrack(track.id);
                      } else {
                        await playlistManager.addTrack(track);
                      }
                      setState(() {});
                    },
                    icon: Icon(
                      isAdded
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color:
                          isAdded ? Colors.red : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(
      BuildContext context, ColorScheme colorScheme, TextTheme textTheme) {
    final playlistManager = context.watch<PlaylistManager>();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Icon(
              Icons.music_note_rounded,
              size: 80,
              color: colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Discover Songs',
              style: textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Search for songs and build your perfect playlist',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 40),

            // Feature Cards
            _buildFeatureCard(
              context,
              Icons.search_rounded,
              'Search Songs',
              'Find any song and add to your collection',
              colorScheme.primary,
              onTap: () => _runExampleSearch('Top hits'),
            ),
            const SizedBox(height: 12),
            _buildFeatureCard(
              context,
              Icons.mic_rounded,
              'Audio Search',
              'Use your microphone to identify songs',
              colorScheme.secondary,
              onTap: () => _showShazamDialog(context),
            ),
            const SizedBox(height: 12),
            _buildFeatureCard(
              context,
              Icons.favorite_rounded,
              'Save Favorites',
              'Add songs to your playlist for later',
              colorScheme.tertiary,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Use the heart icon on any result to save it to My Playlist.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            const SizedBox(height: 40),

            // Trending Section
            if (_loadingTrending)
              Center(
                child: CircularProgressIndicator(color: colorScheme.primary),
              )
            else ...[
              if (_trendingTracks.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🔥 Trending Now',
                      style: textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ..._trendingTracks.map((track) {
                      final isAdded = playlistManager.isInPlaylist(track.id);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.outlineVariant.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.network(
                                track.imageUrl ??
                                    'https://via.placeholder.com/40?text=No+Image',
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 40,
                                    height: 40,
                                    color: colorScheme.surfaceContainer,
                                    child: Icon(Icons.music_note, size: 20),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    track.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: textTheme.labelMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    track.artistName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () async {
                                if (isAdded) {
                                  await playlistManager.removeTrack(track.id);
                                } else {
                                  await playlistManager.addTrack(track);
                                }
                                setState(() {});
                              },
                              icon: Icon(
                                isAdded
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                color: isAdded
                                    ? Colors.red
                                    : colorScheme.onSurfaceVariant,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 24),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    IconData icon,
    String title,
    String description,
    Color accentColor, {
    VoidCallback? onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final borderRadius = BorderRadius.circular(16);

    final content = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor.withOpacity(0.1),
            accentColor.withOpacity(0.05),
          ],
        ),
        borderRadius: borderRadius,
        border: Border.all(
          color: accentColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 28, color: accentColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return content;
    }

    return Material(
      color: Colors.transparent,
      borderRadius: borderRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: content,
      ),
    );
  }

  void _showSortDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sort By'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Relevance'),
              value: 'relevance',
              groupValue: _sortBy,
              onChanged: (value) {
                setState(() => _sortBy = value ?? 'relevance');
                _applySorting(_searchResults);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Most Popular'),
              value: 'popularity',
              groupValue: _sortBy,
              onChanged: (value) {
                setState(() => _sortBy = value ?? 'popularity');
                _applySorting(_searchResults);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Newest'),
              value: 'newest',
              groupValue: _sortBy,
              onChanged: (value) {
                setState(() => _sortBy = value ?? 'newest');
                _applySorting(_searchResults);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showGenreDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter by Genre'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              'All',
              'Pop',
              'Hip-Hop',
              'Rock',
              'Electronic',
              'Jazz',
              'Classical',
            ]
                .map((genre) => RadioListTile<String>(
                      title: Text(genre),
                      value: genre.toLowerCase(),
                      groupValue: _filterGenre,
                      onChanged: (value) {
                        setState(() => _filterGenre = value ?? 'all');
                        Navigator.pop(context);
                      },
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildMicrophoneFAB(BuildContext context, ColorScheme colorScheme) {
    return FloatingActionButton.extended(
      onPressed: () => _showShazamDialog(context),
      icon: const Icon(Icons.mic_rounded, size: 24),
      label: const Text(
        'Identify Song',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      elevation: 8,
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
    );
  }

  void _showShazamDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const ShazamRecordingDialog(),
    );
  }
}

// Shazam Recording Dialog
class ShazamRecordingDialog extends StatefulWidget {
  const ShazamRecordingDialog({super.key});

  @override
  State<ShazamRecordingDialog> createState() => _ShazamRecordingDialogState();
}

class _ShazamRecordingDialogState extends State<ShazamRecordingDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  WebAudioRecorder? _audioRecorder;
  bool _isRecording = false;
  // ignore: unused_field
  bool _isProcessing = false;
  String _statusText = 'Tap to start listening...';
  // ignore: unused_field
  String? _error;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    // Initialize audio recorder for web
    if (kIsWeb) {
      _audioRecorder = WebAudioRecorder();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _audioRecorder?.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      // Stop recording and identify
      setState(() {
        _statusText = 'Identifying song...';
        _isRecording = false;
        _isProcessing = true;
      });

      try {
        // Stop recording and get audio data
        final audioBase64 = await _audioRecorder?.stopRecording();

        if (audioBase64 == null || audioBase64.isEmpty) {
          throw Exception('No audio data recorded');
        }

        // Call the backend API to identify the song
        final result = await ApiProxyService.recognizeAudio(
          audioBase64: audioBase64,
        );

        if (mounted) {
          Navigator.pop(context);

          if (result['status'] == 'success' && result['result'] != null) {
            final songData = result['result'];
            final title = songData['title'] ?? 'Unknown';
            final artist = songData['artist'] ?? 'Unknown';
            final album = songData['album'];

            // Create a Track object and add to identified songs
            final identifiedTrack = Track(
              id: songData['spotify_id'] ??
                  '${title}_${artist}'.replaceAll(' ', '_'),
              name: title,
              artistName: artist,
              albumName: album,
              imageUrl: songData['spotify']?['image'],
              spotifyUrl: songData['spotify_id'] != null
                  ? 'https://open.spotify.com/track/${songData['spotify_id']}'
                  : null,
              previewUrl: songData['preview_url'],
              popularity: 75,
              durationMs: (songData['duration'] ?? 0) * 1000,
            );

            // Add to identified songs playlist
            final playlistManager = context.read<PlaylistManager>();
            await playlistManager.addIdentifiedSong(identifiedTrack);

            _showSongIdentified(title, artist);
          } else {
            _showError(
                'Could not identify the song. Please try again or search manually.');
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _error = e.toString();
            _statusText = 'Error: ${e.toString()}';
            _isProcessing = false;
          });
        }
      }
    } else {
      // Request permission and start recording
      if (_audioRecorder == null) {
        _showError('Audio recording is only available in web browsers');
        return;
      }

      setState(() {
        _statusText = 'Requesting microphone access...';
      });

      final initialized = await _audioRecorder!.initialize();

      if (!initialized) {
        setState(() {
          _error = _audioRecorder!.error;
          _statusText = 'Microphone access denied';
        });
        return;
      }

      final started = await _audioRecorder!.startRecording();

      if (started) {
        setState(() {
          _isRecording = true;
          _statusText = 'Listening... (tap to stop)';
          _error = null;
        });

        // Auto-stop after 10 seconds
        Future.delayed(const Duration(seconds: 10), () {
          if (_isRecording && mounted) {
            _toggleRecording();
          }
        });
      } else {
        setState(() {
          _error = _audioRecorder!.error;
          _statusText = 'Failed to start recording';
        });
      }
    }
  }

  void _showSongIdentified(String title, String artist) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 12),
            Text('Song Identified!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              artist,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            const Text('Search for this song to add it to your playlist!'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.orange),
            SizedBox(width: 12),
            Text('Recognition Failed'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(32),
      ),
      backgroundColor: colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Text(
              'Song Recognition',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _statusText,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 40),

            // Animated microphone button
            GestureDetector(
              onTap: _toggleRecording,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: _isRecording
                            ? [
                                colorScheme.primary.withOpacity(0.3),
                                colorScheme.primary.withOpacity(0.1),
                                Colors.transparent,
                              ]
                            : [
                                colorScheme.primary.withOpacity(0.2),
                                Colors.transparent,
                              ],
                      ),
                      boxShadow: [
                        if (_isRecording)
                          BoxShadow(
                            color: colorScheme.primary.withOpacity(
                              0.3 * _pulseController.value,
                            ),
                            blurRadius: 40,
                            spreadRadius: 20,
                          ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isRecording
                              ? colorScheme.error
                              : colorScheme.primary,
                          boxShadow: [
                            BoxShadow(
                              color: _isRecording
                                  ? colorScheme.error.withOpacity(0.5)
                                  : colorScheme.primary.withOpacity(0.5),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Icon(
                          _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                          size: 40,
                          color: _isRecording
                              ? colorScheme.onError
                              : colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 40),

            // Cancel button
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
