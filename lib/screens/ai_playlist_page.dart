import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../services/ai_playlist_service.dart';
import '../models/track_model.dart';
import 'track_detail_page.dart';

class AIPlaylistPage extends StatefulWidget {
  const AIPlaylistPage({super.key});

  @override
  State<AIPlaylistPage> createState() => _AIPlaylistPageState();
}

class _AIPlaylistPageState extends State<AIPlaylistPage>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late Animation<double> _pulseAnimation;
  String _selectedMood = 'balanced';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aiService = context.watch<AIPlaylistService>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Expressive App Bar with playful animations
          SliverAppBar.large(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RotationTransition(
                    turns: _rotateController,
                    child: Icon(
                      Icons.auto_awesome,
                      color: colorScheme.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'AI Playlist',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primaryContainer,
                      colorScheme.secondaryContainer,
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Animated circles in background
                    ...List.generate(5, (index) {
                      return AnimatedBuilder(
                        animation: _rotateController,
                        builder: (context, child) {
                          return Positioned(
                            left: 50.0 + index * 60 + math.sin(_rotateController.value * 2 * math.pi + index) * 20,
                            top: 100.0 + math.cos(_rotateController.value * 2 * math.pi + index) * 30,
                            child: Opacity(
                              opacity: 0.1,
                              child: Container(
                                width: 40 + index * 10.0,
                                height: 40 + index * 10.0,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description
                  Card(
                    color: colorScheme.surfaceVariant.withOpacity(0.3),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.psychology_outlined,
                            size: 48,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Let AI create your perfect playlist',
                            style: theme.textTheme.titleLarge,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Using advanced algorithms to analyze your taste and mood',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Mood Selection
                  Text(
                    'Select Your Mood',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildMoodChip(
                          context,
                          'balanced',
                          Icons.favorite_border,
                          'Balanced',
                          Colors.blue,
                        ),
                        _buildMoodChip(
                          context,
                          'energetic',
                          Icons.flash_on,
                          'Energetic',
                          Colors.orange,
                        ),
                        _buildMoodChip(
                          context,
                          'chill',
                          Icons.spa,
                          'Chill',
                          Colors.purple,
                        ),
                        _buildMoodChip(
                          context,
                          'party',
                          Icons.celebration,
                          'Party',
                          Colors.pink,
                        ),
                        _buildMoodChip(
                          context,
                          'focus',
                          Icons.center_focus_strong,
                          'Focus',
                          Colors.teal,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Quick Actions
                  Text(
                    'Quick Playlists',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickActionCard(
                          context,
                          'Workout',
                          Icons.fitness_center,
                          Colors.red,
                          () => _generatePlaylist(aiService, 'workout'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildQuickActionCard(
                          context,
                          'Study',
                          Icons.school,
                          Colors.indigo,
                          () => _generatePlaylist(aiService, 'focus'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Generate Button
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: SizedBox(
                      width: double.infinity,
                      height: 64,
                      child: ElevatedButton(
                        onPressed: aiService.isGenerating
                            ? null
                            : () => _generatePlaylist(aiService, _selectedMood),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          elevation: 8,
                          shadowColor: colorScheme.primary.withOpacity(0.5),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (aiService.isGenerating)
                              const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: Colors.white,
                                ),
                              )
                            else
                              const Icon(Icons.auto_awesome, size: 28),
                            const SizedBox(width: 12),
                            Text(
                              aiService.isGenerating
                                  ? 'Generating...'
                                  : 'Generate AI Playlist',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Progress Indicator
                  if (aiService.isGenerating) ...[
                    const SizedBox(height: 24),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            LinearProgressIndicator(
                              value: aiService.progress,
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              aiService.currentStep,
                              style: theme.textTheme.bodyLarge,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Generated Tracks
                  if (aiService.generatedTracks.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Your AI Playlist',
                          style: theme.textTheme.titleLarge,
                        ),
                        FilledButton.tonalIcon(
                          onPressed: () => _savePlaylist(aiService),
                          icon: const Icon(Icons.save),
                          label: const Text('Save All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...aiService.generatedTracks.asMap().entries.map(
                          (entry) => _buildTrackCard(
                            context,
                            entry.value,
                            entry.key,
                          ),
                        ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodChip(
    BuildContext context,
    String mood,
    IconData icon,
    String label,
    Color color,
  ) {
    final isSelected = _selectedMood == mood;
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        child: FilterChip(
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _selectedMood = mood;
            });
          },
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          backgroundColor: color.withOpacity(0.1),
          selectedColor: color.withOpacity(0.3),
          checkmarkColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      color: color.withOpacity(0.1),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrackCard(BuildContext context, Track track, int index) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 50)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TrackDetailPage(track: track),
              ),
            );
          },
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Album Art
                Hero(
                  tag: 'track_${track.id}',
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: track.imageUrl != null
                          ? DecorationImage(
                              image: NetworkImage(track.imageUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                      color: colorScheme.surfaceVariant,
                    ),
                    child: track.imageUrl == null
                        ? Icon(
                            Icons.music_note,
                            color: colorScheme.onSurfaceVariant,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                // Track Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        track.artistName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Preview indicator
                if (track.previewUrl != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.play_arrow,
                      color: colorScheme.onPrimaryContainer,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _generatePlaylist(AIPlaylistService aiService, String mood) async {
    switch (mood) {
      case 'workout':
        await aiService.generateWorkoutPlaylist();
        break;
      case 'focus':
        await aiService.generateFocusPlaylist();
        break;
      default:
        await aiService.generateSmartPlaylist(mood: mood);
    }
  }

  Future<void> _savePlaylist(AIPlaylistService aiService) async {
    await aiService.saveGeneratedPlaylist();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text('${aiService.generatedTracks.length} tracks saved to your playlist!'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
    }
  }
}
