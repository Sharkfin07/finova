import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/categories.dart';
import '../../../core/constants.dart';
import '../../auth/providers/auth_providers.dart';
import '../../wallets/providers/wallet_providers.dart';
import '../providers/transaction_providers.dart';
import '../data/transaction_model.dart';

class TransactionFormScreen extends ConsumerStatefulWidget {
  /// Pass an existing transaction for editing; null for new.
  final TransactionModel? transaction;

  const TransactionFormScreen({super.key, this.transaction});

  @override
  ConsumerState<TransactionFormScreen> createState() =>
      _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  String _type = 'expense';
  String? _category;
  String? _walletId;
  DateTime _date = DateTime.now();

  bool get _isEditing => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final tx = widget.transaction!;
      _titleController.text = tx.title;
      _amountController.text = tx.amount.toStringAsFixed(0);
      _notesController.text = tx.notes ?? '';
      _type = tx.type;
      _category = tx.category;
      _walletId = tx.walletId;
      _date = tx.date;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  List<TransactionCategory> get _categories =>
      _type == 'expense' ? AppCategories.expense : AppCategories.income;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_category == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }
    if (_walletId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a wallet')));
      return;
    }

    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    final notifier = ref.read(transactionNotifierProvider(user.uid).notifier);

    final amount = double.parse(_amountController.text.replaceAll(',', ''));

    bool success;
    if (_isEditing) {
      final updated = widget.transaction!.copyWith(
        title: _titleController.text.trim(),
        amount: amount,
        type: _type,
        category: _category!,
        walletId: _walletId!,
        date: _date,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );
      success = await notifier.updateTransaction(updated);
    } else {
      success = await notifier.addTransaction(
        title: _titleController.text.trim(),
        amount: amount,
        type: _type,
        category: _category!,
        walletId: _walletId!,
        date: _date,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );
    }

    if (success && mounted) {
      context.pop();
    }
  }

  Future<void> _delete() async {
    if (!_isEditing) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text(
          'Are you sure you want to delete this transaction?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.expense),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    final success = await ref
        .read(transactionNotifierProvider(user.uid).notifier)
        .deleteTransaction(widget.transaction!.id);

    if (success && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final walletState = user != null
        ? ref.watch(walletNotifierProvider(user.uid))
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Transaction' : 'Add Transaction'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.expense),
              onPressed: _delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Type Toggle ──
            _TypeToggle(
              value: _type,
              onChanged: (val) => setState(() {
                _type = val;
                _category = null; // reset category on type change
              }),
            ),
            const SizedBox(height: 24),

            // ── Amount ──
            _buildLabel('Amount'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                prefixText: 'Rp  ',
                prefixStyle: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary.withOpacity(0.5),
                ),
                hintText: '0',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
              ),
              validator: (val) {
                if (val == null || val.isEmpty) return 'Enter an amount';
                if (double.tryParse(val) == null || double.parse(val) <= 0) {
                  return 'Enter a valid amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // ── Title ──
            _buildLabel('Title'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _titleController,
              hint: 'e.g. Grocery shopping',
              validator: (val) =>
                  val == null || val.trim().isEmpty ? 'Enter a title' : null,
            ),
            const SizedBox(height: 20),

            // ── Category ──
            _buildLabel('Category'),
            const SizedBox(height: 12),
            _CategoryGrid(
              categories: _categories,
              selected: _category,
              onSelected: (name) => setState(() => _category = name),
            ),
            const SizedBox(height: 20),

            // ── Wallet ──
            _buildLabel('Wallet'),
            const SizedBox(height: 8),
            if (walletState != null && walletState.wallets.isNotEmpty)
              DropdownButtonFormField<String>(
                value: _walletId,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
                hint: const Text('Select wallet'),
                items: walletState.wallets
                    .map(
                      (w) => DropdownMenuItem(value: w.id, child: Text(w.name)),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _walletId = val),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Text(
                  'No wallets yet. Create one first.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            const SizedBox(height: 20),

            // ── Date ──
            _buildLabel('Date'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat('dd MMMM yyyy').format(_date),
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Notes ──
            _buildLabel('Notes (optional)'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _notesController,
              hint: 'Add a note…',
              maxLines: 3,
            ),
            const SizedBox(height: 32),

            // ── Save Button ──
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  _isEditing ? 'Update Transaction' : 'Add Transaction',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Type Toggle
// ─────────────────────────────────────────────────────────────────────────────

class _TypeToggle extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _TypeToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _buildOption('expense', 'Expense', AppColors.expense),
          _buildOption('income', 'Income', AppColors.income),
        ],
      ),
    );
  }

  Widget _buildOption(String type, String label, Color color) {
    final selected = value == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category Grid
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryGrid extends StatelessWidget {
  final List<TransactionCategory> categories;
  final String? selected;
  final ValueChanged<String> onSelected;

  const _CategoryGrid({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: categories.map((cat) {
        final isSelected = selected == cat.name;
        return GestureDetector(
          onTap: () => onSelected(cat.name),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? cat.color : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? cat.color : AppColors.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  cat.icon,
                  size: 18,
                  color: isSelected ? Colors.white : cat.color,
                ),
                const SizedBox(width: 6),
                Text(
                  cat.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
