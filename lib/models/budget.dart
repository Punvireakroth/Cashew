import 'package:flutter/foundation.dart';

@immutable
class Budget {
  final String id;
  final String name;
  final String? accountId; // null = track all accounts
  final double limitAmount;
  final int startDate;
  final int endDate;
  final bool isArchived;
  final int createdAt;
  final int updatedAt;

  const Budget({
    required this.id,
    required this.name,
    this.accountId,
    required this.limitAmount,
    required this.startDate,
    required this.endDate,
    this.isArchived = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Whether this budget tracks all accounts
  bool get tracksAllAccounts => accountId == null;

  /// Whether this budget period has expired
  bool get isExpired => DateTime.now().millisecondsSinceEpoch > endDate;

  /// Whether this budget is currently active (not expired, not archived)
  bool get isActive {
    final now = DateTime.now().millisecondsSinceEpoch;
    return startDate <= now && endDate >= now && !isArchived;
  }

  /// Convert Budget to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'account_id': accountId,
      'limit_amount': limitAmount,
      'start_date': startDate,
      'end_date': endDate,
      'is_archived': isArchived ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  /// Create Budget from Map (database retrieval)
  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'] as String,
      name: map['name'] as String,
      accountId: map['account_id'] as String?,
      limitAmount: (map['limit_amount'] as num).toDouble(),
      startDate: map['start_date'] as int,
      endDate: map['end_date'] as int,
      isArchived: (map['is_archived'] as int?) == 1,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
    );
  }

  /// Create a copy of Budget with updated fields
  /// Use [clearAccountId] = true to explicitly set accountId to null
  Budget copyWith({
    String? id,
    String? name,
    String? accountId,
    bool clearAccountId = false,
    double? limitAmount,
    int? startDate,
    int? endDate,
    bool? isArchived,
    int? createdAt,
    int? updatedAt,
  }) {
    return Budget(
      id: id ?? this.id,
      name: name ?? this.name,
      accountId: clearAccountId ? null : (accountId ?? this.accountId),
      limitAmount: limitAmount ?? this.limitAmount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Budget(id: $id, name: $name, limitAmount: $limitAmount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Budget && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
