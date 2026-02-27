import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/categories.dart';
import '../../../core/constants.dart';
import '../../auth/providers/auth_providers.dart';
import '../../transactions/providers/transaction_providers.dart';
import '../../transactions/data/transaction_model.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _period = 'month'; // week | month | year

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) return const SizedBox.shrink();

    final txState = ref.watch(transactionNotifierProvider(user.uid));
    final transactions = txState.transactions;

    // Filter by period
    final now = DateTime.now();
    final filtered = _filterByPeriod(transactions, now);

    final totalIncome = filtered
        .where((t) => t.type == 'income')
        .fold(0.0, (s, t) => s + t.amount);
    final totalExpense = filtered
        .where((t) => t.type == 'expense')
        .fold(0.0, (s, t) => s + t.amount);

    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Categories'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Period selector
          _PeriodSelector(
            selected: _period,
            onChanged: (val) => setState(() => _period = val),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // ── Overview Tab ──
                _OverviewTab(
                  filtered: filtered,
                  totalIncome: totalIncome,
                  totalExpense: totalExpense,
                  currencyFormat: currencyFormat,
                ),
                // ── Categories Tab ──
                _CategoriesTab(
                  filtered: filtered,
                  currencyFormat: currencyFormat,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<TransactionModel> _filterByPeriod(
    List<TransactionModel> transactions,
    DateTime now,
  ) {
    DateTime start;
    switch (_period) {
      case 'week':
        start = now.subtract(Duration(days: now.weekday - 1));
        break;
      case 'year':
        start = DateTime(now.year, 1, 1);
        break;
      case 'month':
      default:
        start = DateTime(now.year, now.month, 1);
    }
    final startDate = DateTime(start.year, start.month, start.day);
    return transactions.where((t) => !t.date.isBefore(startDate)).toList();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Period Selector
// ─────────────────────────────────────────────────────────────────────────────

class _PeriodSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _PeriodSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: ['week', 'month', 'year'].map((period) {
          final isActive = selected == period;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(period[0].toUpperCase() + period.substring(1)),
              selected: isActive,
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isActive ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              onSelected: (_) => onChanged(period),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Overview Tab
// ─────────────────────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final List<TransactionModel> filtered;
  final double totalIncome;
  final double totalExpense;
  final NumberFormat currencyFormat;

  const _OverviewTab({
    required this.filtered,
    required this.totalIncome,
    required this.totalExpense,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Income / Expense summary cards
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: 'Income',
                amount: currencyFormat.format(totalIncome),
                color: AppColors.income,
                icon: Icons.arrow_downward,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                label: 'Expenses',
                amount: currencyFormat.format(totalExpense),
                color: AppColors.expense,
                icon: Icons.arrow_upward,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Bar chart – daily spending
        const Text(
          'Spending Trend',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(height: 220, child: _SpendingBarChart(transactions: filtered)),
        const SizedBox(height: 24),

        // Balance line
        const Text(
          'Balance Over Time',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(height: 200, child: _BalanceLineChart(transactions: filtered)),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Spending Bar Chart
// ─────────────────────────────────────────────────────────────────────────────

class _SpendingBarChart extends StatelessWidget {
  final List<TransactionModel> transactions;

  const _SpendingBarChart({required this.transactions});

  @override
  Widget build(BuildContext context) {
    // Group expenses by day of week (0=Mon … 6=Sun)
    final dailyTotals = List.filled(7, 0.0);
    for (final t in transactions.where((t) => t.type == 'expense')) {
      final dayIndex = (t.date.weekday - 1).clamp(0, 6);
      dailyTotals[dayIndex] += t.amount;
    }

    final maxY = dailyTotals
        .reduce((a, b) => a > b ? a : b)
        .clamp(1.0, double.infinity);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY * 1.2,
          barTouchData: BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  const days = [
                    'Mon',
                    'Tue',
                    'Wed',
                    'Thu',
                    'Fri',
                    'Sat',
                    'Sun',
                  ];
                  final idx = value.toInt();
                  if (idx >= 0 && idx < days.length) {
                    return Text(
                      days[idx],
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(7, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: dailyTotals[i],
                  color: AppColors.primary,
                  width: 20,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Balance Line Chart
// ─────────────────────────────────────────────────────────────────────────────

class _BalanceLineChart extends StatelessWidget {
  final List<TransactionModel> transactions;

  const _BalanceLineChart({required this.transactions});

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return const Center(
        child: Text(
          'No data',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    // Running balance over time
    final sorted = [...transactions]..sort((a, b) => a.date.compareTo(b.date));
    double running = 0;
    final spots = <FlSpot>[];
    for (int i = 0; i < sorted.length; i++) {
      final t = sorted[i];
      running += t.type == 'income' ? t.amount : -t.amount;
      spots.add(FlSpot(i.toDouble(), running));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: AppColors.border, strokeWidth: 1),
          ),
          titlesData: const FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.primary,
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.primary.withOpacity(0.08),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Categories Tab
// ─────────────────────────────────────────────────────────────────────────────

class _CategoriesTab extends StatelessWidget {
  final List<TransactionModel> filtered;
  final NumberFormat currencyFormat;

  const _CategoriesTab({required this.filtered, required this.currencyFormat});

  @override
  Widget build(BuildContext context) {
    final expenses = filtered.where((t) => t.type == 'expense').toList();
    final categoryTotals = <String, double>{};
    for (final t in expenses) {
      categoryTotals[t.category] = (categoryTotals[t.category] ?? 0) + t.amount;
    }

    if (categoryTotals.isEmpty) {
      return const Center(
        child: Text(
          'No expenses in this period',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
        ),
      );
    }

    final total = categoryTotals.values.fold(0.0, (a, b) => a + b);
    final sortedEntries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Pie chart sections
    final sections = sortedEntries.map((entry) {
      final cat = AppCategories.getByName(entry.key);
      final color = cat?.color ?? AppColors.textSecondary;
      final pct = total > 0 ? (entry.value / total * 100) : 0;
      return PieChartSectionData(
        value: entry.value,
        color: color,
        radius: 50,
        title: '${pct.toStringAsFixed(0)}%',
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Pie chart
        SizedBox(
          height: 220,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 40,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Category breakdown list
        ...sortedEntries.map((entry) {
          final cat = AppCategories.getByName(entry.key);
          final pct = total > 0 ? (entry.value / total * 100) : 0;
          return _CategoryRow(
            name: entry.key,
            icon: cat?.icon ?? Icons.category,
            color: cat?.color ?? AppColors.textSecondary,
            amount: currencyFormat.format(entry.value),
            percentage: pct.toDouble(),
          );
        }),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final String name;
  final IconData icon;
  final Color color;
  final String amount;
  final double percentage;

  const _CategoryRow({
    required this.name,
    required this.icon,
    required this.color,
    required this.amount,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: AppColors.border,
                    color: color,
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
