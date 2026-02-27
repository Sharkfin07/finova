import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/transaction_model.dart';
import '../data/transaction_repository.dart';

const _uuid = Uuid();

/// Provider for TransactionRepository
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository();
});

/// State for the transaction list
class TransactionListState {
  final List<TransactionModel> transactions;
  final bool isLoading;
  final String? error;

  const TransactionListState({
    this.transactions = const [],
    this.isLoading = false,
    this.error,
  });

  TransactionListState copyWith({
    List<TransactionModel>? transactions,
    bool? isLoading,
    String? error,
  }) {
    return TransactionListState(
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  double get totalIncome => transactions
      .where((t) => t.type == 'income')
      .fold(0.0, (sum, t) => sum + t.amount);

  double get totalExpense => transactions
      .where((t) => t.type == 'expense')
      .fold(0.0, (sum, t) => sum + t.amount);

  double get balance => totalIncome - totalExpense;
}

/// StateNotifier for managing transactions
class TransactionNotifier extends StateNotifier<TransactionListState> {
  final TransactionRepository _repo;
  final String _userId;

  TransactionNotifier(this._repo, this._userId)
    : super(const TransactionListState());

  /// Load all transactions for the current user.
  Future<void> loadTransactions() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final transactions = await _repo.getTransactions(_userId);
      state = state.copyWith(transactions: transactions, isLoading: false);
    } catch (e) {
      // Use cached data on failure
      final cached = _repo.getCachedTransactions(_userId);
      state = state.copyWith(
        transactions: cached,
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Add a new transaction.
  Future<bool> addTransaction({
    required double amount,
    required String type,
    required String category,
    required String title,
    required String walletId,
    DateTime? date,
    String? notes,
    String? tags,
  }) async {
    try {
      final transaction = TransactionModel(
        id: _uuid.v4(),
        userId: _userId,
        amount: amount,
        type: type,
        category: category,
        title: title,
        walletId: walletId,
        date: date ?? DateTime.now(),
        notes: notes,
        tags: tags,
      );

      await _repo.addTransaction(transaction);
      await loadTransactions();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Update an existing transaction.
  Future<bool> updateTransaction(TransactionModel transaction) async {
    try {
      await _repo.updateTransaction(transaction);
      await loadTransactions();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Delete a transaction.
  Future<bool> deleteTransaction(String transactionId) async {
    try {
      await _repo.deleteTransaction(_userId, transactionId);
      await loadTransactions();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Get transactions within a date range (for reports).
  Future<List<TransactionModel>> getByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      return await _repo.getTransactionsByDateRange(
        _userId,
        start: start,
        end: end,
      );
    } catch (e) {
      return [];
    }
  }

  /// Get spending grouped by category.
  Map<String, double> getSpendingByCategory() {
    return _repo.getSpendingByCategory(state.transactions);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider family – creates a notifier scoped to a userId.
final transactionNotifierProvider =
    StateNotifierProvider.family<
      TransactionNotifier,
      TransactionListState,
      String
    >((ref, userId) {
      final repo = ref.watch(transactionRepositoryProvider);
      return TransactionNotifier(repo, userId);
    });
