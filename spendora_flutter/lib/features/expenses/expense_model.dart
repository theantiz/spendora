enum ExpenseType { income, expense }

class ExpenseModel {
  ExpenseModel({
    this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.type,
    required this.date,
  });

  static const String incomePrefix = '[INCOME] ';

  final String? id;
  final String title;
  final String category;
  final double amount;
  final ExpenseType type;
  final DateTime date;

  factory ExpenseModel.fromJson(
    Map<String, dynamic> json, {
    Map<int, String>? categoryNamesById,
  }) {
    final String description = (json['description'] ?? json['title'] ?? '')
        .toString()
        .trim();
    final bool inferredIncome = description.startsWith(incomePrefix);
    final String normalizedTitle = inferredIncome
        ? description.substring(incomePrefix.length).trim()
        : description;

    final Object? rawAmount = json['amount'];
    final double amount = switch (rawAmount) {
      num value => value.toDouble(),
      String value => double.tryParse(value) ?? 0,
      _ => 0,
    };

    final String rawType = (json['type'] ?? '').toString().toLowerCase();
    final ExpenseType type = rawType == 'income' || inferredIncome
        ? ExpenseType.income
        : ExpenseType.expense;

    final String rawDate = (json['spentAt'] ?? json['date'] ?? '').toString();
    final String category = _resolveCategory(
      json: json,
      categoryNamesById: categoryNamesById,
    );

    return ExpenseModel(
      id: json['id']?.toString(),
      title: normalizedTitle.isEmpty ? 'Untitled' : normalizedTitle,
      category: category,
      amount: amount,
      type: type,
      date: DateTime.tryParse(rawDate)?.toLocal() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (id != null) 'id': id,
      'title': title,
      'category': category,
      'amount': amount,
      'type': type.name,
      'date': date.toUtc().toIso8601String(),
    };
  }

  static String _resolveCategory({
    required Map<String, dynamic> json,
    Map<int, String>? categoryNamesById,
  }) {
    final String explicit = (json['category'] ?? json['categoryName'] ?? '')
        .toString()
        .trim();
    if (explicit.isNotEmpty) {
      return explicit;
    }

    final int? categoryId = _toInt(json['categoryId']);
    if (categoryId != null && categoryNamesById != null) {
      final String? mapped = categoryNamesById[categoryId];
      if (mapped != null && mapped.isNotEmpty) {
        return mapped;
      }
    }

    return 'Other';
  }

  static int? _toInt(Object? value) {
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
