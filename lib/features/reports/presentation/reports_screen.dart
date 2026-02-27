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

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String _period = 'Monthly'; // Weekly | Monthly | Yearly

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) return const SizedBox.shrink();

    final txState = ref.watch(transactionNotifierProvider(user.uid));
    final transactions = txState.transactions;

    final now = DateTime.now();
    final filtered = _filterByPeriod(transactions, now, _period);
    final previousFiltered = _filterByPreviousPeriod(
      transactions,
      now,
      _period,
    );

    final totalIncome = filtered
        .where((t) => t.type == 'income')
        .fold(0.0, (s, t) => s + t.amount);
    final totalExpense = filtered
        .where((t) => t.type == 'expense')
        .fold(0.0, (s, t) => s + t.amount);
    final netSavings = totalIncome - totalExpense;

    final prevIncome = previousFiltered
        .where((t) => t.type == 'income')
        .fold(0.0, (s, t) => s + t.amount);
    final prevExpense = previousFiltered
        .where((t) => t.type == 'expense')
        .fold(0.0, (s, t) => s + t.amount);

    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    // Financial health
    final savingsRate = totalIncome > 0 ? (netSavings / totalIncome * 100) : 0;
    final prevSavingsRate = prevIncome > 0
        ? ((prevIncome - prevExpense) / prevIncome * 100)
        : 0;
    final savingsImprovement = savingsRate - prevSavingsRate;

    String healthLabel;
    Color healthColor;
    if (savingsRate >= 20) {
      healthLabel = 'Excellent';
      healthColor = AppColors.income;
    } else if (savingsRate >= 10) {
      healthLabel = 'Good';
      healthColor = AppColors.savings;
    } else if (savingsRate >= 0) {
      healthLabel = 'Fair';
      healthColor = Colors.orange;
    } else {
      healthLabel = 'Poor';
      healthColor = AppColors.expense;
    }

    // Period comparison percentages
    final incomeChange = prevIncome > 0
        ? ((totalIncome - prevIncome) / prevIncome * 100)
        : 0.0;
    final expenseChange = prevExpense > 0
        ? ((totalExpense - prevExpense) / prevExpense * 100)
        : 0.0;

    final periodLabel = _period == 'Weekly'
        ? 'vs last week'
        : _period == 'Yearly'
        ? 'vs last year'
        : 'vs last month';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Financial Report'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.more_horiz), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Period Selector ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: ['Weekly', 'Monthly', 'Yearly'].map((period) {
                    final isActive = _period == period;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _period = period),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.darkNavy
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            period,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isActive
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: isActive
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Executive Summary ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(20),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Executive Summary',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _period == 'Weekly'
                                ? 'This Week'
                                : _period == 'Yearly'
                                ? 'This Year'
                                : 'This Month',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Total Income
                    _SummaryRow(
                      label: 'Total Income',
                      amount: currencyFormat.format(totalIncome),
                      color: AppColors.income,
                      icon: Icons.trending_up,
                    ),
                    const SizedBox(height: 16),

                    // Total Expenses
                    _SummaryRow(
                      label: 'Total Expenses',
                      amount: currencyFormat.format(totalExpense),
                      color: AppColors.expense,
                      icon: Icons.trending_down,
                    ),
                    const SizedBox(height: 16),

                    // Net Savings
                    _SummaryRow(
                      label: 'Net Savings',
                      amount: currencyFormat.format(netSavings.abs()),
                      color: AppColors.savings,
                      icon: Icons.account_balance,
                    ),
                    const SizedBox(height: 20),

                    // Financial Health
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(fontSize: 14),
                            children: [
                              const TextSpan(
                                text: 'Financial Health: ',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              TextSpan(
                                text: healthLabel,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: healthColor,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          savingsImprovement >= 0
                              ? "You've saved ${savingsImprovement.toStringAsFixed(0)}% more than the previous period. Keep up the great work!"
                              : "Your savings decreased by ${savingsImprovement.abs().toStringAsFixed(0)}% compared to the previous period.",
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Income vs Expense Trend ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(20),
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
                    const Text(
                      'Income vs Expense Trend',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 200,
                      child: _IncomeExpenseLineChart(
                        transactions: filtered,
                        period: _period,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Expense Breakdown ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(20),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Expense Breakdown',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'View All',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.savings,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _ExpenseBreakdownChart(
                      filtered: filtered,
                      currencyFormat: currencyFormat,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Period Comparison ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Period Comparison',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Income comparison card
                  _ComparisonCard(
                    label: 'Income',
                    amount: currencyFormat.format(totalIncome),
                    changePercent: incomeChange,
                    periodLabel: periodLabel,
                  ),
                  const SizedBox(height: 12),

                  // Expense comparison card
                  _ComparisonCard(
                    label: 'Expenses',
                    amount: currencyFormat.format(totalExpense),
                    changePercent: expenseChange,
                    periodLabel: periodLabel,
                    invertColor: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  List<TransactionModel> _filterByPeriod(
    List<TransactionModel> transactions,
    DateTime now,
    String period,
  ) {
    DateTime start;
    switch (period) {
      case 'Weekly':
        start = now.subtract(Duration(days: now.weekday - 1));
        break;
      case 'Yearly':
        start = DateTime(now.year, 1, 1);
        break;
      case 'Monthly':
      default:
        start = DateTime(now.year, now.month, 1);
    }
    final startDate = DateTime(start.year, start.month, start.day);
    return transactions.where((t) => !t.date.isBefore(startDate)).toList();
  }

  List<TransactionModel> _filterByPreviousPeriod(
    List<TransactionModel> transactions,
    DateTime now,
    String period,
  ) {
    DateTime start;
    DateTime end;
    switch (period) {
      case 'Weekly':
        end = now.subtract(Duration(days: now.weekday));
        start = end.subtract(const Duration(days: 6));
        break;
      case 'Yearly':
        start = DateTime(now.year - 1, 1, 1);
        end = DateTime(now.year - 1, 12, 31);
        break;
      case 'Monthly':
      default:
        final prevMonth = DateTime(now.year, now.month - 1, 1);
        start = prevMonth;
        end = DateTime(now.year, now.month, 0);
    }
    final startDate = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day, 23, 59, 59);
    return transactions
        .where((t) => !t.date.isBefore(startDate) && !t.date.isAfter(endDate))
        .toList();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Executive Summary Row
// ─────────────────────────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;
  final IconData icon;

  const _SummaryRow({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  amount,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Icon(icon, color: color.withOpacity(0.5), size: 30),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Income vs Expense Line Chart
// ─────────────────────────────────────────────────────────────────────────────

class _IncomeExpenseLineChart extends StatelessWidget {
  final List<TransactionModel> transactions;
  final String period;

  const _IncomeExpenseLineChart({
    required this.transactions,
    required this.period,
  });

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

    // Group by month labels for monthly/yearly, or by day for weekly
    final Map<int, double> incomeByGroup = {};
    final Map<int, double> expenseByGroup = {};
    List<String> labels;

    if (period == 'Weekly') {
      labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      for (final t in transactions) {
        final idx = (t.date.weekday - 1).clamp(0, 6);
        if (t.type == 'income') {
          incomeByGroup[idx] = (incomeByGroup[idx] ?? 0) + t.amount;
        } else {
          expenseByGroup[idx] = (expenseByGroup[idx] ?? 0) + t.amount;
        }
      }
    } else if (period == 'Yearly') {
      labels = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      for (final t in transactions) {
        final idx = t.date.month - 1;
        if (t.type == 'income') {
          incomeByGroup[idx] = (incomeByGroup[idx] ?? 0) + t.amount;
        } else {
          expenseByGroup[idx] = (expenseByGroup[idx] ?? 0) + t.amount;
        }
      }
    } else {
      // Monthly - group by week of month
      labels = ['Week 1', 'Week 2', 'Week 3', 'Week 4', 'Week 5'];
      for (final t in transactions) {
        final weekIdx = ((t.date.day - 1) / 7).floor().clamp(0, 4);
        if (t.type == 'income') {
          incomeByGroup[weekIdx] = (incomeByGroup[weekIdx] ?? 0) + t.amount;
        } else {
          expenseByGroup[weekIdx] = (expenseByGroup[weekIdx] ?? 0) + t.amount;
        }
      }
    }

    final count = labels.length;
    final incomeSpots = List.generate(
      count,
      (i) => FlSpot(i.toDouble(), incomeByGroup[i] ?? 0),
    );
    final expenseSpots = List.generate(
      count,
      (i) => FlSpot(i.toDouble(), expenseByGroup[i] ?? 0),
    );

    final allValues = [
      ...incomeSpots.map((s) => s.y),
      ...expenseSpots.map((s) => s.y),
    ];
    final maxY = allValues.isEmpty
        ? 100.0
        : allValues.reduce((a, b) => a > b ? a : b) * 1.2;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY > 0 ? maxY / 4 : 25,
          getDrawingHorizontalLine: (_) => FlLine(
            color: AppColors.border.withOpacity(0.5),
            strokeWidth: 0.8,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (value, _) {
                if (value == 0) return const SizedBox.shrink();
                String text;
                if (value >= 1000000) {
                  text = '\$${(value / 1000000).toStringAsFixed(1)}M';
                } else if (value >= 1000) {
                  text = '\$${(value / 1000).toStringAsFixed(1)}k';
                } else {
                  text = '\$${value.toStringAsFixed(0)}';
                }
                return Text(
                  text,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                );
              },
            ),
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
              interval: 1,
              getTitlesWidget: (value, _) {
                final idx = value.toInt();
                if (idx >= 0 && idx < labels.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      labels[idx],
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minY: 0,
        maxY: maxY,
        lineBarsData: [
          // Income line (green)
          LineChartBarData(
            spots: incomeSpots,
            isCurved: true,
            color: AppColors.income,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.income.withOpacity(0.06),
            ),
          ),
          // Expense line (red)
          LineChartBarData(
            spots: expenseSpots,
            isCurved: true,
            color: AppColors.expense,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.expense.withOpacity(0.06),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Expense Breakdown (Donut Chart + Legend)
// ─────────────────────────────────────────────────────────────────────────────

class _ExpenseBreakdownChart extends StatelessWidget {
  final List<TransactionModel> filtered;
  final NumberFormat currencyFormat;

  const _ExpenseBreakdownChart({
    required this.filtered,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    final expenses = filtered.where((t) => t.type == 'expense').toList();
    final categoryTotals = <String, double>{};
    for (final t in expenses) {
      categoryTotals[t.category] = (categoryTotals[t.category] ?? 0) + t.amount;
    }

    if (categoryTotals.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            'No expenses in this period',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ),
      );
    }

    final sortedEntries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final sections = sortedEntries.map((entry) {
      final cat = AppCategories.getByName(entry.key);
      final color = cat?.color ?? AppColors.textSecondary;
      return PieChartSectionData(
        value: entry.value,
        color: color,
        radius: 28,
        title: '',
        showTitle: false,
      );
    }).toList();

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 50,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Legend grid
        Wrap(
          spacing: 16,
          runSpacing: 10,
          children: sortedEntries.map((entry) {
            final cat = AppCategories.getByName(entry.key);
            final color = cat?.color ?? AppColors.textSecondary;
            return SizedBox(
              width: (MediaQuery.of(context).size.width - 80) / 2,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '${entry.key} ${currencyFormat.format(entry.value)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Period Comparison Card
// ─────────────────────────────────────────────────────────────────────────────

class _ComparisonCard extends StatelessWidget {
  final String label;
  final String amount;
  final double changePercent;
  final String periodLabel;
  final bool invertColor;

  const _ComparisonCard({
    required this.label,
    required this.amount,
    required this.changePercent,
    required this.periodLabel,
    this.invertColor = false,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = changePercent >= 0;
    final Color badgeColor;
    if (invertColor) {
      badgeColor = isPositive ? AppColors.expense : AppColors.income;
    } else {
      badgeColor = isPositive ? AppColors.income : AppColors.expense;
    }

    final sign = isPositive ? '+' : '';
    final arrow = isPositive ? '↑' : '↓';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Left side: label + amount
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  amount,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          // Right side: change badge
          if (changePercent != 0)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(arrow, style: TextStyle(fontSize: 13, color: badgeColor)),
                const SizedBox(width: 4),
                Text(
                  '$sign${changePercent.toStringAsFixed(0)}% $periodLabel',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: badgeColor,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
