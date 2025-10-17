import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/spotify_auth_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late ThemeMode _currentThemeMode;
  bool _notificationsEnabled = true;
  bool _analyticsEnabled = true;

  @override
  void initState() {
    super.initState();
    _currentThemeMode = ThemeMode.system;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final authService = context.watch<SpotifyAuthService>();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header with gradient
              Container(
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
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.settings_rounded,
                        size: 24,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Settings',
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Settings Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Appearance Section
                    _buildSectionTitle('Appearance', colorScheme, textTheme),
                    const SizedBox(height: 12),
                    _buildThemeCard(context, colorScheme, textTheme),
                    const SizedBox(height: 24),

                    // Preferences Section
                    _buildSectionTitle('Preferences', colorScheme, textTheme),
                    const SizedBox(height: 12),
                    _buildToggleCard(
                      context,
                      Icons.notifications_outlined,
                      'Notifications',
                      'Get updates and recommendations',
                      _notificationsEnabled,
                      (value) {
                        setState(() {
                          _notificationsEnabled = value;
                        });
                      },
                      colorScheme,
                      textTheme,
                    ),
                    const SizedBox(height: 12),
                    _buildToggleCard(
                      context,
                      Icons.analytics_outlined,
                      'Analytics',
                      'Help us improve the app',
                      _analyticsEnabled,
                      (value) {
                        setState(() {
                          _analyticsEnabled = value;
                        });
                      },
                      colorScheme,
                      textTheme,
                    ),
                    const SizedBox(height: 24),

                    // Account Section
                    _buildSectionTitle('Account', colorScheme, textTheme),
                    const SizedBox(height: 12),
                    if (authService.isAuthenticated) ...[
                      _buildAccountCard(context, authService, colorScheme, textTheme),
                      const SizedBox(height: 12),
                      _buildLogoutButton(context, authService, colorScheme, textTheme),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colorScheme.outlineVariant.withOpacity(0.5),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.person_outline_rounded,
                              size: 48,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Not logged in',
                              style: textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Login to access personalized features',
                              textAlign: TextAlign.center,
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),

                    // About Section
                    _buildSectionTitle('About', colorScheme, textTheme),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      Icons.info_outline_rounded,
                      'App Version',
                      '1.0.0',
                      colorScheme,
                      textTheme,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      Icons.open_in_browser_rounded,
                      'GitHub Repository',
                      'ByFlowt/spotify-ai-music-app',
                      colorScheme,
                      textTheme,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ColorScheme colorScheme, TextTheme textTheme) {
    return Text(
      title,
      style: textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: colorScheme.primary,
      ),
    );
  }

  Widget _buildThemeCard(BuildContext context, ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.brightness_6_rounded,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Text(
                'Dark Mode',
                style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildThemeOption(
                  context,
                  'System',
                  ThemeMode.system,
                  Icons.brightness_auto_rounded,
                  colorScheme,
                  textTheme,
                ),
                const SizedBox(width: 12),
                _buildThemeOption(
                  context,
                  'Light',
                  ThemeMode.light,
                  Icons.brightness_7_rounded,
                  colorScheme,
                  textTheme,
                ),
                const SizedBox(width: 12),
                _buildThemeOption(
                  context,
                  'Dark',
                  ThemeMode.dark,
                  Icons.brightness_4_rounded,
                  colorScheme,
                  textTheme,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    String label,
    ThemeMode mode,
    IconData icon,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final isSelected = _currentThemeMode == mode || 
        (mode == ThemeMode.system && _currentThemeMode == ThemeMode.system);

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentThemeMode = mode;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Theme set to $label'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(milliseconds: 1500),
          ),
        );
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? colorScheme.primary.withOpacity(0.2) : colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? colorScheme.primary : colorScheme.outlineVariant.withOpacity(0.3),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Icon(
              icon,
              color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleCard(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  subtitle,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard(
    BuildContext context,
    SpotifyAuthService authService,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary.withOpacity(0.1),
            colorScheme.secondary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.person_rounded,
              color: colorScheme.primary,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Logged in to Spotify',
                  style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Premium access enabled',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF1DB954).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.check_circle,
              color: Color(0xFF1DB954),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(
    BuildContext context,
    SpotifyAuthService authService,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Logout?'),
              content: const Text('Are you sure you want to logout from Spotify?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    await authService.logout();
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Logged out successfully'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  child: const Text('Logout'),
                ),
              ],
            ),
          );
        },
        icon: const Icon(Icons.logout_rounded),
        label: const Text('Logout'),
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.error,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    IconData icon,
    String title,
    String value,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: colorScheme.secondary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
