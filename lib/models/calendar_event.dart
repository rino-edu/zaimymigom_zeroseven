import 'dart:convert';

enum CalendarEventType {
  loanPayment,
  subscription,
  bill,
  goalDeadline,
  other,
}

class CalendarEvent {
  final String id;
  final String title;
  final DateTime dateTime;
  final CalendarEventType type;
  final bool isPaid;
  final String? description;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.dateTime,
    required this.type,
    this.isPaid = false,
    this.description,
  });

  CalendarEvent copyWith({
    String? id,
    String? title,
    DateTime? dateTime,
    CalendarEventType? type,
    bool? isPaid,
    String? description,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      dateTime: dateTime ?? this.dateTime,
      type: type ?? this.type,
      isPaid: isPaid ?? this.isPaid,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'dateTime': dateTime.toIso8601String(),
      'type': type.name,
      'isPaid': isPaid,
      'description': description,
    };
  }

  factory CalendarEvent.fromMap(Map<String, dynamic> map) {
    return CalendarEvent(
      id: map['id'] as String,
      title: map['title'] as String,
      dateTime: DateTime.parse(map['dateTime'] as String),
      type: CalendarEventType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => CalendarEventType.other,
      ),
      isPaid: (map['isPaid'] as bool?) ?? false,
      description: map['description'] as String?,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory CalendarEvent.fromJson(String source) =>
      CalendarEvent.fromMap(jsonDecode(source) as Map<String, dynamic>);
}


