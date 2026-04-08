import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ─── Event Category ───

class EventCategory {
  final String id;
  String name;
  Color color;

  EventCategory({required this.id, required this.name, this.color = Colors.blue});

  factory EventCategory.create({required String name, Color color = Colors.blue}) {
    return EventCategory(id: UniqueKey().toString(), name: name, color: color);
  }

  factory EventCategory.defaultCategory() {
    return EventCategory(id: 'general', name: 'General', color: Colors.grey);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color': color.value,
    };
  }

  factory EventCategory.fromMap(Map<String, dynamic> map) {
    return EventCategory(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      color: Color(map['color'] ?? Colors.blue.value),
    );
  }
}

// ─── Calendar Event ───

class CalendarEvent {
  final String id;
  String title;
  DateTime date;
  EventCategory category;
  bool hasReminder;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.date,
    required this.category,
    this.hasReminder = false,
  });

  factory CalendarEvent.create({
    required String title,
    required DateTime date,
    required EventCategory category,
    bool hasReminder = false,
  }) {
    return CalendarEvent(
      id: UniqueKey().toString(),
      title: title,
      date: date,
      category: category,
      hasReminder: hasReminder,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'date': date.toIso8601String(),
      'categoryId': category.id,
      'categoryName': category.name,
      'categoryColor': category.color.value,
      'hasReminder': hasReminder,
    };
  }

  factory CalendarEvent.fromMap(Map<String, dynamic> map) {
    return CalendarEvent(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      date: DateTime.parse(map['date']),
      category: EventCategory(
        id: map['categoryId'] ?? 'general',
        name: map['categoryName'] ?? 'General',
        color: Color(map['categoryColor'] ?? Colors.grey.value),
      ),
      hasReminder: map['hasReminder'] ?? false,
    );
  }
}

// ─── Firestore-backed Calendar Service (singleton) ───

class CalendarService extends ChangeNotifier {
  static final CalendarService _instance = CalendarService._internal();
  factory CalendarService() => _instance;
  CalendarService._internal();

  final List<EventCategory> categories = [];
  final List<CalendarEvent> events = [];
  String? _userId;

  // Firestore references
  CollectionReference<Map<String, dynamic>> get _categoriesRef =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('eventCategories');

  CollectionReference<Map<String, dynamic>> get _eventsRef =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('calendarEvents');

  // ─── Initialization ───

  void setUser(String userId) {
    _userId = userId;
    fetchAll();
  }

  Future<void> fetchAll() async {
    await fetchCategories();
    await fetchEvents();
  }

  // ─── Categories ───

  Future<void> fetchCategories() async {
    if (_userId == null) return;

    final snapshot = await _categoriesRef.get();
    categories.clear();

    if (snapshot.docs.isEmpty) {
      // Ensure default category exists
      final defaultCat = EventCategory.defaultCategory();
      await _categoriesRef.doc(defaultCat.id).set(defaultCat.toMap());
      categories.add(defaultCat);
    } else {
      categories.addAll(
        snapshot.docs.map((doc) => EventCategory.fromMap(doc.data())),
      );
    }
    notifyListeners();
  }

  Future<void> addCategory(String name, {Color color = Colors.blue}) async {
    if (_userId == null) return;
    final cat = EventCategory.create(name: name, color: color);
    await _categoriesRef.doc(cat.id).set(cat.toMap());
    await fetchCategories();
  }

  Future<void> deleteCategory(String categoryId) async {
    if (_userId == null) return;
    await _categoriesRef.doc(categoryId).delete();
    await fetchCategories();
  }

  EventCategory getCategoryById(String id) {
    return categories.firstWhere(
      (cat) => cat.id == id,
      orElse: () => EventCategory.defaultCategory(),
    );
  }

  // ─── Events ───

  Future<void> fetchEvents() async {
    if (_userId == null) return;

    final snapshot = await _eventsRef.get();
    events.clear();
    events.addAll(
      snapshot.docs.map((doc) => CalendarEvent.fromMap(doc.data())),
    );
    notifyListeners();
  }

  Future<void> addEvent(CalendarEvent event) async {
    if (_userId == null) return;
    await _eventsRef.doc(event.id).set(event.toMap());
    await fetchEvents();
  }

  Future<void> updateEvent(CalendarEvent event) async {
    if (_userId == null) return;
    await _eventsRef.doc(event.id).set(event.toMap());
    await fetchEvents();
  }

  Future<void> deleteEvent(String eventId) async {
    if (_userId == null) return;
    await _eventsRef.doc(eventId).delete();
    await fetchEvents();
  }

  // ─── Helpers ───

  CalendarEvent? getMostUrgentEvent() {
    final now = DateTime.now();
    final upcomingEvents = events
        .where((event) => !event.date.isBefore(DateTime(now.year, now.month, now.day)))
        .toList();
    if (upcomingEvents.isEmpty) return null;
    upcomingEvents.sort((a, b) => a.date.compareTo(b.date));
    return upcomingEvents.first;
  }
}
