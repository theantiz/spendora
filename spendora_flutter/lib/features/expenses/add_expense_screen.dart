import 'package:flutter/material.dart';

import '../../widgets/custom_button.dart';
import '../ai/ai_service.dart';
import 'expense_model.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final AiService _aiService = AiService();

  String _category = 'Food';
  ExpenseType _type = ExpenseType.expense;
  bool _isAiLoading = false;
  String? _aiHint;
  int? _aiSuggestionId;

  final List<String> _categories = <String>[
    'Food',
    'Transport',
    'Entertainment',
    'Shopping',
    'Bills',
    'Health',
    'Other',
    'Uncategorized',
  ];
  final List<String> _aiExamples = <String>[
    'Paneer butter masala dinner',
    'Dune movie ticket',
    'Netflix subscription',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _requestAiCategorySuggestion() async {
    final String title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() {
        _aiHint = 'Enter a title first so AI can suggest a category.';
      });
      return;
    }

    setState(() {
      _isAiLoading = true;
      _aiHint = null;
    });

    try {
      final AiCategorySuggestion suggestion = await _aiService.suggestCategory(
        description: title,
      );
      if (!mounted) {
        return;
      }

      final String suggestedCategory = _normalizeCategoryName(
        suggestion.category,
      );
      if (!_categories.contains(suggestedCategory)) {
        _categories.add(suggestedCategory);
      }

      setState(() {
        _category = suggestedCategory;
        _aiSuggestionId = suggestion.suggestionId;
        _aiHint =
            'AI selected "$suggestedCategory" '
            '(${(suggestion.confidence * 100).toStringAsFixed(0)}% • ${suggestion.source}).';
        _isAiLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _aiHint = 'AI suggestion unavailable: $error';
        _isAiLoading = false;
      });
    }
  }

  Future<void> _submit() async {
    final double? amount = double.tryParse(_amountController.text.trim());
    if (_titleController.text.trim().isEmpty || amount == null || amount <= 0) {
      return;
    }

    if (_aiSuggestionId != null) {
      try {
        await _aiService.submitFeedback(
          suggestionId: _aiSuggestionId!,
          finalCategory: _category,
        );
      } catch (_) {
        // Saving expense should continue even if feedback fails.
      }
    }

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop(
      ExpenseModel(
        title: _titleController.text.trim(),
        category: _category,
        amount: amount,
        type: _type,
        date: DateTime.now(),
      ),
    );
  }

  String _normalizeCategoryName(String input) {
    final String trimmed = input.trim();
    if (trimmed.isEmpty) {
      return 'Uncategorized';
    }
    return trimmed[0].toUpperCase() + trimmed.substring(1);
  }

  void _useAiExample(String text) {
    _titleController.text = text;
    _titleController.selection = TextSelection.fromPosition(
      TextPosition(offset: text.length),
    );
    setState(() {
      _aiHint = 'Example loaded. Tap AI to detect the category.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Expense')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _aiExamples
                    .map(
                      (String item) => ActionChip(
                        label: Text(item),
                        onPressed: () => _useAiExample(item),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Amount (₹)'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: _categories
                        .map(
                          (String category) => DropdownMenuItem<String>(
                            value: category,
                            child: Text(category),
                          ),
                        )
                        .toList(),
                    onChanged: (String? value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _category = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _isAiLoading ? null : _requestAiCategorySuggestion,
                  icon: _isAiLoading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: const Text('AI'),
                ),
              ],
            ),
            if (_aiHint != null) ...<Widget>[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _aiHint!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
            const SizedBox(height: 8),
            SegmentedButton<ExpenseType>(
              segments: const <ButtonSegment<ExpenseType>>[
                ButtonSegment<ExpenseType>(
                  value: ExpenseType.expense,
                  label: Text('Expense'),
                ),
                ButtonSegment<ExpenseType>(
                  value: ExpenseType.income,
                  label: Text('Income'),
                ),
              ],
              selected: <ExpenseType>{_type},
              onSelectionChanged: (Set<ExpenseType> selected) {
                setState(() {
                  _type = selected.first;
                });
              },
            ),
            const SizedBox(height: 16),
            CustomButton(label: 'Create Entry', onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
