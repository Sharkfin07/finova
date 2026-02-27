import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

import 'wallet_model.dart';

class WalletRepository {
  final FirebaseFirestore _firestore;
  final Box<WalletModel> _localBox;

  WalletRepository({FirebaseFirestore? firestore, Box<WalletModel>? localBox})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _localBox = localBox ?? Hive.box<WalletModel>('wallets');

  // ---------------------------------------------------------------------------
  // Firestore helpers
  // ---------------------------------------------------------------------------

  CollectionReference<Map<String, dynamic>> _userWallets(String userId) {
    return _firestore.collection('users').doc(userId).collection('wallets');
  }

  // ---------------------------------------------------------------------------
  // CREATE
  // ---------------------------------------------------------------------------

  Future<WalletModel> addWallet(WalletModel wallet) async {
    try {
      await _userWallets(wallet.userId).doc(wallet.id).set(wallet.toMap());
      await _localBox.put(wallet.id, wallet);
      return wallet;
    } catch (e) {
      await _localBox.put(wallet.id, wallet);
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // READ
  // ---------------------------------------------------------------------------

  Future<List<WalletModel>> getWallets(String userId) async {
    try {
      final snapshot = await _userWallets(
        userId,
      ).get().timeout(const Duration(seconds: 10));

      final wallets = snapshot.docs
          .map((doc) => WalletModel.fromMap(doc.data()))
          .toList();

      // Sync to local cache
      for (final w in wallets) {
        await _localBox.put(w.id, w);
      }

      return wallets;
    } catch (e) {
      // Fallback to local cache
      return _getLocalWallets(userId);
    }
  }

  Future<WalletModel?> getWalletById(String userId, String walletId) async {
    try {
      final doc = await _userWallets(userId).doc(walletId).get();
      if (!doc.exists) return null;

      final wallet = WalletModel.fromMap(doc.data()!);
      await _localBox.put(wallet.id, wallet);
      return wallet;
    } catch (e) {
      return _localBox.get(walletId);
    }
  }

  // ---------------------------------------------------------------------------
  // UPDATE
  // ---------------------------------------------------------------------------

  Future<void> updateWallet(WalletModel wallet) async {
    try {
      await _userWallets(wallet.userId).doc(wallet.id).update(wallet.toMap());
      await _localBox.put(wallet.id, wallet);
    } catch (e) {
      await _localBox.put(wallet.id, wallet);
      rethrow;
    }
  }

  /// Update wallet balance after a transaction.
  Future<void> updateBalance(
    String userId,
    String walletId,
    double delta,
  ) async {
    final wallet = await getWalletById(userId, walletId);
    if (wallet == null) return;

    final updated = wallet.copyWith(balance: wallet.balance + delta);
    await updateWallet(updated);
  }

  // ---------------------------------------------------------------------------
  // DELETE
  // ---------------------------------------------------------------------------

  Future<void> deleteWallet(String userId, String walletId) async {
    try {
      await _userWallets(userId).doc(walletId).delete();
      await _localBox.delete(walletId);
    } catch (e) {
      await _localBox.delete(walletId);
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // LOCAL helpers
  // ---------------------------------------------------------------------------

  List<WalletModel> _getLocalWallets(String userId) {
    return _localBox.values.where((w) => w.userId == userId).toList();
  }

  /// Quick synchronous access for UI display.
  List<WalletModel> getCachedWallets(String userId) {
    return _getLocalWallets(userId);
  }

  // ---------------------------------------------------------------------------
  // AGGREGATIONS
  // ---------------------------------------------------------------------------

  double getTotalBalance(List<WalletModel> wallets) {
    return wallets.fold(0.0, (sum, w) => sum + w.balance);
  }
}
