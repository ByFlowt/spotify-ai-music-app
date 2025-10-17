import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/spotify_auth_service.dart';
import '../services/spotify_service.dart';
import '../models/track_model.dart';
import '../models/artist_model.dart';
import 'track_detail_page.dart';
import 'artist_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Track>? _topTracks;
  List<Artist>? _topArtists;
  List<Track>? _recentlyPlayed;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPersonalizedContent();
  }

  Future<void> _loadPersonalizedContent() async {
    final authService = context.read<SpotifyAuthService>();
    final spotifyService = context.read<SpotifyService>();
    
    if (authService.isAuthenticated && authService.accessToken != null) {
      try {
        // Load user's personalized data in parallel
        final results = await Future.wait([
          spotifyService.getUserTopTracks(
            userAccessToken: authService.accessToken!,
            timeRange: 'short_term',
            limit: 10,
          ),
          spotifyService.getUserTopArtists(
            userAccessToken: authService.accessToken!,
            timeRange: 'short_term',
            limit: 10,
          ),
          spotifyService.getUserRecentlyPlayed(
            userAccessToken: authService.accessToken!,
            limit: 10,
          ),
        ]);
        
        if (mounted) {
          setState(() {
            _topTracks = results[0] as List<Track>;
            _topArtists = results[1] as List<Artist>;
            _recentlyPlayed = results[2] as List<Track>;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      // Guest mode - don't load personalized content
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else if (hour < 22) {
      return 'Good evening';
    } else {
      return 'Good night';
    }
  }

  List<String> _getRandomGreetings() {
    return [
      'Welcome back',
      'Hello',
      'Hey there',
      'Great to see you',
      'Nice to see you',
    ];
  }

  String _getPersonalizedGreeting(String? userName) {
    final greetings = [_getGreeting(), ..._getRandomGreetings()];
    final greeting = (greetings..shuffle()).first;
    return userName != null ? '$greeting, $userName!' : '$greeting!';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final authService = context.watch<SpotifyAuthService>();
    final isAuthenticated = authService.isAuthenticated;

    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: colorScheme.primary),
                    const SizedBox(height: 16),
                    Text('Loading your music...', style: textTheme.titleMedium),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadPersonalizedContent,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        
                        // Personalized Greeting
                        _buildGreeting(context, authService, colorScheme, textTheme),
                        
                        const SizedBox(height: 32),
                        
                        if (isAuthenticated) ...[
                          // Recently Played
                          if (_recentlyPlayed != null && _recentlyPlayed!.isNotEmpty) ...[
                            _buildSectionHeader('🕒 Recently Played', colorScheme, textTheme),
                            const SizedBox(height: 16),
                            _buildTracksList(_recentlyPlayed!),
                            const SizedBox(height: 32),
                          ],
                          
                          // Top Tracks
                          if (_topTracks != null && _topTracks!.isNotEmpty) ...[
                            _buildSectionHeader('🎵 Your Top Tracks', colorScheme, textTheme),
                            const SizedBox(height: 16),
                            _buildTracksList(_topTracks!),
                            const SizedBox(height: 32),
                          ],
                          
                          // Top Artists
                          if (_topArtists != null && _topArtists!.isNotEmpty) ...[
                            _buildSectionHeader('👤 Your Top Artists', colorScheme, textTheme),
                            const SizedBox(height: 16),
                            _buildArtistsList(_topArtists!),
                            const SizedBox(height: 32),
                          ],
                        ] else ...[
                          // Guest mode - show features
                          _buildGuestModeFeatures(context, colorScheme, textTheme),
                        ],
                        
                        const SizedBox(height: 24),
                        
                        // Footer
                        Center(
                          child: Text(
                            'Powered by Spotify API',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildGreeting(
    BuildContext context,
    SpotifyAuthService authService,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final userName = authService.userName;
    final greeting = _getPersonalizedGreeting(userName);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer,
            colorScheme.secondaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary,
                  colorScheme.secondary,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              authService.isAuthenticated ? Icons.person : Icons.music_note_rounded,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  authService.isAuthenticated
                      ? 'Your personalized music awaits'
                      : 'Discover amazing music',
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onPrimaryContainer.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, ColorScheme colorScheme, TextTheme textTheme) {
    return Text(
      title,
      style: textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
    );
  }

  Widget _buildTracksList(List<Track> tracks) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: tracks.length,
        itemBuilder: (context, index) {
          final track = tracks[index];
          return _buildTrackCard(track);
        },
      ),
    );
  }

  Widget _buildTrackCard(Track track) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
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
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Album Art
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: track.imageUrl != null
                    ? Image.network(
                        track.imageUrl!,
                        width: 160,
                        height: 120,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 160,
                        height: 120,
                        color: colorScheme.surfaceVariant,
                        child: Icon(
                          Icons.music_note,
                          size: 40,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.name,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      track.artistName,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArtistsList(List<Artist> artists) {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: artists.length,
        itemBuilder: (context, index) {
          final artist = artists[index];
          return _buildArtistCard(artist);
        },
      ),
    );
  }

  Widget _buildArtistCard(Artist artist) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ArtistDetailPage(artist: artist),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              // Artist Image
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: artist.imageUrl != null
                    ? Image.network(
                        artist.imageUrl!,
                        width: 140,
                        height: 110,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 140,
                        height: 110,
                        color: colorScheme.surfaceVariant,
                        child: Icon(
                          Icons.person,
                          size: 40,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Text(
                      artist.name,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuestModeFeatures(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Column(
      children: [
        _buildFeatureCard(
          context,
          icon: Icons.search_rounded,
          title: 'Intelligent Search',
          description: 'Search for artists and discover their music instantly.',
          gradient: LinearGradient(
            colors: [
              colorScheme.primaryContainer,
              colorScheme.secondaryContainer,
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildFeatureCard(
          context,
          icon: Icons.auto_awesome,
          title: 'Login for More',
          description: 'Login to see your top tracks, artists, and get AI-powered playlist recommendations!',
          gradient: LinearGradient(
            colors: [
              colorScheme.secondaryContainer,
              colorScheme.tertiaryContainer,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Gradient gradient,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
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
                    title,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSecondaryContainer.withOpacity(0.8),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
