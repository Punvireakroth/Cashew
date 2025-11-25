import 'package:flutter/foundation.dart';

@immutable
class Category {
  final String id;
  final String name;
  final String iconName;
  final int color;
  final String type; // 'income' or 'expense'
  final int createdAt;

  const Category({
    required this.id,
    required this.name,
    required this.iconName,
    required this.color,
    required this.type,
    required this.createdAt,
  }) : assert(
         type == 'income' || type == 'expense',
         'Category type must be either "income" or "expense"',
       );

  /// Convert Category to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon_name': iconName,
      'color': color,
      'type': type,
      'created_at': createdAt,
    };
  }

  /// Create Category from Map (database retrieval)
  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as String,
      name: map['name'] as String,
      iconName: map['icon_name'] as String,
      color: map['color'] as int,
      type: map['type'] as String,
      createdAt: map['created_at'] as int,
    );
  }

  /// Create a copy of Category with updated fields
  Category copyWith({
    String? id,
    String? name,
    String? iconName,
    int? color,
    String? type,
    int? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      iconName: iconName ?? this.iconName,
      color: color ?? this.color,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';

  @override
  String toString() {
    return 'Category(id: $id, name: $name, type: $type, iconName: $iconName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Category && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
