import 'package:flutter/foundation.dart';

@immutable
class Budget {
  final String id;
  final String name;
  final double limitAmount;
  final int startDate;
  final int endDate;
  final int createdAt;
  final int updatedAt;

  const Budget({
    required this.id,
    required this.name,
    required this.limitAmount,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Convert Budget to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'limit_amount': limitAmount,
      'start_date': startDate,
      'end_date': endDate,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  /// Create Budget from Map (database retrieval)
  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'] as String,
      name: map['name'] as String,
      limitAmount: (map['limit_amount'] as num).toDouble(),
      startDate: map['start_date'] as int,
      endDate: map['end_date'] as int,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
    );
  }

  /// Create a copy of Budget with updated fields
  Budget copyWith({
    String? id,
    String? name,
    double? limitAmount,
    int? startDate,
    int? endDate,
    int? createdAt,
    int? updatedAt,
  }) {
    return Budget(
      id: id ?? this.id,
      name: name ?? this.name,
      limitAmount: limitAmount ?? this.limitAmount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
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
