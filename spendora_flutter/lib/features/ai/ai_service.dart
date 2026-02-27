import '../../services/api_service.dart';
import '../../core/currency.dart';
import '../expenses/expense_model.dart';

class AiCategorySuggestion {
  const AiCategorySuggestion({
    required this.category,
    required this.confidence,
    required this.source,
    this.suggestionId,
  });

  final String category;
  final double confidence;
  final String source;
  final int? suggestionId;
}

class AiInsightResult {
  const AiInsightResult({required this.insights});

  final List<String> insights;
}

class AiTrainingDataResult {
  const AiTrainingDataResult({
    required this.format,
    required this.count,
    required this.note,
    required this.lines,
  });

  final String format;
  final int count;
  final String note;
  final List<String> lines;

  String get asJsonl => lines.join('\n');
}

class AiService {
  AiService({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<AiCategorySuggestion> suggestCategory({
    required String description,
  }) async {
    final String input = description.trim();
    if (input.isEmpty) {
      throw ApiException('Description is required for AI category suggestion.');
    }

    final dynamic data = await _apiService.postJson(
      '/api/ai/suggest-category',
      <String, dynamic>{'description': input},
    );

    if (data is! Map<String, dynamic>) {
      throw ApiException('Unexpected AI suggestion response.');
    }

    return AiCategorySuggestion(
      category: (data['category'] ?? 'Uncategorized').toString(),
      confidence: _toDouble(data['confidence']) ?? 0,
      source: (data['source'] ?? 'AI').toString(),
      suggestionId: _toInt(data['suggestionId']),
    );
  }

  Future<void> submitFeedback({
    required int suggestionId,
    required String finalCategory,
  }) async {
    await _apiService.postJson('/api/ai/feedback', <String, dynamic>{
      'suggestionId': suggestionId,
      'finalCategory': finalCategory.trim(),
    });
  }

  Future<AiInsightResult> loadInsights(List<ExpenseModel> expenses) async {
    try {
      final dynamic data = await _apiService.getJson('/api/ai/insights');
      if (data is! Map<String, dynamic>) {
        return AiInsightResult(insights: _fallbackInsights(expenses));
      }

      final List<String> backendInsights =
          ((data['insights'] as List?) ?? <dynamic>[])
              .map((dynamic item) => item.toString())
              .where((String text) => text.trim().isNotEmpty)
              .toList();

      if (backendInsights.isNotEmpty) {
        return AiInsightResult(insights: backendInsights.take(4).toList());
      }

      return AiInsightResult(insights: _fallbackInsights(expenses));
    } catch (_) {
      return AiInsightResult(insights: _fallbackInsights(expenses));
    }
  }

  Future<AiTrainingDataResult> loadTrainingData() async {
    final dynamic data = await _apiService.getJson('/api/ai/training-data');
    if (data is! Map<String, dynamic>) {
      throw ApiException('Unexpected training-data response.');
    }

    final List<String> lines = ((data['lines'] as List?) ?? <dynamic>[])
        .map((dynamic item) => item.toString())
        .where((String line) => line.trim().isNotEmpty)
        .toList();

    return AiTrainingDataResult(
      format: (data['format'] ?? 'jsonl').toString(),
      count: _toInt(data['count']) ?? lines.length,
      note: (data['note'] ?? '').toString(),
      lines: lines,
    );
  }

  List<String> _fallbackInsights(List<ExpenseModel> expenses) {
    final List<ExpenseModel> expenseOnly = expenses
        .where((ExpenseModel item) => item.type == ExpenseType.expense)
        .toList();

    if (expenseOnly.isEmpty) {
      return const <String>['Add expense entries to generate AI insights.'];
    }

    final Map<String, double> byCategory = <String, double>{};
    for (final ExpenseModel item in expenseOnly) {
      byCategory[item.category] =
          (byCategory[item.category] ?? 0) + item.amount;
    }

    final MapEntry<String, double> top = byCategory.entries.reduce((
      MapEntry<String, double> a,
      MapEntry<String, double> b,
    ) {
      return a.value >= b.value ? a : b;
    });

    final double weeklyTotal = expenseOnly.fold<double>(
      0,
      (double sum, ExpenseModel item) => sum + item.amount,
    );

    return <String>[
      'Highest spend is ${top.key} at ${formatInr(top.value)}.',
      'Total expense tracked: ${formatInr(weeklyTotal)}.',
      'Consider a category cap for ${top.key} this week.',
    ];
  }

  int? _toInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  double? _toDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }
}
