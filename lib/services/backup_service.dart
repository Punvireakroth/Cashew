import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:googleapis/drive/v3.dart' as drive;
import 'database_service.dart';
import 'google_auth_service.dart';
import '../models/account.dart';
import '../models/category.dart';
import '../models/budget.dart';
import '../models/transaction.dart' as app_models;

/// Data class representing a complete backup
class BackupData {
  final String version;
  final int createdAt;
  final String appVersion;
  final List<Account> accounts;
  final List<Category> categories;
  final List<Budget> budgets;
  final List<app_models.Transaction> transactions;

  const BackupData({
    required this.version,
    required this.createdAt,
    required this.appVersion,
    required this.accounts,
    required this.categories,
    required this.budgets,
    required this.transactions,
  });

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'created_at': createdAt,
      'app_version': appVersion,
      'data': {
        'accounts': accounts.map((a) => a.toMap()).toList(),
        'categories': categories.map((c) => c.toMap()).toList(),
        'budgets': budgets.map((b) => b.toMap()).toList(),
        'transactions': transactions.map((t) => t.toMap()).toList(),
      },
    };
  }

  factory BackupData.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return BackupData(
      version: json['version'] as String,
      createdAt: json['created_at'] as int,
      appVersion: json['app_version'] as String,
      accounts: (data['accounts'] as List)
          .map((a) => Account.fromMap(a as Map<String, dynamic>))
          .toList(),
      categories: (data['categories'] as List)
          .map((c) => Category.fromMap(c as Map<String, dynamic>))
          .toList(),
      budgets: (data['budgets'] as List)
          .map((b) => Budget.fromMap(b as Map<String, dynamic>))
          .toList(),
      transactions: (data['transactions'] as List)
          .map((t) => app_models.Transaction.fromMap(t as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Metadata for a backup file
class BackupMetadata {
  final String fileName;
  final String filePath;
  final int createdAt;
  final int fileSize;

  const BackupMetadata({
    required this.fileName,
    required this.filePath,
    required this.createdAt,
    required this.fileSize,
  });
}

/// Service for handling backup and restore operations
class BackupService {
  static const String _backupVersion = '1.0';
  static const String _appVersion = '1.0.0';
  static const String _backupFolderName = 'CashChew_Backups';

  final DatabaseService _db;

  BackupService(this._db);

  /// Get the backup directory path
  Future<Directory> get _backupDirectory async {
    final appDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory(p.join(appDir.path, _backupFolderName));
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    return backupDir;
  }

  /// Generate a backup filename with timestamp
  String _generateBackupFileName() {
    final now = DateTime.now();
    final timestamp =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    return 'cashchew_backup_$timestamp.json';
  }

  /// Export all data to a BackupData object
  Future<BackupData> exportData() async {
    final accounts = await _db.getAccounts();
    final categories = await _db.getCategories();
    final budgets = await _db.getBudgets();
    final transactions = await _db.getTransactions();

    return BackupData(
      version: _backupVersion,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      appVersion: _appVersion,
      accounts: accounts,
      categories: categories,
      budgets: budgets,
      transactions: transactions,
    );
  }

  /// Export data to JSON string
  Future<String> exportToJson() async {
    final backupData = await exportData();
    return const JsonEncoder.withIndent('  ').convert(backupData.toJson());
  }

  /// Save backup to local device storage
  Future<String> exportToLocalFile() async {
    final backupDir = await _backupDirectory;
    final fileName = _generateBackupFileName();
    final filePath = p.join(backupDir.path, fileName);

    final jsonString = await exportToJson();
    final file = File(filePath);
    await file.writeAsString(jsonString);

    return filePath;
  }

  /// Validate backup JSON structure
  BackupValidationResult validateBackup(String jsonString) {
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;

      // Check required fields
      if (!json.containsKey('version')) {
        return BackupValidationResult.invalid('Missing backup version');
      }
      if (!json.containsKey('data')) {
        return BackupValidationResult.invalid('Missing data section');
      }

      final data = json['data'] as Map<String, dynamic>;
      if (!data.containsKey('accounts')) {
        return BackupValidationResult.invalid('Missing accounts data');
      }
      if (!data.containsKey('categories')) {
        return BackupValidationResult.invalid('Missing categories data');
      }
      if (!data.containsKey('budgets')) {
        return BackupValidationResult.invalid('Missing budgets data');
      }
      if (!data.containsKey('transactions')) {
        return BackupValidationResult.invalid('Missing transactions data');
      }

      // Try to parse the backup data
      final backupData = BackupData.fromJson(json);

      return BackupValidationResult.valid(backupData);
    } catch (e) {
      return BackupValidationResult.invalid('Invalid backup format: $e');
    }
  }

  /// Import data from JSON string
  Future<void> importFromJson(
    String jsonString, {
    bool clearExisting = true,
  }) async {
    final validation = validateBackup(jsonString);
    if (!validation.isValid) {
      throw Exception(validation.error);
    }

    final backupData = validation.data!;

    if (clearExisting) {
      await _clearAllData();
    }

    // Import in order: categories first (no dependencies), then accounts, budgets, transactions
    for (final category in backupData.categories) {
      await _db.insertCategory(category);
    }

    for (final account in backupData.accounts) {
      await _db.insertAccount(account);
    }

    for (final budget in backupData.budgets) {
      await _db.insertBudget(budget);
    }

    for (final transaction in backupData.transactions) {
      await _db.insertTransaction(transaction);
    }
  }

  /// Import data from a local file
  Future<void> importFromLocalFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Backup file not found');
    }

    final jsonString = await file.readAsString();
    await importFromJson(jsonString);
  }

  /// List all local backup files
  Future<List<BackupMetadata>> listLocalBackups() async {
    final backupDir = await _backupDirectory;
    final backups = <BackupMetadata>[];

    if (!await backupDir.exists()) {
      return backups;
    }

    final files = backupDir.listSync().whereType<File>().where(
      (f) => f.path.endsWith('.json'),
    );

    for (final file in files) {
      final stat = await file.stat();
      backups.add(
        BackupMetadata(
          fileName: p.basename(file.path),
          filePath: file.path,
          createdAt: stat.modified.millisecondsSinceEpoch,
          fileSize: stat.size,
        ),
      );
    }

    // Sort by creation date, newest first
    backups.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return backups;
  }

  /// Delete a local backup file
  Future<void> deleteLocalBackup(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Clear all existing data from database
  Future<void> _clearAllData() async {
    final db = await _db.database;

    // Delete in reverse order of dependencies
    await db.delete('transactions');
    await db.delete('budgets');
    await db.delete('accounts');
    await db.delete('categories');
  }

  /// Get backup directory path (for display purposes)
  Future<String> getBackupDirectoryPath() async {
    final dir = await _backupDirectory;
    return dir.path;
  }

  // ==================== GOOGLE DRIVE BACKUP METHODS ====================

  static const String _driveFolderName = 'appDataFolder';
  static const String _driveBackupMimeType = 'application/json';

  /// Upload backup to Google Drive
  Future<String?> backupToGoogleDrive() async {
    final googleAuth = GoogleAuthService();
    final driveApi = await googleAuth.getDriveApi();

    if (driveApi == null) {
      throw Exception('Not signed in to Google');
    }

    final jsonString = await exportToJson();
    final fileName = _generateBackupFileName();

    // Create file metadata
    final driveFile = drive.File()
      ..name = fileName
      ..parents = [_driveFolderName];

    // Convert string to stream
    final bytes = utf8.encode(jsonString);
    final stream = Stream.value(bytes);

    // Upload file
    final result = await driveApi.files.create(
      driveFile,
      uploadMedia: drive.Media(stream, bytes.length),
    );

    return result.id;
  }

  /// List backups from Google Drive
  Future<List<DriveBackupMetadata>> listGoogleDriveBackups() async {
    final googleAuth = GoogleAuthService();
    final driveApi = await googleAuth.getDriveApi();

    if (driveApi == null) {
      throw Exception('Not signed in to Google');
    }

    final backups = <DriveBackupMetadata>[];

    final result = await driveApi.files.list(
      spaces: _driveFolderName,
      q: "name contains 'cashchew_backup' and mimeType='$_driveBackupMimeType'",
      orderBy: 'modifiedTime desc',
      $fields: 'files(id, name, size, modifiedTime, createdTime)',
    );

    if (result.files != null) {
      for (final file in result.files!) {
        backups.add(
          DriveBackupMetadata(
            fileId: file.id ?? '',
            fileName: file.name ?? '',
            modifiedTime: file.modifiedTime,
            fileSize: int.tryParse(file.size ?? '0') ?? 0,
          ),
        );
      }
    }

    return backups;
  }

  /// Restore backup from Google Drive
  Future<void> restoreFromGoogleDrive(String fileId) async {
    final googleAuth = GoogleAuthService();
    final driveApi = await googleAuth.getDriveApi();

    if (driveApi == null) {
      throw Exception('Not signed in to Google');
    }

    // Download file content
    final response =
        await driveApi.files.get(
              fileId,
              downloadOptions: drive.DownloadOptions.fullMedia,
            )
            as drive.Media;

    final bytes = <int>[];
    await for (final chunk in response.stream) {
      bytes.addAll(chunk);
    }

    final jsonString = utf8.decode(bytes);
    await importFromJson(jsonString);
  }

  /// Delete a backup from Google Drive
  Future<void> deleteGoogleDriveBackup(String fileId) async {
    final googleAuth = GoogleAuthService();
    final driveApi = await googleAuth.getDriveApi();

    if (driveApi == null) {
      throw Exception('Not signed in to Google');
    }

    await driveApi.files.delete(fileId);
  }
}

/// Metadata for a Google Drive backup file
class DriveBackupMetadata {
  final String fileId;
  final String fileName;
  final DateTime? modifiedTime;
  final int fileSize;

  const DriveBackupMetadata({
    required this.fileId,
    required this.fileName,
    this.modifiedTime,
    required this.fileSize,
  });
}

/// Result of backup validation
class BackupValidationResult {
  final bool isValid;
  final String? error;
  final BackupData? data;

  const BackupValidationResult._({
    required this.isValid,
    this.error,
    this.data,
  });

  factory BackupValidationResult.valid(BackupData data) {
    return BackupValidationResult._(isValid: true, data: data);
  }

  factory BackupValidationResult.invalid(String error) {
    return BackupValidationResult._(isValid: false, error: error);
  }
}
