import 'package:flutter/foundation.dart';

@immutable
class Transaction {
  final String id;
  final String accountId;
  final String categoryId;
  final double amount;
  final String title;
  final String? notes;
  final int date;
  final int createdAt;
  final int updatedAt;

  const Transaction({
    required this.id,
    required this.accountId,
    required this.categoryId,
    required this.amount,
    required this.title,
    this.notes,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Convert Transaction to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'account_id': accountId,
      'category_id': categoryId,
      'amount': amount,
      'title': title,
      'notes': notes,
      'date': date,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  /// Create Transaction from Map (database retrieval)
  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as String,
      accountId: map['account_id'] as String,
      categoryId: map['category_id'] as String,
      amount: (map['amount'] as num).toDouble(),
      title: map['title'] as String,
      notes: map['notes'] as String?,
      date: map['date'] as int,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
    );
  }

  /// Create a copy of Transaction with updated fields
  Transaction copyWith({
    String? id,
    String? accountId,
    String? categoryId,
    double? amount,
    String? title,
    String? notes,
    int? date,
    int? createdAt,
    int? updatedAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Transaction(id: $id, title: $title, amount: $amount, date: $date)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Transaction && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
