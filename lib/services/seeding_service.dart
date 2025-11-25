import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'database_service.dart';
import '../models/category.dart';

/// Service to seed default data into the database
class SeedingService {
  final DatabaseService _db;
  final Uuid _uuid = const Uuid();

  SeedingService(this._db);

  /// Seed all default data
  Future<void> seedDefaultData() async {
    try {
      print('Starting to seed default data...');
      await _seedCategories();
      print('Default data seeded successfully!');
    } catch (e) {
      print('Error seeding default data: $e');
      rethrow;
    }
  }

  /// Seed default expense and income categories
  Future<void> _seedCategories() async {
    final now = DateTime.now().millisecondsSinceEpoch;

    // Check if categories already exist
    final existingCategories = await _db.getCategories();
    if (existingCategories.isNotEmpty) {
      print('Categories already exist, skipping seeding');
      return;
    }

    // Default Expense Categories
    final expenseCategories = [
      Category(
        id: _uuid.v4(),
        name: 'Food & Dining',
        iconName: 'restaurant',
        color: Colors.orange.value,
        type: 'expense',
        createdAt: now,
      ),
      Category(
        id: _uuid.v4(),
        name: 'Transportation',
        iconName: 'directions_car',
        color: Colors.blue.value,
        type: 'expense',
        createdAt: now,
      ),
      Category(
        id: _uuid.v4(),
        name: 'Shopping',
        iconName: 'shopping_bag',
        color: Colors.purple.value,
        type: 'expense',
        createdAt: now,
      ),
      Category(
        id: _uuid.v4(),
        name: 'Entertainment',
        iconName: 'movie',
        color: Colors.pink.value,
        type: 'expense',
        createdAt: now,
      ),
      Category(
        id: _uuid.v4(),
        name: 'Bills & Utilities',
        iconName: 'receipt_long',
        color: Colors.red.value,
        type: 'expense',
        createdAt: now,
      ),
      Category(
        id: _uuid.v4(),
        name: 'Healthcare',
        iconName: 'medical_services',
        color: Colors.teal.value,
        type: 'expense',
        createdAt: now,
      ),
      Category(
        id: _uuid.v4(),
        name: 'Education',
        iconName: 'school',
        color: Colors.indigo.value,
        type: 'expense',
        createdAt: now,
      ),
      Category(
        id: _uuid.v4(),
        name: 'Travel',
        iconName: 'flight',
        color: Colors.cyan.value,
        type: 'expense',
        createdAt: now,
      ),
      Category(
        id: _uuid.v4(),
        name: 'Housing',
        iconName: 'home',
        color: Colors.brown.value,
        type: 'expense',
        createdAt: now,
      ),
      Category(
        id: _uuid.v4(),
        name: 'Personal Care',
        iconName: 'spa',
        color: Colors.pinkAccent.value,
        type: 'expense',
        createdAt: now,
      ),
      Category(
        id: _uuid.v4(),
        name: 'Fitness & Sports',
        iconName: 'fitness_center',
        color: Colors.deepOrange.value,
        type: 'expense',
        createdAt: now,
      ),
      Category(
        id: _uuid.v4(),
        name: 'Other Expenses',
        iconName: 'more_horiz',
        color: Colors.grey.value,
        type: 'expense',
        createdAt: now,
      ),
    ];

    // Default Income Categories
    final incomeCategories = [
      Category(
        id: _uuid.v4(),
        name: 'Salary',
        iconName: 'work',
        color: Colors.green.value,
        type: 'income',
        createdAt: now,
      ),
      Category(
        id: _uuid.v4(),
        name: 'Business',
        iconName: 'business_center',
        color: Colors.lightGreen.value,
        type: 'income',
        createdAt: now,
      ),
      Category(
        id: _uuid.v4(),
        name: 'Investments',
        iconName: 'trending_up',
        color: Colors.teal.value,
        type: 'income',
        createdAt: now,
      ),
      Category(
        id: _uuid.v4(),
        name: 'Freelance',
        iconName: 'laptop_mac',
        color: Colors.blue.value,
        type: 'income',
        createdAt: now,
      ),
      Category(
        id: _uuid.v4(),
        name: 'Gifts',
        iconName: 'card_giftcard',
        color: Colors.pink.value,
        type: 'income',
        createdAt: now,
      ),
      Category(
        id: _uuid.v4(),
        name: 'Rental Income',
        iconName: 'apartment',
        color: Colors.amber.value,
        type: 'income',
        createdAt: now,
      ),
      Category(
        id: _uuid.v4(),
        name: 'Refunds',
        iconName: 'money_off',
        color: Colors.lightBlue.value,
        type: 'income',
        createdAt: now,
      ),
      Category(
        id: _uuid.v4(),
        name: 'Other Income',
        iconName: 'more_horiz',
        color: Colors.grey.value,
        type: 'income',
        createdAt: now,
      ),
    ];

    // Insert all categories into the database
    final allCategories = [...expenseCategories, ...incomeCategories];

    for (var category in allCategories) {
      await _db.insertCategory(category);
    }

    print('${expenseCategories.length} expense categories seeded');
    print('${incomeCategories.length} income categories seeded');
    print('Total ${allCategories.length} categories created');
  }
}
