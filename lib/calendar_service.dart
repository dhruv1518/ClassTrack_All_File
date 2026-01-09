import 'package:flutter/material.dart';

class EventCategory {
  final String id;
  String name;
  Color color;

  EventCategory({required this.name, this.color = Colors.blue})
      : id = UniqueKey().toString();

  factory EventCategory.defaultCategory() {
    return EventCategory(name: 'General', color: Colors.grey);
  }
}

class CalendarEvent {
  final String id;
  String title;
  DateTime date;
  EventCategory category;
  bool hasReminder;

  CalendarEvent({
    required this.title,
    required this.date,
    required this.category,
    this.hasReminder = false,
  }) : id = UniqueKey().toString();
}

class CalendarService {
  static final CalendarService _instance = CalendarService._internal();
  factory CalendarService() => _instance;
  CalendarService._internal() {
    if (categories.isEmpty) {
      categories.add(EventCategory.defaultCategory());
    }
    // Example events for testing alerts
   }

  final List<EventCategory> categories = [];
  final List<CalendarEvent> events = [];

  EventCategory getCategoryById(String id) {
    return categories.firstWhere((cat) => cat.id == id, orElse: () => EventCategory.defaultCategory());
  }

  CalendarEvent? getMostUrgentEvent() {
    final now = DateTime.now();
    final upcomingEvents = events.where((event) => !event.date.isBefore(DateTime(now.year, now.month, now.day))).toList();
    if (upcomingEvents.isEmpty) {
      return null;
    }
    upcomingEvents.sort((a, b) => a.date.compareTo(b.date));
    return upcomingEvents.first;
  }
}
