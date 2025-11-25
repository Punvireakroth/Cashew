import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/category.dart';
import '../models/account.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  /// Get database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize database
  Future<Database> _initDatabase() async {
    try {
      final databasePath = await getDatabasesPath();
      final path = join(databasePath, 'cashchew.db');

      print('Database path: $path');

      return await openDatabase(
        path,
        version: 1,
        onCreate: _createDatabase,
        onConfigure: _onConfigure,
      );
    } catch (e) {
      print('Error initializing database: $e');
      rethrow;
    }
  }

  /// Configure database (enable foreign keys)
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
    print('Foreign keys enabled');
  }

  /// Create all database tables
  Future<void> _createDatabase(Database db, int version) async {
    try {
      print('Creating database tables...');

      // Create accounts table
      await db.execute('''
        CREATE TABLE accounts (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          balance REAL NOT NULL DEFAULT 0,
          currency TEXT NOT NULL DEFAULT 'USD',
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        );
      ''');
      print('accounts table created');

      // Create categories table
      await db.execute('''
        CREATE TABLE categories (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL UNIQUE,
          icon_name TEXT NOT NULL,
          color INTEGER NOT NULL,
          type TEXT NOT NULL CHECK(type IN ('income', 'expense')),
          created_at INTEGER NOT NULL
        );
      ''');
      print('categories table created');

      // Create budgets table
      await db.execute('''
        CREATE TABLE budgets (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          limit_amount REAL NOT NULL,
          start_date INTEGER NOT NULL,
          end_date INTEGER NOT NULL,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        );
      ''');
      print('budgets table created');

      // Create transactions table
      await db.execute('''
        CREATE TABLE transactions (
          id TEXT PRIMARY KEY,
          account_id TEXT NOT NULL,
          category_id TEXT NOT NULL,
          amount REAL NOT NULL,
          title TEXT NOT NULL,
          notes TEXT,
          date INTEGER NOT NULL,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE,
          FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE RESTRICT
        );
      ''');
      print('transactions table created');

      // Create indexes for performance
      await db.execute(
        'CREATE INDEX idx_transactions_date ON transactions(date DESC);',
      );
      await db.execute(
        'CREATE INDEX idx_transactions_account ON transactions(account_id);',
      );
      await db.execute(
        'CREATE INDEX idx_transactions_category ON transactions(category_id);',
      );
      print('Performance indexes created');

      print('Database initialized successfully!');
    } catch (e) {
      print('Error creating database tables: $e');
      rethrow;
    }
  }

  /// Close database connection
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
    print('Database closed');
  }

  /// Delete database
  Future<void> deleteDatabase() async {
    try {
      final databasePath = await getDatabasesPath();
      final path = join(databasePath, 'cashchew.db');
      await databaseFactory.deleteDatabase(path);
      _database = null;
      print('Database deleted');
    } catch (e) {
      print('Error deleting database: $e');
      rethrow;
    }
  }

  /// Get database version
  Future<int> getVersion() async {
    final db = await database;
    return await db.getVersion();
  }

  // ==================== CATEGORY CRUD OPERATIONS ====================

  /// Insert a new category
  Future<void> insertCategory(Category category) async {
    try {
      final db = await database;
      await db.insert(
        'categories',
        category.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print('Category inserted: ${category.name}');
    } catch (e) {
      print('Error inserting category: $e');
      rethrow;
    }
  }

  /// Update an existing category
  Future<void> updateCategory(Category category) async {
    try {
      final db = await database;
      final count = await db.update(
        'categories',
        category.toMap(),
        where: 'id = ?',
        whereArgs: [category.id],
      );

      if (count == 0) {
        throw Exception('Category not found: ${category.id}');
      }

      print('Category updated: ${category.name}');
    } catch (e) {
      print('Error updating category: $e');
      rethrow;
    }
  }

  /// Delete a category by id
  Future<void> deleteCategory(String id) async {
    try {
      final db = await database;
      final count = await db.delete(
        'categories',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (count == 0) {
        throw Exception('Category not found: $id');
      }

      print('Category deleted: $id');
    } catch (e) {
      // Check if deletion failed due to foreign key constraint
      if (e.toString().contains('FOREIGN KEY constraint failed')) {
        throw Exception(
          'Cannot delete category: it is being used by existing transactions',
        );
      }
      print('Error deleting category: $e');
      rethrow;
    }
  }

  /// Get all categories, optionally filtered by type
  Future<List<Category>> getCategories({String? type}) async {
    try {
      final db = await database;
      List<Map<String, dynamic>> maps;

      if (type != null) {
        if (type != 'income' && type != 'expense') {
          throw ArgumentError('Type must be either "income" or "expense"');
        }
        maps = await db.query(
          'categories',
          where: 'type = ?',
          whereArgs: [type],
          orderBy: 'name ASC',
        );
      } else {
        maps = await db.query('categories', orderBy: 'name ASC');
      }

      return maps.map((map) => Category.fromMap(map)).toList();
    } catch (e) {
      print('Error getting categories: $e');
      rethrow;
    }
  }

  /// Get a single category by id
  Future<Category?> getCategoryById(String id) async {
    try {
      final db = await database;
      final maps = await db.query(
        'categories',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isEmpty) {
        return null;
      }

      return Category.fromMap(maps.first);
    } catch (e) {
      print('Error getting category by id: $e');
      rethrow;
    }
  }

  /// Check if a category exists by name
  Future<bool> categoryExistsByName(String name) async {
    try {
      final db = await database;
      final maps = await db.query(
        'categories',
        where: 'LOWER(name) = LOWER(?)',
        whereArgs: [name],
        limit: 1,
      );

      return maps.isNotEmpty;
    } catch (e) {
      print('Error checking category existence: $e');
      rethrow;
    }
  }

  // ==================== ACCOUNT CRUD OPERATIONS ====================

  /// Insert a new account
  Future<void> insertAccount(Account account) async {
    try {
      final db = await database;
      await db.insert(
        'accounts',
        account.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print('Account inserted: ${account.name}');
    } catch (e) {
      print('Error inserting account: $e');
      rethrow;
    }
  }

  /// Update an existing account
  Future<void> updateAccount(Account account) async {
    try {
      final db = await database;
      final count = await db.update(
        'accounts',
        account.toMap(),
        where: 'id = ?',
        whereArgs: [account.id],
      );

      if (count == 0) {
        throw Exception('Account not found: ${account.id}');
      }

      print('Account updated: ${account.name}');
    } catch (e) {
      print('Error updating account: $e');
      rethrow;
    }
  }

  /// Delete an account by id
  Future<void> deleteAccount(String id) async {
    try {
      final db = await database;
      final count = await db.delete(
        'accounts',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (count == 0) {
        throw Exception('Account not found: $id');
      }

      print('Account deleted: $id');
    } catch (e) {
      // Check if deletion failed due to foreign key constraint
      if (e.toString().contains('FOREIGN KEY constraint failed')) {
        throw Exception(
          'Cannot delete account: it has associated transactions',
        );
      }
      print('Error deleting account: $e');
      rethrow;
    }
  }

  /// Get all accounts
  Future<List<Account>> getAccounts() async {
    try {
      final db = await database;
      final maps = await db.query('accounts', orderBy: 'created_at DESC');

      return maps.map((map) => Account.fromMap(map)).toList();
    } catch (e) {
      print('Error getting accounts: $e');
      rethrow;
    }
  }

  /// Get a single account by id
  Future<Account?> getAccountById(String id) async {
    try {
      final db = await database;
      final maps = await db.query(
        'accounts',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isEmpty) {
        return null;
      }

      return Account.fromMap(maps.first);
    } catch (e) {
      print('Error getting account by id: $e');
      rethrow;
    }
  }

  /// Check if an account exists by name
  Future<bool> accountExistsByName(String name, {String? excludeId}) async {
    try {
      final db = await database;
      List<Map<String, dynamic>> maps;

      if (excludeId != null) {
        // Exclude specific account when checking (useful for updates)
        maps = await db.query(
          'accounts',
          where: 'LOWER(name) = LOWER(?) AND id != ?',
          whereArgs: [name, excludeId],
          limit: 1,
        );
      } else {
        maps = await db.query(
          'accounts',
          where: 'LOWER(name) = LOWER(?)',
          whereArgs: [name],
          limit: 1,
        );
      }

      return maps.isNotEmpty;
    } catch (e) {
      print('Error checking account existence: $e');
      rethrow;
    }
  }

  /// Update account balance
  Future<void> updateAccountBalance(String accountId, double newBalance) async {
    try {
      final db = await database;
      final now = DateTime.now().millisecondsSinceEpoch;

      final count = await db.update(
        'accounts',
        {'balance': newBalance, 'updated_at': now},
        where: 'id = ?',
        whereArgs: [accountId],
      );

      if (count == 0) {
        throw Exception('Account not found: $accountId');
      }

      print('Account balance updated: $accountId -> $newBalance');
    } catch (e) {
      print('Error updating account balance: $e');
      rethrow;
    }
  }
}
