import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import '../models/track_model.dart';
import '../services/spotify_service.dart';
import '../services/playlist_manager.dart';
import 'track_detail_page.dart';

class SongSearchPage extends StatefulWidget {
  const SongSearchPage({super.key});

  @override
  State<SongSearchPage> createState() => _SongSearchPageState();
}

class _SongSearchPageState extends State<SongSearchPage> {
  final TextEditingController _searchController = TextEditingController();
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
                  return _buildResultsView(context, service, playlistManager, colorScheme, textTheme);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme colorScheme, TextTheme textTheme) {
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
                  backgroundColor: colorScheme.primaryContainer.withOpacity(0.3),
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
                  backgroundColor: colorScheme.secondaryContainer.withOpacity(0.3),
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
              Icon(Icons.error_outline_rounded, size: 64, color: colorScheme.error),
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
            Icon(Icons.search_off_rounded, size: 64, color: colorScheme.onSurfaceVariant),
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
                      track.imageUrl ?? 'https://via.placeholder.com/60?text=No+Image',
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
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          track.artistName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                      isAdded ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: isAdded ? Colors.red : colorScheme.onSurfaceVariant,
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

  Widget _buildEmptyState(BuildContext context, ColorScheme colorScheme, TextTheme textTheme) {
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
              style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
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
            ),
            const SizedBox(height: 12),
            _buildFeatureCard(
              context,
              Icons.mic_rounded,
              'Audio Search',
              'Use your microphone to identify songs',
              colorScheme.secondary,
            ),
            const SizedBox(height: 12),
            _buildFeatureCard(
              context,
              Icons.favorite_rounded,
              'Save Favorites',
              'Add songs to your playlist for later',
              colorScheme.tertiary,
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
                      style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
                                track.imageUrl ?? 'https://via.placeholder.com/40?text=No+Image',
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
                                    style: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
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
                                isAdded ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                color: isAdded ? Colors.red : colorScheme.onSurfaceVariant,
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
    Color accentColor,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
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
        borderRadius: BorderRadius.circular(16),
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
                  style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
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
}
