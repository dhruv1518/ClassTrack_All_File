// lib/notes_service.dart
import 'package:flutter/material.dart';

// --- Data Models ---
class Note {
  final String id;
  String title;
  String content;
  DateTime lastModified;

  Note({
    required this.title,
    required this.content,
    required this.lastModified,
  }) : id = UniqueKey().toString();
}

class Category {
  final String id;
  String name;
  final List<Note> notes;

  Category({required this.name, List<Note>? notes})
      : id = UniqueKey().toString(),
        notes = notes ?? [];
}

// --- In-Memory Data Service ---
// This class will hold the list of categories while the app is running.
class NotesService {
  // A singleton pattern ensures we use the same instance across the app.
  static final NotesService _instance = NotesService._internal();
  factory NotesService() => _instance;
  NotesService._internal();

  // The main list that stores all categories.
  final List<Category> categories=[];
}
