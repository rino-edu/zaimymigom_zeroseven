import 'package:flutter/material.dart';

/// Цветовая схема приложения для строительного таск-менеджера
class AppColors {
  // Основные цвета
  static const Color primary = Color(0xFF4BAD07); // Зеленый - цвет строительства
  static const Color primaryLight = Color(0xFFAEFB81);
  static const Color primaryDark = Color(0xFF388602);
  
  // Вторичные цвета
  static const Color secondary = Color(0xFFFF8F00); // Оранжевый - предупреждения
  static const Color secondaryLight = Color(0xFFFFB74D);
  static const Color secondaryDark = Color(0xFFE65100);
  
  // Акцентные цвета
  static const Color accent = Color(0xFF2E7D32); // Синий - информация
  static const Color accentLight = Color(0xFF60AD5E);
  static const Color accentDark = Color(0xFF1B5E20);
  
  // Цвета приоритетов задач
  static const Color urgent = Color(0xFFD32F2F); // Красный - срочно
  static const Color high = Color(0xFFFF8F00); // Оранжевый - высокий
  static const Color medium = Color(0xFF1976D2); // Синий - средний
  static const Color low = Color(0xFF388E3C); // Зеленый - низкий
  
  // Цвета статусов
  static const Color completed = Color(0xFF4CAF50); // Зеленый - выполнено
  static const Color inProgress = Color(0xFF2196F3); // Синий - в процессе
  static const Color pending = Color(0xFFFF9800); // Оранжевый - ожидает
  static const Color cancelled = Color(0xFF9E9E9E); // Серый - отменено
  
  // Цвета тегов
  static const Color planning = Color(0xFF9C27B0); // Фиолетовый - планирование
  static const Color materials = Color(0xFF795548); // Коричневый - материалы
  static const Color construction = Color(0xFF607D8B); // Сине-серый - строительство
  static const Color finishing = Color(0xFFFFC107); // Янтарный - отделка
  static const Color inspection = Color(0xFFE91E63); // Розовый - проверка
  static const Color other = Color(0xFF9E9E9E); // Серый - другое
  
  // Фоновые цвета
  static const Color background = Color(0xFFFAFAFA); // Светло-серый фон
  static const Color surface = Color(0xFFFFFFFF); // Белый поверхность
  static const Color cardBackground = Color(0xFFFFFFFF); // Белый фон карточек
  
  // Текстовые цвета
  static const Color textPrimary = Color(0xFF212121); // Темно-серый основной текст
  static const Color textSecondary = Color(0xFF757575); // Серый вторичный текст
  static const Color textHint = Color(0xFFBDBDBD); // Светло-серый подсказки
  
  // Цвета ошибок и состояний
  static const Color error = Color(0xFFD32F2F); // Красный - ошибка
  static const Color warning = Color(0xFFFF8F00); // Оранжевый - предупреждение
  static const Color success = Color(0xFF4CAF50); // Зеленый - успех
  static const Color info = Color(0xFF2196F3); // Синий - информация
  
  // Границы и разделители
  static const Color divider = Color(0xFFE0E0E0); // Светло-серый разделитель
  static const Color border = Color(0xFFBDBDBD); // Серый граница
  
  // Тени
  static const Color shadow = Color(0x1A000000); // Полупрозрачный черный для теней
  
  // Темная тема
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFB3B3B3);
  static const Color darkDivider = Color(0xFF333333);
  
  // Получение цвета по приоритету
  static Color getPriorityColor(Priority priority) {
    switch (priority) {
      case Priority.urgent:
        return urgent;
      case Priority.high:
        return high;
      case Priority.medium:
        return medium;
      case Priority.low:
        return low;
    }
  }
  
  // Получение цвета по статусу
  static Color getStatusColor(Status status) {
    switch (status) {
      case Status.completed:
        return completed;
      case Status.inProgress:
        return inProgress;
      case Status.pending:
        return pending;
      case Status.cancelled:
        return cancelled;
    }
  }
  
  // Получение цвета по тегу
  static Color getTagColor(TaskTag tag) {
    switch (tag) {
      case TaskTag.planning:
        return planning;
      case TaskTag.materials:
        return materials;
      case TaskTag.construction:
        return construction;
      case TaskTag.finishing:
        return finishing;
      case TaskTag.inspection:
        return inspection;
      case TaskTag.other:
        return other;
    }
  }
}

/// Приоритеты задач
enum Priority {
  low,
  medium,
  high,
  urgent,
}

/// Статусы задач
enum Status {
  pending,
  inProgress,
  completed,
  cancelled,
}

/// Теги задач
enum TaskTag {
  planning,
  materials,
  construction,
  finishing,
  inspection,
  other,
}
