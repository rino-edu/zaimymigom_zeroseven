import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/calendar_event.dart';

class CalendarProvider extends ChangeNotifier {
  static const String _storageKey = 'calendar_events_v1';

  final List<CalendarEvent> _events = [];
  bool _initialized = false;

  List<CalendarEvent> get events =>
      List<CalendarEvent>.unmodifiable(_events..sort((a, b) => a.dateTime.compareTo(b.dateTime)));

  bool get initialized => _initialized;

  Future<void> load() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_storageKey) ?? <String>[];
    _events
      ..clear()
      ..addAll(data.map((e) => CalendarEvent.fromMap(jsonDecode(e) as Map<String, dynamic>)));
    _initialized = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _events.map((e) => jsonEncode(e.toMap())).toList();
    await prefs.setStringList(_storageKey, data);
  }

  Future<void> add(CalendarEvent event) async {
    _events.add(event);
    await _persist();
    notifyListeners();
  }

  Future<void> update(CalendarEvent event) async {
    final index = _events.indexWhere((e) => e.id == event.id);
    if (index != -1) {
      _events[index] = event;
      await _persist();
      notifyListeners();
    }
  }

  Future<void> remove(String id) async {
    _events.removeWhere((e) => e.id == id);
    await _persist();
    notifyListeners();
  }

  List<CalendarEvent> eventsForDate(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return _events
        .where((e) {
          final ed = DateTime(e.dateTime.year, e.dateTime.month, e.dateTime.day);
          return ed == d;
        })
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }
}


