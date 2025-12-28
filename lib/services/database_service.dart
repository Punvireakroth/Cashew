import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/category.dart';
import '../models/account.dart';
import '../models/budget.dart';
import '../models/transaction.dart' as app_models;

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
        version: 2,
        onCreate: _createDatabase,
        onUpgrade: _onUpgrade,
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

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('Upgrading database from version $oldVersion to $newVersion');

    if (oldVersion < 2) {
      // Migration to version 2: Add budget_categories table and account_id to budgets
      await db.execute('''
        ALTER TABLE budgets ADD COLUMN account_id TEXT REFERENCES accounts(id) ON DELETE SET NULL;
      ''');
      print('Added account_id column to budgets table');

      await db.execute('''
        CREATE TABLE budget_categories (
          budget_id TEXT NOT NULL,
          category_id TEXT NOT NULL UNIQUE,
          PRIMARY KEY (budget_id, category_id),
          FOREIGN KEY (budget_id) REFERENCES budgets(id) ON DELETE CASCADE,
          FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE
        );
      ''');
      print('budget_categories table created');

      await db.execute(
        'CREATE INDEX idx_budget_categories_budget ON budget_categories(budget_id);',
      );
      print('Index created for budget_categories');
    }

    print('Database upgrade complete');
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
          account_id TEXT REFERENCES accounts(id) ON DELETE SET NULL,
          limit_amount REAL NOT NULL,
          start_date INTEGER NOT NULL,
          end_date INTEGER NOT NULL,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        );
      ''');
      print('budgets table created');

      // Create budget_categories junction table
      await db.execute('''
        CREATE TABLE budget_categories (
          budget_id TEXT NOT NULL,
          category_id TEXT NOT NULL UNIQUE,
          PRIMARY KEY (budget_id, category_id),
          FOREIGN KEY (budget_id) REFERENCES budgets(id) ON DELETE CASCADE,
          FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE
        );
      ''');
      print('budget_categories table created');

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
      await db.execute(
        'CREATE INDEX idx_budget_categories_budget ON budget_categories(budget_id);',
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

  // ==================== TRANSACTION CRUD OPERATIONS ====================

  /// Insert a new transaction
  Future<void> insertTransaction(app_models.Transaction transaction) async {
    try {
      final db = await database;
      await db.insert(
        'transactions',
        transaction.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print('Transaction inserted: ${transaction.title}');
    } catch (e) {
      print('Error inserting transaction: $e');
      rethrow;
    }
  }

  /// Update an existing transaction
  Future<void> updateTransaction(app_models.Transaction transaction) async {
    try {
      final db = await database;
      final count = await db.update(
        'transactions',
        transaction.toMap(),
        where: 'id = ?',
        whereArgs: [transaction.id],
      );

      if (count == 0) {
        throw Exception('Transaction not found: ${transaction.id}');
      }

      print('Transaction updated: ${transaction.title}');
    } catch (e) {
      print('Error updating transaction: $e');
      rethrow;
    }
  }

  /// Delete a transaction by id
  Future<void> deleteTransaction(String id) async {
    try {
      final db = await database;
      final count = await db.delete(
        'transactions',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (count == 0) {
        throw Exception('Transaction not found: $id');
      }

      print('Transaction deleted: $id');
    } catch (e) {
      print('Error deleting transaction: $e');
      rethrow;
    }
  }

  /// Get all transactions with pagination
  Future<List<app_models.Transaction>> getTransactions({
    int? limit,
    int? offset,
  }) async {
    try {
      final db = await database;
      final maps = await db.query(
        'transactions',
        orderBy: 'date DESC',
        limit: limit,
        offset: offset,
      );

      return maps.map((map) => app_models.Transaction.fromMap(map)).toList();
    } catch (e) {
      print('Error getting transactions: $e');
      rethrow;
    }
  }

  /// Get filtered transactions with search and filters
  Future<List<app_models.Transaction>> getFilteredTransactions({
    String? searchQuery,
    int? startDate,
    int? endDate,
    List<String>? categoryIds,
    String? accountId,
    String? type, // 'income' or 'expense'
    int? limit,
    int? offset,
  }) async {
    try {
      final db = await database;

      // Build WHERE clause dynamically
      final List<String> whereConditions = [];
      final List<dynamic> whereArgs = [];

      // Search by title or notes
      if (searchQuery != null && searchQuery.isNotEmpty) {
        whereConditions.add('(title LIKE ? OR notes LIKE ?)');
        whereArgs.add('%$searchQuery%');
        whereArgs.add('%$searchQuery%');
      }

      // Filter by date range
      if (startDate != null) {
        whereConditions.add('date >= ?');
        whereArgs.add(startDate);
      }
      if (endDate != null) {
        whereConditions.add('date <= ?');
        whereArgs.add(endDate);
      }

      // Filter by categories
      if (categoryIds != null && categoryIds.isNotEmpty) {
        final placeholders = List.filled(categoryIds.length, '?').join(',');
        whereConditions.add('category_id IN ($placeholders)');
        whereArgs.addAll(categoryIds);
      }

      // Filter by account
      if (accountId != null) {
        whereConditions.add('account_id = ?');
        whereArgs.add(accountId);
      }

      // Filter by type (requires JOIN with categories)
      String query;
      if (type != null) {
        // Use JOIN to filter by transaction type
        final whereClause = whereConditions.isEmpty
            ? 'WHERE c.type = ?'
            : 'WHERE ${whereConditions.join(' AND ')} AND c.type = ?';
        whereArgs.add(type);

        query =
            '''
          SELECT t.* FROM transactions t
          INNER JOIN categories c ON t.category_id = c.id
          $whereClause
          ORDER BY t.date DESC
          ${limit != null ? 'LIMIT $limit' : ''}
          ${offset != null ? 'OFFSET $offset' : ''}
        ''';
      } else {
        final whereClause = whereConditions.isEmpty
            ? ''
            : 'WHERE ${whereConditions.join(' AND ')}';

        query =
            '''
          SELECT * FROM transactions
          $whereClause
          ORDER BY date DESC
          ${limit != null ? 'LIMIT $limit' : ''}
          ${offset != null ? 'OFFSET $offset' : ''}
        ''';
      }

      final maps = await db.rawQuery(query, whereArgs);
      return maps.map((map) => app_models.Transaction.fromMap(map)).toList();
    } catch (e) {
      print('Error getting filtered transactions: $e');
      rethrow;
    }
  }

  /// Get a single transaction by id
  Future<app_models.Transaction?> getTransactionById(String id) async {
    try {
      final db = await database;
      final maps = await db.query(
        'transactions',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isEmpty) {
        return null;
      }

      return app_models.Transaction.fromMap(maps.first);
    } catch (e) {
      print('Error getting transaction by id: $e');
      rethrow;
    }
  }

  /// Get transactions by account
  Future<List<app_models.Transaction>> getTransactionsByAccount(
    String accountId, {
    int? limit,
    int? offset,
  }) async {
    try {
      final db = await database;
      final maps = await db.query(
        'transactions',
        where: 'account_id = ?',
        whereArgs: [accountId],
        orderBy: 'date DESC',
        limit: limit,
        offset: offset,
      );

      return maps.map((map) => app_models.Transaction.fromMap(map)).toList();
    } catch (e) {
      print('Error getting transactions by account: $e');
      rethrow;
    }
  }

  /// Get transactions by category
  Future<List<app_models.Transaction>> getTransactionsByCategory(
    String categoryId, {
    int? limit,
    int? offset,
  }) async {
    try {
      final db = await database;
      final maps = await db.query(
        'transactions',
        where: 'category_id = ?',
        whereArgs: [categoryId],
        orderBy: 'date DESC',
        limit: limit,
        offset: offset,
      );

      return maps.map((map) => app_models.Transaction.fromMap(map)).toList();
    } catch (e) {
      print('Error getting transactions by category: $e');
      rethrow;
    }
  }

  /// Count total transactions (for pagination)
  Future<int> getTransactionCount({
    String? searchQuery,
    int? startDate,
    int? endDate,
    List<String>? categoryIds,
    String? accountId,
    String? type,
  }) async {
    try {
      final db = await database;

      final List<String> whereConditions = [];
      final List<dynamic> whereArgs = [];

      if (searchQuery != null && searchQuery.isNotEmpty) {
        whereConditions.add('(title LIKE ? OR notes LIKE ?)');
        whereArgs.add('%$searchQuery%');
        whereArgs.add('%$searchQuery%');
      }

      if (startDate != null) {
        whereConditions.add('date >= ?');
        whereArgs.add(startDate);
      }
      if (endDate != null) {
        whereConditions.add('date <= ?');
        whereArgs.add(endDate);
      }

      if (categoryIds != null && categoryIds.isNotEmpty) {
        final placeholders = List.filled(categoryIds.length, '?').join(',');
        whereConditions.add('category_id IN ($placeholders)');
        whereArgs.addAll(categoryIds);
      }

      if (accountId != null) {
        whereConditions.add('account_id = ?');
        whereArgs.add(accountId);
      }

      String query;
      if (type != null) {
        final whereClause = whereConditions.isEmpty
            ? 'WHERE c.type = ?'
            : 'WHERE ${whereConditions.join(' AND ')} AND c.type = ?';
        whereArgs.add(type);

        query =
            '''
          SELECT COUNT(*) as count FROM transactions t
          INNER JOIN categories c ON t.category_id = c.id
          $whereClause
        ''';
      } else {
        final whereClause = whereConditions.isEmpty
            ? ''
            : 'WHERE ${whereConditions.join(' AND ')}';

        query = 'SELECT COUNT(*) as count FROM transactions $whereClause';
      }

      final result = await db.rawQuery(query, whereArgs);
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      print('Error counting transactions: $e');
      rethrow;
    }
  }

  /// Calculate total income for a period
  Future<double> getTotalIncome({int? startDate, int? endDate}) async {
    try {
      final db = await database;

      final whereConditions = <String>[];
      final whereArgs = <dynamic>[];

      if (startDate != null) {
        whereConditions.add('t.date >= ?');
        whereArgs.add(startDate);
      }
      if (endDate != null) {
        whereConditions.add('t.date <= ?');
        whereArgs.add(endDate);
      }

      final whereClause = whereConditions.isEmpty
          ? "WHERE c.type = 'income'"
          : "WHERE ${whereConditions.join(' AND ')} AND c.type = 'income'";

      final query =
          '''
        SELECT SUM(t.amount) as total FROM transactions t
        INNER JOIN categories c ON t.category_id = c.id
        $whereClause
      ''';

      final result = await db.rawQuery(query, whereArgs);
      return (result.first['total'] as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      print('Error calculating total income: $e');
      rethrow;
    }
  }

  /// Calculate total expenses for a period
  Future<double> getTotalExpenses({int? startDate, int? endDate}) async {
    try {
      final db = await database;

      final whereConditions = <String>[];
      final whereArgs = <dynamic>[];

      if (startDate != null) {
        whereConditions.add('t.date >= ?');
        whereArgs.add(startDate);
      }
      if (endDate != null) {
        whereConditions.add('t.date <= ?');
        whereArgs.add(endDate);
      }

      final whereClause = whereConditions.isEmpty
          ? "WHERE c.type = 'expense'"
          : "WHERE ${whereConditions.join(' AND ')} AND c.type = 'expense'";

      final query =
          '''
        SELECT SUM(t.amount) as total FROM transactions t
        INNER JOIN categories c ON t.category_id = c.id
        $whereClause
      ''';

      final result = await db.rawQuery(query, whereArgs);
      return (result.first['total'] as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      print('Error calculating total expenses: $e');
      rethrow;
    }
  }

  // ==================== BUDGET CRUD OPERATIONS ====================

  /// Insert a new budget
  Future<void> insertBudget(Budget budget) async {
    try {
      final db = await database;
      await db.insert(
        'budgets',
        budget.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print('Budget inserted: ${budget.name}');
    } catch (e) {
      print('Error inserting budget: $e');
      rethrow;
    }
  }

  /// Update an existing budget
  Future<void> updateBudget(Budget budget) async {
    try {
      final db = await database;
      final count = await db.update(
        'budgets',
        budget.toMap(),
        where: 'id = ?',
        whereArgs: [budget.id],
      );

      if (count == 0) {
        throw Exception('Budget not found: ${budget.id}');
      }

      print('Budget updated: ${budget.name}');
    } catch (e) {
      print('Error updating budget: $e');
      rethrow;
    }
  }

  /// Delete a budget by id
  Future<void> deleteBudget(String id) async {
    try {
      final db = await database;
      final count = await db.delete(
        'budgets',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (count == 0) {
        throw Exception('Budget not found: $id');
      }

      print('Budget deleted: $id');
    } catch (e) {
      print('Error deleting budget: $e');
      rethrow;
    }
  }

  /// Get all budgets
  Future<List<Budget>> getBudgets() async {
    try {
      final db = await database;
      final maps = await db.query('budgets', orderBy: 'start_date DESC');

      return maps.map((map) => Budget.fromMap(map)).toList();
    } catch (e) {
      print('Error getting budgets: $e');
      rethrow;
    }
  }

  /// Get a single budget by id
  Future<Budget?> getBudgetById(String id) async {
    try {
      final db = await database;
      final maps = await db.query(
        'budgets',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isEmpty) {
        return null;
      }

      return Budget.fromMap(maps.first);
    } catch (e) {
      print('Error getting budget by id: $e');
      rethrow;
    }
  }

  /// Get active budgets (current date falls within budget period)
  Future<List<Budget>> getActiveBudgets() async {
    try {
      final db = await database;
      final now = DateTime.now().millisecondsSinceEpoch;

      final maps = await db.query(
        'budgets',
        where: 'start_date <= ? AND end_date >= ?',
        whereArgs: [now, now],
        orderBy: 'start_date DESC',
      );

      return maps.map((map) => Budget.fromMap(map)).toList();
    } catch (e) {
      print('Error getting active budgets: $e');
      rethrow;
    }
  }

  /// Get total expenses within a budget period for specific categories and account
  /// [categoryIds] - list of category IDs to filter by (required)
  /// [accountId] - optional account ID, null means all accounts
  Future<double> getBudgetSpent(
    int startDate,
    int endDate,
    List<String> categoryIds, {
    String? accountId,
  }) async {
    try {
      if (categoryIds.isEmpty) return 0.0;

      final db = await database;
      final placeholders = List.filled(categoryIds.length, '?').join(',');

      final whereConditions = [
        't.date >= ?',
        't.date <= ?',
        "c.type = 'expense'",
        't.category_id IN ($placeholders)',
      ];
      final whereArgs = <dynamic>[startDate, endDate, ...categoryIds];

      if (accountId != null) {
        whereConditions.add('t.account_id = ?');
        whereArgs.add(accountId);
      }

      final query =
          '''
        SELECT SUM(t.amount) as total FROM transactions t
        INNER JOIN categories c ON t.category_id = c.id
        WHERE ${whereConditions.join(' AND ')}
      ''';

      final result = await db.rawQuery(query, whereArgs);
      return (result.first['total'] as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      print('Error calculating budget spent: $e');
      rethrow;
    }
  }

  // ==================== BUDGET CATEGORIES OPERATIONS ====================

  /// Set categories for a budget (replaces existing)
  Future<void> setBudgetCategories(
    String budgetId,
    List<String> categoryIds,
  ) async {
    try {
      final db = await database;

      await db.transaction((txn) async {
        // Delete existing categories for this budget
        await txn.delete(
          'budget_categories',
          where: 'budget_id = ?',
          whereArgs: [budgetId],
        );

        // Insert new categories
        for (final categoryId in categoryIds) {
          await txn.insert('budget_categories', {
            'budget_id': budgetId,
            'category_id': categoryId,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      });

      print(
        'Budget categories set: $budgetId -> ${categoryIds.length} categories',
      );
    } catch (e) {
      print('Error setting budget categories: $e');
      rethrow;
    }
  }

  /// Get category IDs for a budget
  Future<List<String>> getBudgetCategoryIds(String budgetId) async {
    try {
      final db = await database;
      final maps = await db.query(
        'budget_categories',
        columns: ['category_id'],
        where: 'budget_id = ?',
        whereArgs: [budgetId],
      );

      return maps.map((m) => m['category_id'] as String).toList();
    } catch (e) {
      print('Error getting budget category IDs: $e');
      rethrow;
    }
  }

  /// Get expense categories not assigned to any budget
  /// [excludeBudgetId] - optionally include categories from this budget
  Future<List<Category>> getUnassignedExpenseCategories({
    String? excludeBudgetId,
  }) async {
    try {
      final db = await database;

      String query;
      List<dynamic> args;

      if (excludeBudgetId != null) {
        // Include categories assigned to the excluded budget
        query = '''
          SELECT c.* FROM categories c
          WHERE c.type = 'expense'
            AND (c.id NOT IN (SELECT category_id FROM budget_categories)
                 OR c.id IN (SELECT category_id FROM budget_categories WHERE budget_id = ?))
          ORDER BY c.name ASC
        ''';
        args = [excludeBudgetId];
      } else {
        query = '''
          SELECT c.* FROM categories c
          WHERE c.type = 'expense'
            AND c.id NOT IN (SELECT category_id FROM budget_categories)
          ORDER BY c.name ASC
        ''';
        args = [];
      }

      final maps = await db.rawQuery(query, args);
      return maps.map((map) => Category.fromMap(map)).toList();
    } catch (e) {
      print('Error getting unassigned expense categories: $e');
      rethrow;
    }
  }

  /// Check which budget a category is assigned to
  Future<String?> getCategoryBudgetId(String categoryId) async {
    try {
      final db = await database;
      final maps = await db.query(
        'budget_categories',
        columns: ['budget_id'],
        where: 'category_id = ?',
        whereArgs: [categoryId],
        limit: 1,
      );

      if (maps.isEmpty) return null;
      return maps.first['budget_id'] as String;
    } catch (e) {
      print('Error getting category budget ID: $e');
      rethrow;
    }
  }

  /// Check if a budget with the same name exists
  Future<bool> budgetExistsByName(String name, {String? excludeId}) async {
    try {
      final db = await database;
      List<Map<String, dynamic>> maps;

      if (excludeId != null) {
        maps = await db.query(
          'budgets',
          where: 'LOWER(name) = LOWER(?) AND id != ?',
          whereArgs: [name, excludeId],
          limit: 1,
        );
      } else {
        maps = await db.query(
          'budgets',
          where: 'LOWER(name) = LOWER(?)',
          whereArgs: [name],
          limit: 1,
        );
      }

      return maps.isNotEmpty;
    } catch (e) {
      print('Error checking budget existence: $e');
      rethrow;
    }
  }
}
