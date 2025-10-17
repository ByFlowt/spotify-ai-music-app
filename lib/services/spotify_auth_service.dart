import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

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
    if (kDebugMode) {
      print('🔐 [AUTH] Starting Spotify login flow...');
      print('🔐 [AUTH] Client ID: $clientId');
      print('🔐 [AUTH] Redirect URI: $redirectUri');
    }
    
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
      
      if (kDebugMode) {
        print('🔐 [AUTH] Scopes requested: $scopes');
      }
      
      // Use Implicit Grant Flow (response_type=token) for web without backend
      final authUrl = Uri.https('accounts.spotify.com', '/authorize', {
        'client_id': clientId,
        'response_type': 'token',  // Implicit flow - returns token directly
        'redirect_uri': redirectUri,
        'scope': scopes,
        'show_dialog': 'false',
      });
      
      if (kDebugMode) {
        print('🔐 [AUTH] Opening authorization URL...');
        print('🔐 [AUTH] URL: $authUrl');
      }
      
      // Open browser for authentication
      if (kDebugMode) {
        print('🔐 [AUTH] Calling FlutterWebAuth2.authenticate...');
      }
      
      final result = await FlutterWebAuth2.authenticate(
        url: authUrl.toString(),
        callbackUrlScheme: 'https',
        options: const FlutterWebAuth2Options(
          intentFlags: ephemeralIntentFlags,
        ),
      );
      
      if (kDebugMode) {
        print('🔐 [AUTH] Received callback result');
        print('🔐 [AUTH] Result URL: $result');
      }
      
      // Extract access token from URL fragment (after #)
      // Format: https://byflowt.github.io/spotify-ai-music-app/#access_token=XXX&token_type=Bearer&expires_in=3600
      final uri = Uri.parse(result);
      
      if (kDebugMode) {
        print('🔐 [AUTH] Parsing callback URI...');
        print('🔐 [AUTH] URI scheme: ${uri.scheme}');
        print('🔐 [AUTH] URI host: ${uri.host}');
        print('🔐 [AUTH] URI path: ${uri.path}');
        print('🔐 [AUTH] URI fragment: ${uri.fragment}');
        print('🔐 [AUTH] URI query: ${uri.query}');
      }
      
      // Parse fragment manually since Uri doesn't parse # fragments as query params
      String? accessToken;
      int? expiresIn;
      
      // Try to parse fragment
      if (uri.fragment.isNotEmpty) {
        if (kDebugMode) {
          print('🔐 [AUTH] Processing fragment parameters...');
        }
        final fragmentParams = Uri.splitQueryString(uri.fragment);
        if (kDebugMode) {
          print('🔐 [AUTH] Fragment params: ${fragmentParams.keys.join(", ")}');
        }
        accessToken = fragmentParams['access_token'];
        expiresIn = int.tryParse(fragmentParams['expires_in'] ?? '3600');
        
        // Also check for error in fragment
        final error = fragmentParams['error'];
        if (error != null) {
          if (kDebugMode) {
            print('❌ [AUTH] Error in fragment: $error');
          }
          throw Exception('Spotify authentication error: $error');
        }
      }
      
      // Also try query params (in case it's in the query instead of fragment)
      if (accessToken == null && uri.queryParameters.isNotEmpty) {
        if (kDebugMode) {
          print('🔐 [AUTH] Trying query parameters...');
        }
        accessToken = uri.queryParameters['access_token'];
        expiresIn = int.tryParse(uri.queryParameters['expires_in'] ?? '3600');
        
        // Also check for error in query params
        final error = uri.queryParameters['error'];
        if (error != null) {
          if (kDebugMode) {
            print('❌ [AUTH] Error in query: $error');
          }
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
      if (kDebugMode) {
        print('🔐 [AUTH] Storing tokens to secure storage...');
      }
      
      _accessToken = accessToken;
      _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn ?? 3600));
      
      await _storage.write(key: 'spotify_access_token', value: _accessToken);
      await _storage.write(key: 'spotify_token_expiry', value: _tokenExpiry!.toIso8601String());
      
      if (kDebugMode) {
        print('✅ [AUTH] Tokens stored successfully');
        print('🔐 [AUTH] Fetching user profile...');
      }
      
      // Get user profile
      await _fetchUserProfile();
      
      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      
      if (kDebugMode) {
        print('✅ [AUTH] Login successful!');
        print('✅ [AUTH] User: ${_userProfile?['display_name'] ?? 'Unknown'}');
        print('✅ [AUTH] Email: ${_userProfile?['email'] ?? 'N/A'}');
      }
      
      return true;
    } catch (e) {
      // Check if user cancelled the login
      if (e.toString().contains('CANCELED') || e.toString().contains('User cancelled')) {
        _error = null; // Don't show error if user cancelled
        if (kDebugMode) {
          print('⚠️ [AUTH] Login cancelled by user');
        }
      } else {
        _error = 'Login failed: ${e.toString()}';
        if (kDebugMode) {
          print('❌ [AUTH] Login error: $e');
          print('❌ [AUTH] Error type: ${e.runtimeType}');
        }
      }
      
      _isLoading = false;
      _isAuthenticated = false;
      notifyListeners();
      
      return false;
    }
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
    if (kDebugMode) {
      print('🔐 [AUTH] Loading stored tokens from secure storage...');
    }
    
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
          if (kDebugMode) {
            print('⚠️ [AUTH] Token expired, clearing auth state');
          }
          await logout();
          return;
        }
        
        // Validate token by trying to fetch user profile
        if (kDebugMode) {
          print('🔐 [AUTH] Validating stored token...');
        }
        
        try {
          await _fetchUserProfile();
          _isAuthenticated = true;
          if (kDebugMode) {
            print('✅ [AUTH] Successfully validated stored token');
            print('✅ [AUTH] Authenticated as: ${_userProfile?['display_name']}');
          }
        } catch (e) {
          // Token is invalid
          if (kDebugMode) {
            print('❌ [AUTH] Stored token is invalid: $e');
          }
          await logout();
          return;
        }
      } else {
        // No stored tokens found - user needs to login
        if (kDebugMode) {
          print('ℹ️ [AUTH] No stored tokens found - guest mode');
        }
        _isAuthenticated = false;
      }
      
      // Always notify listeners when done checking
      if (kDebugMode) {
        print('🔐 [AUTH] Token loading complete. Authenticated: $_isAuthenticated');
      }
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('❌ [AUTH] Error loading stored tokens: $e');
      }
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
