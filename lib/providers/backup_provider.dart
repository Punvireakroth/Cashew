import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../services/backup_service.dart';
import '../services/database_service.dart';
import '../services/google_auth_service.dart';

/// State for backup operations
enum BackupStatus { idle, loading, success, error }

/// State class for backup management
class BackupState {
  final BackupStatus status;
  final String? message;
  final String? error;
  final List<BackupMetadata> localBackups;
  final List<DriveBackupMetadata> driveBackups;
  final bool isGoogleSignedIn;
  final String? googleUserEmail;
  final String? googleUserName;
  final String? googleUserPhotoUrl;

  const BackupState({
    this.status = BackupStatus.idle,
    this.message,
    this.error,
    this.localBackups = const [],
    this.driveBackups = const [],
    this.isGoogleSignedIn = false,
    this.googleUserEmail,
    this.googleUserName,
    this.googleUserPhotoUrl,
  });

  BackupState copyWith({
    BackupStatus? status,
    String? message,
    String? error,
    List<BackupMetadata>? localBackups,
    List<DriveBackupMetadata>? driveBackups,
    bool? isGoogleSignedIn,
    String? googleUserEmail,
    String? googleUserName,
    String? googleUserPhotoUrl,
    bool clearError = false,
    bool clearMessage = false,
  }) {
    return BackupState(
      status: status ?? this.status,
      message: clearMessage ? null : (message ?? this.message),
      error: clearError ? null : (error ?? this.error),
      localBackups: localBackups ?? this.localBackups,
      driveBackups: driveBackups ?? this.driveBackups,
      isGoogleSignedIn: isGoogleSignedIn ?? this.isGoogleSignedIn,
      googleUserEmail: googleUserEmail ?? this.googleUserEmail,
      googleUserName: googleUserName ?? this.googleUserName,
      googleUserPhotoUrl: googleUserPhotoUrl ?? this.googleUserPhotoUrl,
    );
  }
}

/// Provider for backup operations
class BackupNotifier extends StateNotifier<BackupState> {
  final BackupService _backupService;
  final GoogleAuthService _googleAuthService;

  BackupNotifier(this._backupService, this._googleAuthService)
    : super(const BackupState());

  /// Initialize - check Google sign-in status and load backups
  Future<void> init() async {
    state = state.copyWith(status: BackupStatus.loading);

    try {
      // Initialize Google auth
      await _googleAuthService.init();

      // Update Google sign-in state
      _updateGoogleState();

      // Load local backups
      await loadLocalBackups();

      // Load Google Drive backups if signed in
      if (_googleAuthService.isSignedIn) {
        await loadDriveBackups();
      }

      state = state.copyWith(status: BackupStatus.idle);
    } catch (e) {
      state = state.copyWith(
        status: BackupStatus.error,
        error: 'Failed to initialize: $e',
      );
    }
  }

  /// Update Google sign-in state from auth service
  void _updateGoogleState() {
    state = state.copyWith(
      isGoogleSignedIn: _googleAuthService.isSignedIn,
      googleUserEmail: _googleAuthService.userEmail,
      googleUserName: _googleAuthService.userName,
      googleUserPhotoUrl: _googleAuthService.userPhotoUrl,
    );
  }

  // ==================== LOCAL BACKUP OPERATIONS ====================

  /// Create local backup
  Future<bool> createLocalBackup() async {
    state = state.copyWith(
      status: BackupStatus.loading,
      clearError: true,
      clearMessage: true,
    );

    try {
      await _backupService.exportToLocalFile();
      await loadLocalBackups();

      state = state.copyWith(
        status: BackupStatus.success,
        message: 'Backup created successfully',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        status: BackupStatus.error,
        error: 'Failed to create backup: $e',
      );
      return false;
    }
  }

  /// Load list of local backups
  Future<void> loadLocalBackups() async {
    try {
      final backups = await _backupService.listLocalBackups();
      state = state.copyWith(localBackups: backups);
    } catch (e) {
      print('Error loading local backups: $e');
    }
  }

  /// Restore from local backup file
  Future<bool> restoreFromLocalBackup(String filePath) async {
    state = state.copyWith(
      status: BackupStatus.loading,
      clearError: true,
      clearMessage: true,
    );

    try {
      await _backupService.importFromLocalFile(filePath);

      state = state.copyWith(
        status: BackupStatus.success,
        message: 'Backup restored successfully',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        status: BackupStatus.error,
        error: 'Failed to restore backup: $e',
      );
      return false;
    }
  }

  /// Pick and restore from any JSON file
  Future<bool> pickAndRestoreBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) {
        return false;
      }

      final filePath = result.files.single.path;
      if (filePath == null) {
        state = state.copyWith(
          status: BackupStatus.error,
          error: 'Could not access file',
        );
        return false;
      }

      return await restoreFromLocalBackup(filePath);
    } catch (e) {
      state = state.copyWith(
        status: BackupStatus.error,
        error: 'Failed to pick file: $e',
      );
      return false;
    }
  }

  /// Delete a local backup
  Future<bool> deleteLocalBackup(String filePath) async {
    try {
      await _backupService.deleteLocalBackup(filePath);
      await loadLocalBackups();
      state = state.copyWith(message: 'Backup deleted');
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete backup: $e');
      return false;
    }
  }

  // ==================== GOOGLE SIGN-IN OPERATIONS ====================

  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    state = state.copyWith(
      status: BackupStatus.loading,
      clearError: true,
      clearMessage: true,
    );

    try {
      final account = await _googleAuthService.signIn();
      if (account != null) {
        _updateGoogleState();
        await loadDriveBackups();
        state = state.copyWith(
          status: BackupStatus.success,
          message: 'Signed in as ${account.email}',
        );
        return true;
      } else {
        state = state.copyWith(status: BackupStatus.idle);
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        status: BackupStatus.error,
        error: 'Failed to sign in: $e',
      );
      return false;
    }
  }

  /// Sign out from Google
  Future<void> signOutFromGoogle() async {
    state = state.copyWith(
      status: BackupStatus.loading,
      clearError: true,
      clearMessage: true,
    );

    try {
      await _googleAuthService.signOut();
      state = state.copyWith(
        status: BackupStatus.idle,
        isGoogleSignedIn: false,
        googleUserEmail: null,
        googleUserName: null,
        googleUserPhotoUrl: null,
        driveBackups: [],
        message: 'Signed out successfully',
      );
    } catch (e) {
      state = state.copyWith(
        status: BackupStatus.error,
        error: 'Failed to sign out: $e',
      );
    }
  }

  // ==================== GOOGLE DRIVE BACKUP OPERATIONS ====================

  /// Create backup on Google Drive
  Future<bool> createDriveBackup() async {
    if (!_googleAuthService.isSignedIn) {
      state = state.copyWith(error: 'Please sign in to Google first');
      return false;
    }

    state = state.copyWith(
      status: BackupStatus.loading,
      clearError: true,
      clearMessage: true,
    );

    try {
      await _backupService.backupToGoogleDrive();
      await loadDriveBackups();

      state = state.copyWith(
        status: BackupStatus.success,
        message: 'Backup uploaded to Google Drive',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        status: BackupStatus.error,
        error: 'Failed to backup to Drive: $e',
      );
      return false;
    }
  }

  /// Load list of Google Drive backups
  Future<void> loadDriveBackups() async {
    if (!_googleAuthService.isSignedIn) return;

    try {
      final backups = await _backupService.listGoogleDriveBackups();
      state = state.copyWith(driveBackups: backups);
    } catch (e) {
      print('Error loading Drive backups: $e');
    }
  }

  /// Restore from Google Drive backup
  Future<bool> restoreFromDriveBackup(String fileId) async {
    state = state.copyWith(
      status: BackupStatus.loading,
      clearError: true,
      clearMessage: true,
    );

    try {
      await _backupService.restoreFromGoogleDrive(fileId);

      state = state.copyWith(
        status: BackupStatus.success,
        message: 'Backup restored from Google Drive',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        status: BackupStatus.error,
        error: 'Failed to restore from Drive: $e',
      );
      return false;
    }
  }

  /// Delete a Google Drive backup
  Future<bool> deleteDriveBackup(String fileId) async {
    try {
      await _backupService.deleteGoogleDriveBackup(fileId);
      await loadDriveBackups();
      state = state.copyWith(message: 'Drive backup deleted');
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete Drive backup: $e');
      return false;
    }
  }

  /// Clear messages
  void clearMessages() {
    state = state.copyWith(clearError: true, clearMessage: true);
  }

  /// Get backup directory path
  Future<String> getBackupDirectoryPath() async {
    return await _backupService.getBackupDirectoryPath();
  }
}

/// Provider for BackupNotifier
final backupProvider = StateNotifierProvider<BackupNotifier, BackupState>(
  (ref) =>
      BackupNotifier(BackupService(DatabaseService()), GoogleAuthService()),
);
