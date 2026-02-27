import 'package:hive/hive.dart';

part 'wallet_model.g.dart';

@HiveType(typeId: 1)
class WalletModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String name;

  @HiveField(3)
  final double balance;

  @HiveField(4)
  final String icon; // icon name string

  @HiveField(5)
  final String color; // hex color string

  @HiveField(6)
  final String? accountNumber; // last 4 digits e.g. "1234"

  WalletModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.balance,
    this.icon = 'account_balance',
    this.color = '0xFF2ECC71',
    this.accountNumber,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'balance': balance,
      'icon': icon,
      'color': color,
      'accountNumber': accountNumber,
    };
  }

  factory WalletModel.fromMap(Map<String, dynamic> map) {
    return WalletModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      name: map['name'] as String,
      balance: (map['balance'] as num).toDouble(),
      icon: map['icon'] as String? ?? 'account_balance',
      color: map['color'] as String? ?? '0xFF2ECC71',
      accountNumber: map['accountNumber'] as String?,
    );
  }

  WalletModel copyWith({
    String? id,
    String? userId,
    String? name,
    double? balance,
    String? icon,
    String? color,
    String? accountNumber,
  }) {
    return WalletModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      accountNumber: accountNumber ?? this.accountNumber,
    );
  }
}
