import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

import 'transaction_model.dart';

class TransactionRepository {
  final FirebaseFirestore _firestore;
  final Box<TransactionModel> _localBox;

  TransactionRepository({
    FirebaseFirestore? firestore,
    Box<TransactionModel>? localBox,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _localBox = localBox ?? Hive.box<TransactionModel>('transactions');

  // ---------------------------------------------------------------------------
  // Firestore helpers
  // ---------------------------------------------------------------------------

  CollectionReference<Map<String, dynamic>> _userTransactions(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions');
  }

  // ---------------------------------------------------------------------------
  // CREATE
  // ---------------------------------------------------------------------------

  Future<TransactionModel> addTransaction(TransactionModel transaction) async {
    try {
      // Save to Firestore
      await _userTransactions(
        transaction.userId,
      ).doc(transaction.id).set(transaction.toMap());

      // Cache locally
      await _localBox.put(transaction.id, transaction);

      return transaction;
    } catch (e) {
      // If Firestore fails, still save locally for offline support
      await _localBox.put(transaction.id, transaction);
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // READ
  // ---------------------------------------------------------------------------

  Future<List<TransactionModel>> getTransactions(String userId) async {
    try {
      final snapshot = await _userTransactions(userId)
          .orderBy('date', descending: true)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 5));

      final transactions = snapshot.docs
          .map((doc) => TransactionModel.fromMap(doc.data()))
          .toList();

      // Sync to local cache
      for (final t in transactions) {
        await _localBox.put(t.id, t);
      }

      return transactions;
    } catch (e) {
      // Fallback to local cache if offline
      return _getLocalTransactions(userId);
    }
  }

  Future<List<TransactionModel>> getTransactionsByDateRange(
    String userId, {
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final snapshot = await _userTransactions(userId)
          .where('date', isGreaterThanOrEqualTo: start.toIso8601String())
          .where('date', isLessThanOrEqualTo: end.toIso8601String())
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => TransactionModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      // Fallback: filter local cache
      return _getLocalTransactions(userId).where((t) {
        return t.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
            t.date.isBefore(end.add(const Duration(seconds: 1)));
      }).toList();
    }
  }

  Future<List<TransactionModel>> getTransactionsByWallet(
    String userId,
    String walletId,
  ) async {
    try {
      final snapshot = await _userTransactions(userId)
          .where('walletId', isEqualTo: walletId)
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => TransactionModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      return _getLocalTransactions(
        userId,
      ).where((t) => t.walletId == walletId).toList();
    }
  }

  // ---------------------------------------------------------------------------
  // UPDATE
  // ---------------------------------------------------------------------------

  Future<void> updateTransaction(TransactionModel transaction) async {
    try {
      await _userTransactions(
        transaction.userId,
      ).doc(transaction.id).update(transaction.toMap());

      await _localBox.put(transaction.id, transaction);
    } catch (e) {
      await _localBox.put(transaction.id, transaction);
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // DELETE
  // ---------------------------------------------------------------------------

  Future<void> deleteTransaction(String userId, String transactionId) async {
    try {
      await _userTransactions(userId).doc(transactionId).delete();
      await _localBox.delete(transactionId);
    } catch (e) {
      await _localBox.delete(transactionId);
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // LOCAL helpers
  // ---------------------------------------------------------------------------

  List<TransactionModel> _getLocalTransactions(String userId) {
    return _localBox.values.where((t) => t.userId == userId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Get cached transactions (synchronous) for quick UI display.
  List<TransactionModel> getCachedTransactions(String userId) {
    return _getLocalTransactions(userId);
  }

  // ---------------------------------------------------------------------------
  // AGGREGATIONS
  // ---------------------------------------------------------------------------

  double getTotalByType(List<TransactionModel> transactions, String type) {
    return transactions
        .where((t) => t.type == type)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  Map<String, double> getSpendingByCategory(
    List<TransactionModel> transactions,
  ) {
    final map = <String, double>{};
    for (final t in transactions.where((t) => t.type == 'expense')) {
      map[t.category] = (map[t.category] ?? 0) + t.amount;
    }
    return map;
  }
}
