import '../../services/api_service.dart';
import 'expense_model.dart';

class ExpenseService {
  ExpenseService({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  static const String _expensesPath = '/api/expenses';
  static const String _categoriesPath = '/api/categories';
  static const List<String> _fallbackColors = <String>[
    '#4D96FF',
    '#FF6B6B',
    '#6BCB77',
    '#F4A261',
    '#8E7DBE',
    '#219EBC',
  ];

  final ApiService _apiService;
  final Map<String, int> _categoryIdByName = <String, int>{};
  final Map<int, String> _categoryNameById = <int, String>{};

  Future<List<ExpenseModel>> fetchExpenses() async {
    await _refreshCategories();

    final dynamic data = await _apiService.getJson(_expensesPath);
    if (data is! List) {
      throw ApiException('Unexpected expenses response format.');
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map(
          (Map<String, dynamic> row) =>
              ExpenseModel.fromJson(row, categoryNamesById: _categoryNameById),
        )
        .toList();
  }

  Future<ExpenseModel> createExpense(ExpenseModel expense) async {
    await _refreshCategories();
    final int categoryId = await _resolveCategoryId(expense.category);

    final dynamic data = await _apiService
        .postJson(_expensesPath, <String, dynamic>{
          'categoryId': categoryId,
          'amount': expense.amount.abs(),
          'description': _descriptionForBackend(expense),
          'spentAt': _dateForBackend(expense.date),
        });

    if (data is Map<String, dynamic>) {
      return ExpenseModel.fromJson(data, categoryNamesById: _categoryNameById);
    }
    return expense;
  }

  Future<void> _refreshCategories() async {
    final dynamic data = await _apiService.getJson(_categoriesPath);
    if (data is! List) {
      throw ApiException('Unexpected categories response format.');
    }

    _categoryIdByName.clear();
    _categoryNameById.clear();

    for (final Map<String, dynamic> row
        in data.whereType<Map<String, dynamic>>()) {
      final int? id = _toInt(row['id']);
      final String name = (row['name'] ?? '').toString().trim();
      if (id == null || name.isEmpty) {
        continue;
      }

      _categoryIdByName[_normalizeCategoryName(name)] = id;
      _categoryNameById[id] = name;
    }
  }

  Future<int> _resolveCategoryId(String categoryName) async {
    final String displayName = _displayCategoryName(categoryName);
    final String key = _normalizeCategoryName(displayName);
    final int? existingId = _categoryIdByName[key];
    if (existingId != null) {
      return existingId;
    }

    try {
      final dynamic created = await _apiService.postJson(
        _categoriesPath,
        <String, dynamic>{
          'name': displayName,
          'color': _categoryColor(displayName),
        },
      );

      if (created is! Map<String, dynamic>) {
        throw ApiException('Unexpected create-category response format.');
      }

      final int? id = _toInt(created['id']);
      if (id == null) {
        throw ApiException('Created category response is missing an id.');
      }

      _categoryIdByName[key] = id;
      _categoryNameById[id] = displayName;
      return id;
    } on ApiException catch (error) {
      if (error.statusCode == 409) {
        await _refreshCategories();
        final int? resolved = _categoryIdByName[key];
        if (resolved != null) {
          return resolved;
        }
      }
      rethrow;
    }
  }

  String _descriptionForBackend(ExpenseModel expense) {
    final String title = expense.title.trim().isEmpty
        ? 'Untitled'
        : expense.title.trim();
    if (expense.type == ExpenseType.income) {
      return '${ExpenseModel.incomePrefix}$title';
    }
    return title;
  }

  String _dateForBackend(DateTime date) {
    final DateTime local = date.toLocal();
    final String month = local.month.toString().padLeft(2, '0');
    final String day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }

  String _displayCategoryName(String raw) {
    final String trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return 'Other';
    }
    return trimmed[0].toUpperCase() + trimmed.substring(1);
  }

  String _normalizeCategoryName(String raw) {
    return raw.trim().toLowerCase();
  }

  String _categoryColor(String name) {
    final int hash = name.codeUnits.fold<int>(
      0,
      (int sum, int value) => sum + value,
    );
    return _fallbackColors[hash % _fallbackColors.length];
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
}
