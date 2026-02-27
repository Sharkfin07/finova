import 'package:hive_flutter/hive_flutter.dart';
import '../../features/transactions/data/transaction_model.dart';
import '../../features/wallets/data/wallet_model.dart';

class HiveService {
  static const String transactionsBox = 'transactions';
  static const String walletsBox = 'wallets';

  /// Initialize Hive and register adapters
  static Future<void> init() async {
    await Hive.initFlutter();

    // Register adapters
    Hive.registerAdapter(TransactionModelAdapter());
    Hive.registerAdapter(WalletModelAdapter());

    // Open boxes
    await Hive.openBox<TransactionModel>(transactionsBox);
    await Hive.openBox<WalletModel>(walletsBox);
  }

  /// Get transactions box
  static Box<TransactionModel> get transactionBox =>
      Hive.box<TransactionModel>(transactionsBox);

  /// Get wallets box
  static Box<WalletModel> get walletBox => Hive.box<WalletModel>(walletsBox);

  /// Close all boxes
  static Future<void> close() async {
    await Hive.close();
  }
}
