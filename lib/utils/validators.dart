/// Валидаторы для форм приложения
class Validators {
  /// Проверка на пустое значение
  static String? required(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return fieldName != null 
          ? 'Поле "$fieldName" обязательно для заполнения'
          : 'Поле обязательно для заполнения';
    }
    return null;
  }
  
  /// Проверка длины строки
  static String? length(String? value, int min, int max, {String? fieldName}) {
    if (value == null) return null;
    
    if (value.length < min) {
      return fieldName != null 
          ? 'Поле "$fieldName" должно содержать минимум $min символов'
          : 'Минимальная длина: $min символов';
    }
    
    if (value.length > max) {
      return fieldName != null 
          ? 'Поле "$fieldName" должно содержать максимум $max символов'
          : 'Максимальная длина: $max символов';
    }
    
    return null;
  }
  
  /// Проверка email
  static String? email(String? value) {
    if (value == null || value.isEmpty) return null;
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Введите корректный email адрес';
    }
    return null;
  }
  
  /// Проверка телефона
  static String? phone(String? value) {
    if (value == null || value.isEmpty) return null;
    
    final phoneRegex = RegExp(r'^\+?[1-9]\d{1,14}$');
    final cleanPhone = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    if (!phoneRegex.hasMatch(cleanPhone)) {
      return 'Введите корректный номер телефона';
    }
    return null;
  }
  
  /// Проверка URL
  static String? url(String? value) {
    if (value == null || value.isEmpty) return null;
    
    final urlRegex = RegExp(r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$');
    if (!urlRegex.hasMatch(value)) {
      return 'Введите корректный URL';
    }
    return null;
  }
  
  /// Проверка числового значения
  static String? number(String? value, {double? min, double? max, String? fieldName}) {
    if (value == null || value.isEmpty) return null;
    
    final number = double.tryParse(value);
    if (number == null) {
      return fieldName != null 
          ? 'Поле "$fieldName" должно содержать число'
          : 'Введите корректное число';
    }
    
    if (min != null && number < min) {
      return fieldName != null 
          ? 'Поле "$fieldName" должно быть больше $min'
          : 'Значение должно быть больше $min';
    }
    
    if (max != null && number > max) {
      return fieldName != null 
          ? 'Поле "$fieldName" должно быть меньше $max'
          : 'Значение должно быть меньше $max';
    }
    
    return null;
  }
  
  /// Проверка положительного числа
  static String? positiveNumber(String? value, {String? fieldName}) {
    return number(value, min: 0, fieldName: fieldName);
  }
  
  /// Проверка PIN-кода
  static String? pin(String? value) {
    if (value == null || value.isEmpty) {
      return 'Введите PIN-код';
    }
    
    if (value.length < 4 || value.length > 8) {
      return 'PIN-код должен содержать от 4 до 8 цифр';
    }
    
    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return 'PIN-код должен содержать только цифры';
    }
    
    return null;
  }
  
  /// Проверка пароля
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Введите пароль';
    }
    
    if (value.length < 8) {
      return 'Пароль должен содержать минимум 8 символов';
    }
    
    if (value.length > 128) {
      return 'Пароль должен содержать максимум 128 символов';
    }
    
    return null;
  }
  
  /// Проверка подтверждения пароля
  static String? confirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Подтвердите пароль';
    }
    
    if (value != password) {
      return 'Пароли не совпадают';
    }
    
    return null;
  }
  
  /// Проверка даты
  static String? date(DateTime? value, {DateTime? min, DateTime? max, String? fieldName}) {
    if (value == null) return null;
    
    if (min != null && value.isBefore(min)) {
      return fieldName != null 
          ? 'Поле "$fieldName" не может быть раньше ${_formatDate(min)}'
          : 'Дата не может быть раньше ${_formatDate(min)}';
    }
    
    if (max != null && value.isAfter(max)) {
      return fieldName != null 
          ? 'Поле "$fieldName" не может быть позже ${_formatDate(max)}'
          : 'Дата не может быть позже ${_formatDate(max)}';
    }
    
    return null;
  }
  
  /// Проверка даты в будущем
  static String? futureDate(DateTime? value, {String? fieldName}) {
    if (value == null) return null;
    
    final now = DateTime.now();
    if (value.isBefore(now)) {
      return fieldName != null 
          ? 'Поле "$fieldName" должно быть в будущем'
          : 'Дата должна быть в будущем';
    }
    
    return null;
  }
  
  /// Проверка даты в прошлом
  static String? pastDate(DateTime? value, {String? fieldName}) {
    if (value == null) return null;
    
    final now = DateTime.now();
    if (value.isAfter(now)) {
      return fieldName != null 
          ? 'Поле "$fieldName" должно быть в прошлом'
          : 'Дата должна быть в прошлом';
    }
    
    return null;
  }
  
  /// Проверка диапазона дат
  static String? dateRange(DateTime? startDate, DateTime? endDate, {String? fieldName}) {
    if (startDate == null || endDate == null) return null;
    
    if (endDate.isBefore(startDate)) {
      return fieldName != null 
          ? 'Поле "$fieldName": дата окончания не может быть раньше даты начала'
          : 'Дата окончания не может быть раньше даты начала';
    }
    
    return null;
  }
  
  /// Проверка названия проекта
  static String? projectName(String? value) {
    return required(value, fieldName: 'Название проекта') ?? 
           length(value, 2, 100, fieldName: 'Название проекта');
  }
  
  /// Проверка описания проекта
  static String? projectDescription(String? value) {
    if (value != null && value.length > 1000) {
      return 'Описание проекта должно содержать максимум 1000 символов';
    }
    return null;
  }
  
  /// Проверка названия задачи
  static String? taskTitle(String? value) {
    return required(value, fieldName: 'Название задачи') ?? 
           length(value, 2, 200, fieldName: 'Название задачи');
  }
  
  /// Проверка описания задачи
  static String? taskDescription(String? value) {
    if (value != null && value.length > 1000) {
      return 'Описание задачи должно содержать максимум 1000 символов';
    }
    return null;
  }
  
  /// Проверка названия заметки
  static String? noteTitle(String? value) {
    return required(value, fieldName: 'Название заметки') ?? 
           length(value, 2, 200, fieldName: 'Название заметки');
  }
  
  /// Проверка содержимого заметки
  static String? noteContent(String? value) {
    if (value != null && value.length > 5000) {
      return 'Содержимое заметки должно содержать максимум 5000 символов';
    }
    return null;
  }
  
  /// Проверка размеров для калькуляторов
  static String? dimension(String? value, {String? fieldName}) {
    final numberValidation = positiveNumber(value, fieldName: fieldName);
    if (numberValidation != null) return numberValidation;
    
    final number = double.tryParse(value!);
    if (number! > 1000) {
      return fieldName != null 
          ? 'Поле "$fieldName" не может быть больше 1000'
          : 'Значение не может быть больше 1000';
    }
    
    return null;
  }
  
  /// Проверка количества материала
  static String? materialQuantity(String? value) {
    return positiveNumber(value, fieldName: 'Количество');
  }
  
  /// Проверка цены материала
  static String? materialPrice(String? value) {
    return positiveNumber(value, fieldName: 'Цена');
  }
  
  /// Форматирование даты для валидации
  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
  
  /// Комбинированный валидатор
  static String? combine(List<String? Function()> validators) {
    for (final validator in validators) {
      final result = validator();
      if (result != null) return result;
    }
    return null;
  }
}
