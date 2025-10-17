import 'dart:convert';
import 'dart:html' as html;
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

// Helper function for web console logging
void _log(String message) {
  if (kIsWeb) {
    html.window.console.log(message);
  } else if (kDebugMode) {
    print(message);
  }
}

void _logError(String message) {
  if (kIsWeb) {
    html.window.console.error(message);
  } else if (kDebugMode) {
    print(message);
  }
}

class SpotifyAuthService extends ChangeNotifier {
  static const String clientId = 'ce1797970d2d4ec8852fa68a54fe8a8f';
  // GitHub Pages URL - must match Spotify Dashboard redirect URI
  static const String redirectUri = 'https://byflowt.github.io/spotify-ai-music-app/';
  
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  String? _accessToken;
  String? _refreshToken;
  DateTime? _tokenExpiry;
  Map<String, dynamic>? _userProfile;
  
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _error;
  
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get accessToken => _accessToken;
  Map<String, dynamic>? get userProfile => _userProfile;
  String? get userName => _userProfile?['display_name'];
  String? get userEmail => _userProfile?['email'];
  String? get userImage => _userProfile?['images']?[0]?['url'];
  
  SpotifyAuthService() {
    _loadStoredTokens();
    // Check if we're returning from OAuth callback
    if (kIsWeb) {
      _checkForAuthCallback();
    }
  }
  
  // Check if current URL has auth callback parameters
  Future<void> _checkForAuthCallback() async {
    try {
      final currentUrl = html.window.location.href;
      _log('🔐 [AUTH] Checking current URL for auth callback: $currentUrl');
      
      // Check if we have an access token in the URL fragment
      final fragment = html.window.location.hash;
      if (fragment.isNotEmpty && fragment.contains('access_token')) {
        _log('🔐 [AUTH] Found access token in URL fragment!');
        
        // Check if auth was in progress
        final authInProgress = await _storage.read(key: 'spotify_auth_in_progress');
        if (authInProgress == 'true') {
          _log('🔐 [AUTH] Processing OAuth callback...');
          await _storage.delete(key: 'spotify_auth_in_progress');
          
          // Process the callback
          await _processAuthCallback(currentUrl);
          
          // Clean the URL
          html.window.history.replaceState(null, '', html.window.location.pathname);
        }
      }
    } catch (e) {
      _logError('❌ [AUTH] Error checking for auth callback: $e');
    }
  }
  
  // Public method to check auth status (calls _loadStoredTokens)
  Future<void> checkAuthStatus() async {
    await _loadStoredTokens();
  }
  
  // Generate random string for PKCE
  String _generateRandomString(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final random = Random.secure();
    return List.generate(length, (index) => chars[random.nextInt(chars.length)]).join();
  }
  
  // Generate code verifier and challenge for PKCE
  Map<String, String> _generatePKCE() {
    final codeVerifier = _generateRandomString(128);
    final bytes = utf8.encode(codeVerifier);
    final digest = sha256.convert(bytes);
    final codeChallenge = base64Url.encode(digest.bytes).replaceAll('=', '');
    
    return {
      'codeVerifier': codeVerifier,
      'codeChallenge': codeChallenge,
    };
  }
  
  // Login with Spotify OAuth - Using Implicit Grant Flow for web
  Future<bool> login() async {
    // Always log to browser console for web debugging
    _log('🔐 [AUTH] Starting Spotify login flow...');
    _log('🔐 [AUTH] Client ID: $clientId');
    _log('🔐 [AUTH] Redirect URI: $redirectUri');
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Define required scopes for listening history and playlists
      final scopes = [
        'user-read-private',
        'user-read-email',
        'user-top-read',
        'user-read-recently-played',
        'playlist-modify-public',
        'playlist-modify-private',
      ].join(' ');
      
      _log('🔐 [AUTH] Scopes requested: $scopes');
      
      // Use Implicit Grant Flow (response_type=token) for web without backend
      final authUrl = Uri.https('accounts.spotify.com', '/authorize', {
        'client_id': clientId,
        'response_type': 'token',  // Implicit flow - returns token directly
        'redirect_uri': redirectUri,
        'scope': scopes,
        'show_dialog': 'false',
      });
      
      _log('🔐 [AUTH] Opening authorization URL...');
      _log('🔐 [AUTH] URL: $authUrl');
      
      // For web, use direct window navigation instead of FlutterWebAuth2
      if (kIsWeb) {
        _log('🔐 [AUTH] Using web window navigation...');
        
        // Store state that we're authenticating
        await _storage.write(key: 'spotify_auth_in_progress', value: 'true');
        
        // Redirect current window to Spotify auth
        html.window.location.href = authUrl.toString();
        
        // This won't return - the page will redirect
        return false;
      } else {
        // For non-web platforms, use FlutterWebAuth2
        _log('🔐 [AUTH] Using FlutterWebAuth2 for mobile...');
        
        final result = await FlutterWebAuth2.authenticate(
          url: authUrl.toString(),
          callbackUrlScheme: 'https',
          options: const FlutterWebAuth2Options(
            intentFlags: ephemeralIntentFlags,
          ),
        );
        
        _log('🔐 [AUTH] Received callback result');
        _log('🔐 [AUTH] Result URL: $result');
        
        return await _processAuthCallback(result);
      }
    } catch (e) {
      return _handleAuthError(e);
    }
  }
  
  // Process authentication callback
  Future<bool> _processAuthCallback(String result) async {
    try {
      // Extract access token from URL fragment (after #)
      // Format: https://byflowt.github.io/spotify-ai-music-app/#access_token=XXX&token_type=Bearer&expires_in=3600
      final uri = Uri.parse(result);
      
      _log('🔐 [AUTH] Parsing callback URI...');
      _log('🔐 [AUTH] URI scheme: ${uri.scheme}');
      _log('🔐 [AUTH] URI host: ${uri.host}');
      _log('🔐 [AUTH] URI path: ${uri.path}');
      _log('🔐 [AUTH] URI fragment: ${uri.fragment}');
      _log('🔐 [AUTH] URI query: ${uri.query}');
      
      // Parse fragment manually since Uri doesn't parse # fragments as query params
      String? accessToken;
      int? expiresIn;
      
      // Try to parse fragment
      if (uri.fragment.isNotEmpty) {
        _log('🔐 [AUTH] Processing fragment parameters...');
        final fragmentParams = Uri.splitQueryString(uri.fragment);
        _log('🔐 [AUTH] Fragment params: ${fragmentParams.keys.join(", ")}');
        accessToken = fragmentParams['access_token'];
        expiresIn = int.tryParse(fragmentParams['expires_in'] ?? '3600');
        
        // Also check for error in fragment
        final error = fragmentParams['error'];
        if (error != null) {
          _log('❌ [AUTH] Error in fragment: $error');
          throw Exception('Spotify authentication error: $error');
        }
      }
      
      // Also try query params (in case it's in the query instead of fragment)
      if (accessToken == null && uri.queryParameters.isNotEmpty) {
        _log('🔐 [AUTH] Trying query parameters...');
        accessToken = uri.queryParameters['access_token'];
        expiresIn = int.tryParse(uri.queryParameters['expires_in'] ?? '3600');
        
        // Also check for error in query params
        final error = uri.queryParameters['error'];
        if (error != null) {
          _log('❌ [AUTH] Error in query: $error');
          throw Exception('Spotify authentication error: $error');
        }
      }
      
      if (accessToken == null || accessToken.isEmpty) {
        if (kDebugMode) {
          print('❌ [AUTH] Failed to extract access token');
          print('❌ [AUTH] Full result URL: $result');
        }
        throw Exception('No access token received from Spotify. Please try again.');
      }
      
      if (kDebugMode) {
        print('✅ [AUTH] Successfully extracted access token');
        print('✅ [AUTH] Token length: ${accessToken.length} characters');
        print('✅ [AUTH] Expires in: $expiresIn seconds');
      }
      
      // Store tokens
      _log('🔐 [AUTH] Storing tokens to secure storage...');
      
      _accessToken = accessToken;
      _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn ?? 3600));
      
      await _storage.write(key: 'spotify_access_token', value: _accessToken);
      await _storage.write(key: 'spotify_token_expiry', value: _tokenExpiry!.toIso8601String());
      
      _log('✅ [AUTH] Tokens stored successfully');
      _log('🔐 [AUTH] Fetching user profile...');
      
      // Get user profile
      await _fetchUserProfile();
      
      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      
      _log('✅ [AUTH] Login successful!');
      _log('✅ [AUTH] User: ${_userProfile?['display_name'] ?? 'Unknown'}');
      _log('✅ [AUTH] Email: ${_userProfile?['email'] ?? 'N/A'}');
      
      return true;
    } catch (e) {
      return _handleAuthError(e);
    }
  }
  
  // Handle authentication errors
  bool _handleAuthError(dynamic e) {
    // Check if user cancelled the login
    if (e.toString().contains('CANCELED') || e.toString().contains('User cancelled')) {
      _error = null; // Don't show error if user cancelled
      _log('⚠️ [AUTH] Login cancelled by user');
    } else {
      _error = 'Login failed: ${e.toString()}';
      _logError('❌ [AUTH] Login error: $e');
      _logError('❌ [AUTH] Error type: ${e.runtimeType}');
    }
    
    _isLoading = false;
    _isAuthenticated = false;
    notifyListeners();
    
    return false;
  }
  
  // Exchange authorization code for access and refresh tokens
  Future<void> _exchangeCodeForTokens(String code, String codeVerifier) async {
    final response = await http.post(
      Uri.parse('https://accounts.spotify.com/api/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': redirectUri,
        'client_id': clientId,
        'code_verifier': codeVerifier,
      },
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _accessToken = data['access_token'];
      _refreshToken = data['refresh_token'];
      _tokenExpiry = DateTime.now().add(Duration(seconds: data['expires_in']));
      
      // Store tokens securely
      await _storage.write(key: 'spotify_access_token', value: _accessToken);
      await _storage.write(key: 'spotify_refresh_token', value: _refreshToken);
      await _storage.write(key: 'spotify_token_expiry', value: _tokenExpiry!.toIso8601String());
    } else {
      throw Exception('Token exchange failed: ${response.body}');
    }
  }
  
  // Refresh access token (for Implicit Flow, user needs to re-authenticate)
  Future<void> refreshAccessToken() async {
    // Implicit Grant Flow doesn't provide refresh tokens
    // User needs to login again when token expires
    _isAuthenticated = false;
    _accessToken = null;
    notifyListeners();
    throw Exception('Token expired. Please login again.');
  }
  
  // Check if token needs refresh
  Future<bool> ensureValidToken() async {
    if (_accessToken == null) return false;
    
    if (_tokenExpiry != null && DateTime.now().isAfter(_tokenExpiry!)) {
      // Token expired, user needs to re-login
      _isAuthenticated = false;
      _accessToken = null;
      notifyListeners();
      return false;
    }
    
    return true;
  }
  
  // Fetch user profile
  Future<void> _fetchUserProfile() async {
    final response = await http.get(
      Uri.parse('https://api.spotify.com/v1/me'),
      headers: {'Authorization': 'Bearer $_accessToken'},
    );
    
    if (response.statusCode == 200) {
      _userProfile = jsonDecode(response.body);
      await _storage.write(key: 'spotify_user_profile', value: response.body);
    }
  }
  
  // Load stored tokens on app start
  Future<void> _loadStoredTokens() async {
    _log('🔐 [AUTH] Loading stored tokens from secure storage...');
    
    try {
      _accessToken = await _storage.read(key: 'spotify_access_token');
      _refreshToken = await _storage.read(key: 'spotify_refresh_token');
      
      final expiryString = await _storage.read(key: 'spotify_token_expiry');
      if (expiryString != null) {
        _tokenExpiry = DateTime.parse(expiryString);
      }
      
      final profileString = await _storage.read(key: 'spotify_user_profile');
      if (profileString != null) {
        _userProfile = jsonDecode(profileString);
      }
      
      if (kDebugMode) {
        print('🔐 [AUTH] Access token found: ${_accessToken != null}');
        print('🔐 [AUTH] Token expiry: $_tokenExpiry');
        print('🔐 [AUTH] User profile cached: ${_userProfile != null}');
      }
      
      if (_accessToken != null) {
        // Check if token is expired
        if (_tokenExpiry != null && DateTime.now().isAfter(_tokenExpiry!)) {
          // Token expired - with Implicit Grant we need to re-authenticate
          _log('⚠️ [AUTH] Token expired, clearing auth state');
          await logout();
          return;
        }
        
        // Validate token by trying to fetch user profile
        _log('🔐 [AUTH] Validating stored token...');
        
        try {
          await _fetchUserProfile();
          _isAuthenticated = true;
          if (kDebugMode) {
            print('✅ [AUTH] Successfully validated stored token');
            print('✅ [AUTH] Authenticated as: ${_userProfile?['display_name']}');
          }
        } catch (e) {
          // Token is invalid
          _log('❌ [AUTH] Stored token is invalid: $e');
          await logout();
          return;
        }
      } else {
        // No stored tokens found - user needs to login
        _log('ℹ️ [AUTH] No stored tokens found - guest mode');
        _isAuthenticated = false;
      }
      
      // Always notify listeners when done checking
      _log('🔐 [AUTH] Token loading complete. Authenticated: $_isAuthenticated');
      notifyListeners();
    } catch (e) {
      _log('❌ [AUTH] Error loading stored tokens: $e');
      await logout();
    }
  }
  
  // Logout
  Future<void> logout() async {
    _accessToken = null;
    _refreshToken = null;
    _tokenExpiry = null;
    _userProfile = null;
    _isAuthenticated = false;
    
    await _storage.delete(key: 'spotify_access_token');
    await _storage.delete(key: 'spotify_refresh_token');
    await _storage.delete(key: 'spotify_token_expiry');
    await _storage.delete(key: 'spotify_user_profile');
    
    notifyListeners();
  }
}

