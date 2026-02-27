import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/wallet_model.dart';
import '../data/wallet_repository.dart';

const _uuid = Uuid();

/// Provider for WalletRepository
final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepository();
});

/// State for the wallet list
class WalletListState {
  final List<WalletModel> wallets;
  final bool isLoading;
  final String? error;

  const WalletListState({
    this.wallets = const [],
    this.isLoading = false,
    this.error,
  });

  WalletListState copyWith({
    List<WalletModel>? wallets,
    bool? isLoading,
    String? error,
  }) {
    return WalletListState(
      wallets: wallets ?? this.wallets,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  double get totalBalance => wallets.fold(0.0, (sum, w) => sum + w.balance);
}

/// StateNotifier for managing wallets
class WalletNotifier extends StateNotifier<WalletListState> {
  final WalletRepository _repo;
  final String _userId;

  WalletNotifier(this._repo, this._userId) : super(const WalletListState()) {
    Future.microtask(() => loadWallets());
  }

  /// Load all wallets for the current user.
  Future<void> loadWallets() async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final wallets = await _repo.getWallets(_userId);
      if (!mounted) return;
      state = state.copyWith(wallets: wallets, isLoading: false);
    } catch (e) {
      if (!mounted) return;
      final cached = _repo.getCachedWallets(_userId);
      state = state.copyWith(
        wallets: cached,
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Add a new wallet.
  Future<bool> addWallet({
    required String name,
    required double balance,
    String icon = 'wallet',
    String color = '#2ECC71',
    String? accountNumber,
  }) async {
    try {
      final wallet = WalletModel(
        id: _uuid.v4(),
        userId: _userId,
        name: name,
        balance: balance,
        icon: icon,
        color: color,
        accountNumber: accountNumber,
      );

      await _repo.addWallet(wallet);
      await loadWallets();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Update an existing wallet.
  Future<bool> updateWallet(WalletModel wallet) async {
    try {
      await _repo.updateWallet(wallet);
      await loadWallets();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Update wallet balance (used after transactions).
  Future<void> adjustBalance(String walletId, double delta) async {
    try {
      await _repo.updateBalance(_userId, walletId, delta);
      await loadWallets();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Delete a wallet.
  Future<bool> deleteWallet(String walletId) async {
    try {
      await _repo.deleteWallet(_userId, walletId);
      await loadWallets();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider family – creates a notifier scoped to a userId.
final walletNotifierProvider =
    StateNotifierProvider.family<WalletNotifier, WalletListState, String>((
      ref,
      userId,
    ) {
      final repo = ref.watch(walletRepositoryProvider);
      return WalletNotifier(repo, userId);
    });
