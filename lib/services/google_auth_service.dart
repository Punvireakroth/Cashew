import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:http/http.dart' as http;

/// Service for handling Google authentication and Drive API access
class GoogleAuthService {
  static final GoogleAuthService _instance = GoogleAuthService._internal();
  factory GoogleAuthService() => _instance;
  GoogleAuthService._internal();

  static const List<String> _scopes = [
    'email',
    drive.DriveApi.driveAppdataScope, // App-specific folder in Drive
  ];

  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: _scopes);

  GoogleSignInAccount? _currentUser;

  /// Get current signed-in user
  GoogleSignInAccount? get currentUser => _currentUser;

  /// Check if user is signed in
  bool get isSignedIn => _currentUser != null;

  /// Initialize and try silent sign-in
  Future<GoogleSignInAccount?> init() async {
    try {
      // Listen to auth changes
      _googleSignIn.onCurrentUserChanged.listen((account) {
        _currentUser = account;
      });

      // Try to sign in silently
      _currentUser = await _googleSignIn.signInSilently();
      return _currentUser;
    } catch (e) {
      print('GoogleAuthService init error: $e');
      return null;
    }
  }

  /// Sign in with Google
  Future<GoogleSignInAccount?> signIn() async {
    try {
      _currentUser = await _googleSignIn.signIn();
      return _currentUser;
    } catch (e) {
      print('Google Sign-In error: $e');
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      _currentUser = null;
    } catch (e) {
      print('Google Sign-Out error: $e');
      rethrow;
    }
  }

  /// Disconnect (revoke access)
  Future<void> disconnect() async {
    try {
      await _googleSignIn.disconnect();
      _currentUser = null;
    } catch (e) {
      print('Google disconnect error: $e');
      rethrow;
    }
  }

  /// Get authenticated HTTP client for Google APIs
  Future<http.Client?> getAuthenticatedClient() async {
    if (_currentUser == null) {
      return null;
    }

    try {
      final client = await _googleSignIn.authenticatedClient();
      return client;
    } catch (e) {
      print('Error getting authenticated client: $e');
      return null;
    }
  }

  /// Get Drive API instance
  Future<drive.DriveApi?> getDriveApi() async {
    final client = await getAuthenticatedClient();
    if (client == null) return null;

    return drive.DriveApi(client);
  }

  /// Get user's email
  String? get userEmail => _currentUser?.email;

  /// Get user's display name
  String? get userName => _currentUser?.displayName;

  /// Get user's photo URL
  String? get userPhotoUrl => _currentUser?.photoUrl;
}
