// lib/notes_service.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- Data Models ---

class Note {
  final String id;
  String title;
  String content;
  DateTime lastModified;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.lastModified,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'lastModified': lastModified.toIso8601String(),
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      lastModified: DateTime.parse(map['lastModified']),
    );
  }
}

class Category {
  final String id;
  String name;
  List<Note> notes;

  Category({required this.id, required this.name, List<Note>? notes})
    : notes = notes ?? [];

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name};
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(id: map['id'] ?? '', name: map['name'] ?? '');
  }
}

// --- Firestore-Backed Data Service ---

class NotesService extends ChangeNotifier {
  // Singleton instance
  static final NotesService _instance = NotesService._internal();
  factory NotesService() => _instance;
  NotesService._internal();

  final List<Category> categories = [];
  String? _userId;

  // Reference helpers
  CollectionReference<Map<String, dynamic>> get _categoriesRef =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('noteCategories');

  CollectionReference<Map<String, dynamic>> _notesRef(String categoryId) =>
      _categoriesRef.doc(categoryId).collection('notes');

  // --- Initialization ---

  /// Call this after login/signup to load the user's data.
  void setUser(String userId) {
    _userId = userId;
    fetchCategories();
  }

  /// Auto-detect the current user (convenience method).
  void initWithCurrentUser() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setUser(user.uid);
    }
  }

  // --- Fetch ---

  Future<void> fetchCategories() async {
    if (_userId == null) return;

    final catSnapshot = await _categoriesRef.get();

    final List<Category> loaded = [];
    for (final catDoc in catSnapshot.docs) {
      final category = Category.fromMap(catDoc.data());

      // Fetch notes subcollection for each category
      final notesSnapshot = await _notesRef(category.id).get();
      category.notes = notesSnapshot.docs
          .map((d) => Note.fromMap(d.data()))
          .toList();

      // Sort notes by last modified (newest first)
      category.notes.sort((a, b) => b.lastModified.compareTo(a.lastModified));

      loaded.add(category);
    }

    categories.clear();
    categories.addAll(loaded);
    notifyListeners();
  }

  // --- Category CRUD ---

  Future<void> addCategory(String name) async {
    if (_userId == null) return;

    // Create a new doc ref to get a Firestore-generated ID
    final docRef = _categoriesRef.doc();
    final category = Category(id: docRef.id, name: name);

    await docRef.set(category.toMap());
    await fetchCategories();
  }

  Future<void> deleteCategory(String categoryId) async {
    if (_userId == null) return;

    // Delete all notes inside the category first
    final notesSnapshot = await _notesRef(categoryId).get();
    for (final doc in notesSnapshot.docs) {
      await doc.reference.delete();
    }

    // Delete the category document
    await _categoriesRef.doc(categoryId).delete();
    await fetchCategories();
  }

  // --- Note CRUD ---

  Future<Note> addNote(String categoryId) async {
    final docRef = _notesRef(categoryId).doc();
    final note = Note(
      id: docRef.id,
      title: '',
      content: '',
      lastModified: DateTime.now(),
    );
    await docRef.set(note.toMap());
    await fetchCategories();
    return note;
  }

  Future<void> updateNote(String categoryId, Note note) async {
    if (_userId == null) return;

    note.lastModified = DateTime.now();
    await _notesRef(categoryId).doc(note.id).set(note.toMap());
    await fetchCategories();
  }

  Future<void> deleteNote(String categoryId, String noteId) async {
    if (_userId == null) return;

    await _notesRef(categoryId).doc(noteId).delete();
    await fetchCategories();
  }
}
