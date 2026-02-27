import 'package:flutter/material.dart';

class TransactionCategory {
  final String name;
  final IconData icon;
  final Color color;

  const TransactionCategory({
    required this.name,
    required this.icon,
    required this.color,
  });
}

class AppCategories {
  // Expense categories
  static const List<TransactionCategory> expense = [
    TransactionCategory(
      name: 'Groceries',
      icon: Icons.shopping_cart,
      color: Color(0xFF27AE60),
    ),
    TransactionCategory(
      name: 'Housing',
      icon: Icons.home,
      color: Color(0xFF3498DB),
    ),
    TransactionCategory(
      name: 'Transport',
      icon: Icons.directions_car,
      color: Color(0xFFF39C12),
    ),
    TransactionCategory(
      name: 'Entertainment',
      icon: Icons.music_note,
      color: Color(0xFF9B59B6),
    ),
    TransactionCategory(
      name: 'Utilities',
      icon: Icons.flash_on,
      color: Color(0xFF1ABC9C),
    ),
    TransactionCategory(
      name: 'Netflix',
      icon: Icons.subscriptions,
      color: Color(0xFFE74C3C),
    ),
    TransactionCategory(
      name: 'Other',
      icon: Icons.more_horiz,
      color: Color(0xFF7F8C8D),
    ),
  ];

  // Income categories
  static const List<TransactionCategory> income = [
    TransactionCategory(
      name: 'Salary',
      icon: Icons.attach_money,
      color: Color(0xFF27AE60),
    ),
    TransactionCategory(
      name: 'Freelance',
      icon: Icons.work,
      color: Color(0xFF3498DB),
    ),
    TransactionCategory(
      name: 'Investment',
      icon: Icons.trending_up,
      color: Color(0xFFF39C12),
    ),
    TransactionCategory(
      name: 'Other',
      icon: Icons.more_horiz,
      color: Color(0xFF7F8C8D),
    ),
  ];

  /// Get category by name (searches both income and expense)
  static TransactionCategory? getByName(String name) {
    for (final cat in [...expense, ...income]) {
      if (cat.name.toLowerCase() == name.toLowerCase()) return cat;
    }
    return null;
  }
}
