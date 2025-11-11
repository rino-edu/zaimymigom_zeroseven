/// Модели для системы ведения бюджета

/// Модель дохода
class Income {
  final String? id;
  final String title;
  final double amount;
  final String categoryId;
  final DateTime date;
  final String? description;
  final bool isRecurring;
  final int? recurringIntervalDays; // null для разовых доходов
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Income({
    this.id,
    required this.title,
    required this.amount,
    required this.categoryId,
    required this.date,
    this.description,
    this.isRecurring = false,
    this.recurringIntervalDays,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category_id': categoryId,
      'date': date.toIso8601String(),
      'description': description,
      'is_recurring': isRecurring ? 1 : 0,
      'recurring_interval_days': recurringIntervalDays,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Income.fromMap(Map<String, dynamic> map) {
    return Income(
      id: map['id'] as String?,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      categoryId: map['category_id'] as String,
      date: DateTime.parse(map['date'] as String),
      description: map['description'] as String?,
      isRecurring: (map['is_recurring'] as int) == 1,
      recurringIntervalDays: map['recurring_interval_days'] as int?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Income copyWith({
    String? id,
    String? title,
    double? amount,
    String? categoryId,
    DateTime? date,
    String? description,
    bool? isRecurring,
    int? recurringIntervalDays,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Income(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      date: date ?? this.date,
      description: description ?? this.description,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringIntervalDays: recurringIntervalDays ?? this.recurringIntervalDays,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Модель расхода
class Expense {
  final String? id;
  final String title;
  final double amount;
  final String categoryId;
  final DateTime date;
  final String? description;
  final String? receiptImagePath; // Путь к фотографии чека
  final bool isRecurring;
  final int? recurringIntervalDays; // null для разовых расходов
  final List<String> tags;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Expense({
    this.id,
    required this.title,
    required this.amount,
    required this.categoryId,
    required this.date,
    this.description,
    this.receiptImagePath,
    this.isRecurring = false,
    this.recurringIntervalDays,
    this.tags = const [],
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category_id': categoryId,
      'date': date.toIso8601String(),
      'description': description,
      'receipt_image_path': receiptImagePath,
      'is_recurring': isRecurring ? 1 : 0,
      'recurring_interval_days': recurringIntervalDays,
      'tags': tags.join(','),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as String?,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      categoryId: map['category_id'] as String,
      date: DateTime.parse(map['date'] as String),
      description: map['description'] as String?,
      receiptImagePath: map['receipt_image_path'] as String?,
      isRecurring: (map['is_recurring'] as int) == 1,
      recurringIntervalDays: map['recurring_interval_days'] as int?,
      tags: (map['tags'] as String? ?? '').split(',').where((t) => t.isNotEmpty).toList(),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Expense copyWith({
    String? id,
    String? title,
    double? amount,
    String? categoryId,
    DateTime? date,
    String? description,
    String? receiptImagePath,
    bool? isRecurring,
    int? recurringIntervalDays,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      date: date ?? this.date,
      description: description ?? this.description,
      receiptImagePath: receiptImagePath ?? this.receiptImagePath,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringIntervalDays: recurringIntervalDays ?? this.recurringIntervalDays,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Модель категории
class Category {
  final String? id;
  final String name;
  final CategoryType type; // income или expense
  final String? parentCategoryId; // для подкатегорий
  final int color; // цвет в формате int (0xFFRRGGBB)
  final String? icon; // название иконки
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Category({
    this.id,
    required this.name,
    required this.type,
    this.parentCategoryId,
    this.color = 0xFF2196F3,
    this.icon,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'parent_category_id': parentCategoryId,
      'color': color,
      'icon': icon,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as String?,
      name: map['name'] as String,
      type: CategoryType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => CategoryType.expense,
      ),
      parentCategoryId: map['parent_category_id'] as String?,
      color: map['color'] as int? ?? 0xFF2196F3,
      icon: map['icon'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Category copyWith({
    String? id,
    String? name,
    CategoryType? type,
    String? parentCategoryId,
    int? color,
    String? icon,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      parentCategoryId: parentCategoryId ?? this.parentCategoryId,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Тип категории
enum CategoryType {
  income,
  expense,
}

/// Модель лимита бюджета
class BudgetLimit {
  final String? id;
  final String categoryId;
  final double amount;
  final BudgetPeriod period; // неделя или месяц
  final DateTime? createdAt;
  final DateTime? updatedAt;

  BudgetLimit({
    this.id,
    required this.categoryId,
    required this.amount,
    required this.period,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'amount': amount,
      'period': period.name,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory BudgetLimit.fromMap(Map<String, dynamic> map) {
    return BudgetLimit(
      id: map['id'] as String?,
      categoryId: map['category_id'] as String,
      amount: (map['amount'] as num).toDouble(),
      period: BudgetPeriod.values.firstWhere(
        (e) => e.name == map['period'],
        orElse: () => BudgetPeriod.month,
      ),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  BudgetLimit copyWith({
    String? id,
    String? categoryId,
    double? amount,
    BudgetPeriod? period,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BudgetLimit(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      period: period ?? this.period,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Период бюджета
enum BudgetPeriod {
  week,
  month,
}

