import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Вспомогательные функции приложения
class Helpers {
  /// Форматирование даты
  static String formatDate(DateTime date, {String pattern = 'dd.MM.yyyy'}) {
    final formatter = DateFormat(pattern, 'ru');
    return formatter.format(date);
  }
  
  /// Форматирование времени
  static String formatTime(DateTime date, {String pattern = 'HH:mm'}) {
    final formatter = DateFormat(pattern, 'ru');
    return formatter.format(date);
  }
  
  /// Форматирование даты и времени
  static String formatDateTime(DateTime date, {String pattern = 'dd.MM.yyyy HH:mm'}) {
    final formatter = DateFormat(pattern, 'ru');
    return formatter.format(date);
  }
  
  /// Форматирование относительной даты
  static String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Сегодня';
    } else if (difference.inDays == 1) {
      return 'Вчера';
    } else if (difference.inDays == -1) {
      return 'Завтра';
    } else if (difference.inDays > 1 && difference.inDays < 7) {
      return '${difference.inDays} дня назад';
    } else if (difference.inDays < -1 && difference.inDays > -7) {
      return 'Через ${(-difference.inDays)} дня';
    } else {
      return formatDate(date);
    }
  }
  
  /// Форматирование длительности
  static String formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} дн. ${duration.inHours % 24} ч.';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} ч. ${duration.inMinutes % 60} мин.';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} мин.';
    } else {
      return '${duration.inSeconds} сек.';
    }
  }
  
  /// Форматирование размера файла
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes Б';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} КБ';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} МБ';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} ГБ';
    }
  }
  
  /// Форматирование числа с разделителями
  static String formatNumber(double number, {int decimals = 2}) {
    final formatter = NumberFormat('#,##0.${'0' * decimals}', 'ru');
    return formatter.format(number);
  }
  
  /// Форматирование процентов
  static String formatPercentage(double value, {int decimals = 1}) {
    final formatter = NumberFormat('#,##0.${'0' * decimals}%', 'ru');
    return formatter.format(value / 100);
  }
  
  /// Получение инициалов из имени
  static String getInitials(String name) {
    final words = name.trim().split(' ');
    if (words.isEmpty) return '';
    
    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    } else {
      return '${words[0].substring(0, 1)}${words[1].substring(0, 1)}'.toUpperCase();
    }
  }
  
  /// Обрезка текста с многоточием
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
  
  /// Проверка на просроченность задачи
  static bool isOverdue(DateTime deadline) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadlineDate = DateTime(deadline.year, deadline.month, deadline.day);
    return deadlineDate.isBefore(today);
  }
  
  /// Получение количества дней до дедлайна
  static int getDaysUntilDeadline(DateTime deadline) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadlineDate = DateTime(deadline.year, deadline.month, deadline.day);
    return deadlineDate.difference(today).inDays;
  }
  
  /// Проверка на приближающийся дедлайн
  static bool isDeadlineApproaching(DateTime deadline, {int daysThreshold = 3}) {
    return getDaysUntilDeadline(deadline) <= daysThreshold && getDaysUntilDeadline(deadline) >= 0;
  }
  
  /// Получение цвета по приоритету
  static Color getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
      case 'срочный':
        return Colors.red;
      case 'high':
      case 'высокий':
        return Colors.orange;
      case 'medium':
      case 'средний':
        return Colors.blue;
      case 'low':
      case 'низкий':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
  
  /// Получение иконки по приоритету
  static IconData getPriorityIcon(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
      case 'срочный':
        return Icons.priority_high;
      case 'high':
      case 'высокий':
        return Icons.keyboard_arrow_up;
      case 'medium':
      case 'средний':
        return Icons.remove;
      case 'low':
      case 'низкий':
        return Icons.keyboard_arrow_down;
      default:
        return Icons.help_outline;
    }
  }
  
  /// Получение цвета по статусу
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'выполнено':
        return Colors.green;
      case 'in_progress':
      case 'в процессе':
        return Colors.blue;
      case 'pending':
      case 'ожидает':
        return Colors.orange;
      case 'cancelled':
      case 'отменено':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
  
  /// Получение иконки по статусу
  static IconData getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'выполнено':
        return Icons.check_circle;
      case 'in_progress':
      case 'в процессе':
        return Icons.play_circle;
      case 'pending':
      case 'ожидает':
        return Icons.pending;
      case 'cancelled':
      case 'отменено':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }
  
  /// Генерация случайного цвета
  static Color generateRandomColor() {
    final colors = [
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.yellow,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
      Colors.brown,
      Colors.grey,
      Colors.blueGrey,
    ];
    return colors[DateTime.now().millisecondsSinceEpoch % colors.length];
  }
  
  /// Получение цвета из строки
  static Color getColorFromString(String string) {
    final hash = string.hashCode;
    final color = Color.fromARGB(
      255,
      (hash >> 16) & 0xFF,
      (hash >> 8) & 0xFF,
      hash & 0xFF,
    );
    return color;
  }
  
  /// Создание градиента
  static LinearGradient createGradient(Color color) {
    return LinearGradient(
      colors: [
        color.withOpacity(0.8),
        color.withOpacity(0.6),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
  
  /// Проверка на пустую строку
  static bool isEmpty(String? value) {
    return value == null || value.trim().isEmpty;
  }
  
  /// Проверка на непустую строку
  static bool isNotEmpty(String? value) {
    return !isEmpty(value);
  }
  
  /// Безопасное преобразование в int
  static int? safeParseInt(String? value) {
    if (value == null || value.isEmpty) return null;
    return int.tryParse(value);
  }
  
  /// Безопасное преобразование в double
  static double? safeParseDouble(String? value) {
    if (value == null || value.isEmpty) return null;
    return double.tryParse(value);
  }
  
  /// Безопасное преобразование в DateTime
  static DateTime? safeParseDateTime(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
  
  /// Получение текущего времени в миллисекундах
  static int getCurrentTimestamp() {
    return DateTime.now().millisecondsSinceEpoch;
  }
  
  /// Создание уникального ID
  static String generateId() {
    return '${getCurrentTimestamp()}_${(DateTime.now().microsecond % 1000).toString().padLeft(3, '0')}';
  }
  
  /// Копирование в буфер обмена
  static Future<void> copyToClipboard(String text) async {
    // Реализация будет добавлена при необходимости
  }
  
  /// Показать SnackBar
  static void showSnackBar(BuildContext context, String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }
  
  /// Показать диалог подтверждения
  static Future<bool?> showConfirmDialog(
    BuildContext context,
    String title,
    String message, {
    String confirmText = 'Подтвердить',
    String cancelText = 'Отмена',
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }
  
  /// Получение дня недели
  static String getWeekdayName(DateTime date) {
    final weekdays = ['Понедельник', 'Вторник', 'Среда', 'Четверг', 'Пятница', 'Суббота', 'Воскресенье'];
    return weekdays[date.weekday - 1];
  }
  
  /// Получение названия месяца
  static String getMonthName(DateTime date) {
    final months = [
      'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
      'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'
    ];
    return months[date.month - 1];
  }
  
  /// Проверка на выходной день
  static bool isWeekend(DateTime date) {
    return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
  }
  
  /// Получение первого дня месяца
  static DateTime getFirstDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }
  
  /// Получение последнего дня месяца
  static DateTime getLastDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }
  
  /// Получение первого дня недели
  static DateTime getFirstDayOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }
  
  /// Получение последнего дня недели
  static DateTime getLastDayOfWeek(DateTime date) {
    return date.add(Duration(days: 7 - date.weekday));
  }
}
