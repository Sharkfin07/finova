import 'package:hive/hive.dart';

part 'transaction_model.g.dart';

@HiveType(typeId: 0)
class TransactionModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final String type; // 'income' or 'expense'

  @HiveField(4)
  final String category;

  @HiveField(5)
  final String title;

  @HiveField(6)
  final String walletId;

  @HiveField(7)
  final DateTime date;

  @HiveField(8)
  final String? notes;

  @HiveField(9)
  final String? tags;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.category,
    required this.title,
    required this.walletId,
    required this.date,
    this.notes,
    this.tags,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'type': type,
      'category': category,
      'title': title,
      'walletId': walletId,
      'date': date.toIso8601String(),
      'notes': notes,
      'tags': tags,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: map['type'] as String,
      category: map['category'] as String,
      title: map['title'] as String,
      walletId: map['walletId'] as String,
      date: DateTime.parse(map['date'] as String),
      notes: map['notes'] as String?,
      tags: map['tags'] as String?,
    );
  }

  TransactionModel copyWith({
    String? id,
    String? userId,
    double? amount,
    String? type,
    String? category,
    String? title,
    String? walletId,
    DateTime? date,
    String? notes,
    String? tags,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      title: title ?? this.title,
      walletId: walletId ?? this.walletId,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
    );
  }
}
