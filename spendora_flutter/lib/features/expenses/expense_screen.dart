import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/currency.dart';
import '../../services/api_service.dart';
import '../dashboard/dashboard_screen.dart';
import '../auth/login_screen.dart';
import 'add_expense_screen.dart';
import 'expense_model.dart';
import 'expense_service.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  final ExpenseService _expenseService = ExpenseService();

  bool _isLoading = true;
  String? _error;
  int _index = 0;
  List<ExpenseModel> _expenses = <ExpenseModel>[];

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final List<ExpenseModel> remoteExpenses = await _expenseService
          .fetchExpenses();
      if (!mounted) {
        return;
      }

      setState(() {
        _expenses = remoteExpenses;
        _error = null;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      if (error is ApiException &&
          (error.statusCode == 401 || error.statusCode == 403)) {
        _logout();
        return;
      }

      setState(() {
        _error = _toReadableLoadError(error);
        _isLoading = false;
      });
    }
  }

  Future<void> _openAddExpense() async {
    final ExpenseModel? draft = await Navigator.of(context).push<ExpenseModel>(
      MaterialPageRoute<ExpenseModel>(builder: (_) => const AddExpenseScreen()),
    );

    if (draft == null) {
      return;
    }

    try {
      final ExpenseModel created = await _expenseService.createExpense(draft);
      if (!mounted) {
        return;
      }

      setState(() {
        _expenses.insert(0, created);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_toReadableCreateError(error))));
    }
  }

  String _toReadableLoadError(Object error) {
    if (error is ApiException &&
        (error.statusCode == 401 || error.statusCode == 403)) {
      return 'Session expired or unauthorized. Please login again.';
    }

    return 'Backend unavailable at $kResolvedApiBaseUrl. $error\n'
        'If using a real phone, run with '
        '--dart-define=API_BASE_URL=http://<your-lan-ip>:8080';
  }

  String _toReadableCreateError(Object error) {
    if (error is ApiException) {
      return error.message;
    }
    return 'Could not save to backend. No local fallback is used.';
  }

  void _logout() {
    setApiToken(null);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = <Widget>[
      DashboardScreen(expenses: _expenses),
      _TransactionsList(expenses: _expenses),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spendora'),
        actions: <Widget>[
          IconButton(
            onPressed: _loadExpenses,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh from backend',
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: pages[_index],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddExpense,
        icon: const Icon(Icons.add),
        label: const Text('Add Entry'),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        destinations: const <NavigationDestination>[
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            label: 'Transactions',
          ),
        ],
        onDestinationSelected: (int value) {
          setState(() {
            _index = value;
          });
        },
      ),
      bottomSheet: _isLoading
          ? const LinearProgressIndicator(minHeight: 2)
          : _error == null
          ? null
          : Material(
              color: Colors.amber.shade100,
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(_error!, textAlign: TextAlign.center),
                  ),
                ),
              ),
            ),
    );
  }
}

class _TransactionsList extends StatefulWidget {
  const _TransactionsList({required this.expenses});

  final List<ExpenseModel> expenses;

  @override
  State<_TransactionsList> createState() => _TransactionsListState();
}

class _TransactionsListState extends State<_TransactionsList> {
  ExpenseType? _filter;

  @override
  Widget build(BuildContext context) {
    final List<ExpenseModel> filtered = _filter == null
        ? widget.expenses
        : widget.expenses
              .where((ExpenseModel item) => item.type == _filter)
              .toList();

    return Column(
      children: <Widget>[
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: <Widget>[
            ChoiceChip(
              label: const Text('All'),
              selected: _filter == null,
              onSelected: (_) => setState(() => _filter = null),
            ),
            ChoiceChip(
              label: const Text('Income'),
              selected: _filter == ExpenseType.income,
              onSelected: (_) => setState(() => _filter = ExpenseType.income),
            ),
            ChoiceChip(
              label: const Text('Expenses'),
              selected: _filter == ExpenseType.expense,
              onSelected: (_) => setState(() => _filter = ExpenseType.expense),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('No expense data found in database.'))
              : ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (_, int index) {
                    final ExpenseModel expense = filtered[index];
                    final bool isIncome = expense.type == ExpenseType.income;
                    final Color amountColor = isIncome
                        ? const Color(0xFF0C7A5B)
                        : const Color(0xFFE53935);

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      child: ListTile(
                        title: Text(expense.title),
                        subtitle: Text(expense.category),
                        trailing: Text(
                          formatInr(
                            isIncome ? expense.amount : -expense.amount,
                            withSign: true,
                          ),
                          style: TextStyle(
                            color: amountColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
