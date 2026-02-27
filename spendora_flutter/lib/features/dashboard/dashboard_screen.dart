import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/currency.dart';
import '../../widgets/custom_card.dart';
import '../ai/ai_assistant_widget.dart';
import '../ai/insight_widget.dart';
import '../expenses/expense_model.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({required this.expenses, super.key});

  final List<ExpenseModel> expenses;

  double get _income => expenses
      .where((ExpenseModel item) => item.type == ExpenseType.income)
      .fold(0, (double sum, ExpenseModel item) => sum + item.amount);

  double get _expense => expenses
      .where((ExpenseModel item) => item.type == ExpenseType.expense)
      .fold(0, (double sum, ExpenseModel item) => sum + item.amount);

  double get _balance => _income - _expense;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: <Widget>[
            SizedBox(
              width: MediaQuery.of(context).size.width / 2 - 22,
              child: CustomCard(
                title: 'Balance',
                value: formatInr(_balance),
                color: const Color(0xFF0C7A5B),
              ),
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width / 2 - 22,
              child: CustomCard(
                title: 'Income',
                value: formatInr(_income),
                color: const Color(0xFF1E88E5),
              ),
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width / 2 - 22,
              child: CustomCard(
                title: 'Expenses',
                value: formatInr(_expense),
                color: const Color(0xFFE53935),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text('Recent Activity', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          'API: $kResolvedApiBaseUrl',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        if (expenses.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No entries yet.'),
            ),
          )
        else
          ...expenses
              .take(4)
              .map((ExpenseModel item) => _ExpenseTile(expense: item)),
        const SizedBox(height: 12),
        Text('AI Insight', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        InsightWidget(expenses: expenses),
        const SizedBox(height: 12),
        const AiAssistantWidget(),
      ],
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({required this.expense});

  final ExpenseModel expense;

  @override
  Widget build(BuildContext context) {
    final bool isIncome = expense.type == ExpenseType.income;
    final Color amountColor = isIncome
        ? const Color(0xFF0C7A5B)
        : const Color(0xFFE53935);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: amountColor.withValues(alpha: 0.15),
          child: Icon(
            isIncome
                ? Icons.arrow_downward_rounded
                : Icons.arrow_upward_rounded,
            color: amountColor,
          ),
        ),
        title: Text(expense.title),
        subtitle: Text('${expense.category} • ${_formatDate(expense.date)}'),
        trailing: Text(
          formatInr(
            isIncome ? expense.amount : -expense.amount,
            withSign: true,
          ),
          style: TextStyle(color: amountColor, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  String _formatDate(DateTime value) {
    final String month = value.month.toString().padLeft(2, '0');
    final String day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}
