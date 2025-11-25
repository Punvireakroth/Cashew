import 'package:flutter/foundation.dart';

@immutable
class Account {
  final String id;
  final String name;
  final double balance;
  final String currency;
  final int createdAt;
  final int updatedAt;

  const Account({
    required this.id,
    required this.name,
    required this.balance,
    required this.currency,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Convert Account to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'balance': balance,
      'currency': currency,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  /// Create Account from Map (database retrieval)
  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'] as String,
      name: map['name'] as String,
      balance: (map['balance'] as num).toDouble(),
      currency: map['currency'] as String,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
    );
  }

  /// Create a copy of Account with updated fields
  Account copyWith({
    String? id,
    String? name,
    double? balance,
    String? currency,
    int? createdAt,
    int? updatedAt,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Account(id: $id, name: $name, balance: $balance, currency: $currency)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Account && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
