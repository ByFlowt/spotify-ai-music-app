import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../services/spotify_auth_service.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback? onGuestMode;
  
  const LoginPage({super.key, this.onGuestMode});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authService = context.watch<SpotifyAuthService>();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary.withOpacity(0.1),
              colorScheme.secondary.withOpacity(0.1),
              colorScheme.tertiary.withOpacity(0.1),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Animated background circles
            ...List.generate(8, (index) {
              return TweenAnimationBuilder<double>(
                duration: Duration(seconds: 3 + index),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Positioned(
                    left: (index * 100.0) +
                        math.sin(value * 2 * math.pi + index) * 50,
                    top: (index * 80.0) +
                        math.cos(value * 2 * math.pi + index) * 50,
                    child: Opacity(
                      opacity: 0.05,
                      child: Container(
                        width: 100 + index * 20.0,
                        height: 100 + index * 20.0,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  );
                },
                onEnd: () {
                  // Loop animation
                  setState(() {});
                },
              );
            }),

            // Content
            SafeArea(
              child: Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Spotify Icon
                          TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 2000),
                            tween: Tween(begin: 0.0, end: 1.0),
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: value,
                                child: Transform.rotate(
                                  angle: (1 - value) * math.pi * 2,
                                  child: child,
                                ),
                              );
                            },
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF1DB954),
                                    colorScheme.primary,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF1DB954)
                                        .withOpacity(0.4),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.music_note,
                                size: 60,
                                color: Colors.white,
                              ),
                            ),
                          ),

                          const SizedBox(height: 48),

                          // Title
                          Text(
                            'Welcome to',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'AI Music Discovery',
                            style: theme.textTheme.displayMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              background: Paint()
                                ..shader = LinearGradient(
                                  colors: [
                                    const Color(0xFF1DB954),
                                    colorScheme.primary,
                                  ],
                                ).createShader(
                                    const Rect.fromLTWH(0, 0, 400, 70)),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Features
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                children: [
                                  _buildFeatureItem(
                                    context,
                                    Icons.psychology,
                                    'AI-Powered Playlists',
                                    'Gemini 2.0 Flash analyzes your taste',
                                  ),
                                  const SizedBox(height: 16),
                                  _buildFeatureItem(
                                    context,
                                    Icons.history,
                                    'Real Listening History',
                                    'Based on your actual Spotify data',
                                  ),
                                  const SizedBox(height: 16),
                                  _buildFeatureItem(
                                    context,
                                    Icons.auto_awesome,
                                    'Smart Recommendations',
                                    'Personalized music discovery',
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 48),

                          // Login Button
                          if (authService.isLoading)
                            const Column(
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text('Connecting to Spotify...'),
                              ],
                            )
                          else
                            TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 1500),
                              tween: Tween(begin: 0.9, end: 1.1),
                              builder: (context, value, child) {
                                return Transform.scale(
                                  scale: value,
                                  child: child,
                                );
                              },
                              onEnd: () {
                                setState(() {});
                              },
                              child: SizedBox(
                                width: double.infinity,
                                height: 64,
                                child: ElevatedButton(
                                  onPressed: () => _handleLogin(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1DB954),
                                    foregroundColor: Colors.white,
                                    elevation: 8,
                                    shadowColor:
                                        const Color(0xFF1DB954).withOpacity(0.5),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.login,
                                        size: 28,
                                      ),
                                      const SizedBox(width: 16),
                                      Text(
                                        'Login with Spotify',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                          if (authService.error != null) ...[
                            const SizedBox(height: 16),
                            Card(
                              color: colorScheme.errorContainer,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.error_outline,
                                          color: colorScheme.error,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'Login Error',
                                            style: TextStyle(
                                              color: colorScheme.error,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      authService.error!,
                                      style: TextStyle(
                                        color: colorScheme.error,
                                      ),
                                    ),
                                    if (authService.error!.contains('redirect')) ...[
                                      const SizedBox(height: 12),
                                      Text(
                                        '💡 Quick Fix:',
                                        style: TextStyle(
                                          color: colorScheme.error,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '1. Go to developer.spotify.com/dashboard\n'
                                        '2. Click your app → Edit Settings\n'
                                        '3. Add Redirect URI:\n'
                                        '   https://byflowt.github.io/spotify-ai-music-app/\n'
                                        '4. Click Save and try again',
                                        style: TextStyle(
                                          color: colorScheme.error,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 32),

                          // Info
                          Text(
                            '🔒 Your data is secure and private',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'We use OAuth 2.0 with PKCE for authentication',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          
                          // Guest mode button
                          if (widget.onGuestMode != null) ...[
                            const SizedBox(height: 24),
                            OutlinedButton.icon(
                              onPressed: widget.onGuestMode,
                              icon: const Icon(Icons.explore_outlined),
                              label: const Text('Continue as Guest'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                                side: BorderSide(
                                  color: colorScheme.primary.withOpacity(0.5),
                                  width: 2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Try features without logging in\n(Limited functionality)',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.5),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            icon,
            color: colorScheme.onPrimaryContainer,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _handleLogin(BuildContext context) async {
    final authService = context.read<SpotifyAuthService>();
    
    try {
      final success = await authService.login();

      if (success && mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text('Welcome, ${authService.userName ?? "User"}!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
        // Navigation will be handled automatically by AuthWrapper
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Login failed: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      }
    }
  }
}
