import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'screens/home_page.dart';
import 'screens/search_page.dart';
import 'screens/song_search_page.dart';
import 'screens/my_playlist_page.dart';
import 'screens/ai_playlist_page.dart';
import 'screens/login_page.dart';
import 'services/spotify_service.dart';
import 'services/playlist_manager.dart';
import 'services/ai_playlist_service.dart';
import 'services/spotify_auth_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SpotifyAuthService()),
        ChangeNotifierProvider(create: (_) => SpotifyService()),
        ChangeNotifierProvider(create: (_) => PlaylistManager()),
        ChangeNotifierProxyProvider2<SpotifyService, PlaylistManager, AIPlaylistService>(
          create: (context) => AIPlaylistService(
            context.read<SpotifyService>(),
            context.read<PlaylistManager>(),
          ),
          update: (context, spotify, playlist, previous) =>
              previous ?? AIPlaylistService(spotify, playlist),
        ),
      ],
      child: MaterialApp(
        title: 'Spotify AI Discovery',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1DB954), // Spotify Green
            brightness: Brightness.light,
          ),
          // Expressive typography with playful fonts
          textTheme: GoogleFonts.spaceGroteskTextTheme().copyWith(
            displayLarge: GoogleFonts.spaceGrotesk(
              fontSize: 57,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
            displayMedium: GoogleFonts.spaceGrotesk(
              fontSize: 45,
              fontWeight: FontWeight.w700,
            ),
            headlineLarge: GoogleFonts.spaceGrotesk(
              fontSize: 32,
              fontWeight: FontWeight.w700,
            ),
            titleLarge: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
            bodyLarge: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
          // Expressive shapes with more rounded corners
          cardTheme: CardTheme(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          chipTheme: ChipThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(24)),
            ),
          ),
          // Expressive elevation and shadows
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 3,
              shadowColor: const Color(0xFF1DB954).withOpacity(0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          ),
          // Expressive navigation bar
          navigationBarTheme: NavigationBarThemeData(
            height: 80,
            elevation: 3,
            indicatorShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1DB954),
            brightness: Brightness.dark,
          ),
          textTheme: GoogleFonts.spaceGroteskTextTheme(ThemeData.dark().textTheme).copyWith(
            displayLarge: GoogleFonts.spaceGrotesk(
              fontSize: 57,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: Colors.white,
            ),
            displayMedium: GoogleFonts.spaceGrotesk(
              fontSize: 45,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            headlineLarge: GoogleFonts.spaceGrotesk(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            titleLarge: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            bodyLarge: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.white70,
            ),
          ),
          cardTheme: CardTheme(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          chipTheme: ChipThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(24)),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 3,
              shadowColor: const Color(0xFF1DB954).withOpacity(0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          ),
          navigationBarTheme: NavigationBarThemeData(
            height: 80,
            elevation: 3,
            indicatorShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
        themeMode: ThemeMode.system,
        home: const AuthWrapper(),
      ),
    );
  }
}

// Wrapper to show login or main app based on auth state
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Check for existing auth token when app starts
    await context.read<SpotifyAuthService>().checkAuthStatus();
    
    // Done checking
    if (mounted) {
      setState(() {
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<SpotifyAuthService>();
    
    // Show loading splash while checking initial auth status
    if (_isChecking || authService.isLoading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.1),
                Theme.of(context).colorScheme.secondary.withOpacity(0.1),
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: const Color(0xFF1DB954),
                ),
                const SizedBox(height: 24),
                Text(
                  'Loading...',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    // Only show main app if authenticated with valid token
    if (authService.isAuthenticated && authService.accessToken != null) {
      return const MainNavigator();
    }
    
    // Show login if not authenticated or no token
    return const LoginPage();
  }
}

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const SearchPage(),
    const AIPlaylistPage(),
    const SongSearchPage(),
    const MyPlaylistPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final playlistManager = context.watch<PlaylistManager>();
    
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _pages[_currentIndex],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_search_outlined),
            selectedIcon: Icon(Icons.person_search),
            label: 'Artists',
          ),
          const NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: 'AI',
          ),
          const NavigationDestination(
            icon: Icon(Icons.music_note_outlined),
            selectedIcon: Icon(Icons.music_note),
            label: 'Songs',
          ),
          NavigationDestination(
            icon: Badge(
              label: playlistManager.count > 0 
                  ? Text('${playlistManager.count}')
                  : null,
              isLabelVisible: playlistManager.count > 0,
              child: const Icon(Icons.playlist_play_outlined),
            ),
            selectedIcon: Badge(
              label: playlistManager.count > 0 
                  ? Text('${playlistManager.count}')
                  : null,
              isLabelVisible: playlistManager.count > 0,
              child: const Icon(Icons.playlist_play),
            ),
            label: 'My List',
          ),
        ],
      ),
    );
  }
}
