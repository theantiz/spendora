import 'package:flutter/material.dart';

import '../expenses/expense_model.dart';
import 'ai_service.dart';

class InsightWidget extends StatefulWidget {
  const InsightWidget({required this.expenses, super.key});

  final List<ExpenseModel> expenses;

  @override
  State<InsightWidget> createState() => _InsightWidgetState();
}

class _InsightWidgetState extends State<InsightWidget> {
  final AiService _aiService = AiService();
  late Future<AiInsightResult> _insightsFuture;

  @override
  void initState() {
    super.initState();
    _insightsFuture = _aiService.loadInsights(widget.expenses);
  }

  @override
  void didUpdateWidget(covariant InsightWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expenses.length != widget.expenses.length) {
      _insightsFuture = _aiService.loadInsights(widget.expenses);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AiInsightResult>(
      future: _insightsFuture,
      builder: (BuildContext context, AsyncSnapshot<AiInsightResult> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: LinearProgressIndicator(),
            ),
          );
        }

        final List<String> insights =
            snapshot.data?.insights ?? <String>['No insights yet.'];

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: insights
                  .map(
                    (String item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text('• $item'),
                    ),
                  )
                  .toList(),
            ),
          ),
        );
      },
    );
  }
}
