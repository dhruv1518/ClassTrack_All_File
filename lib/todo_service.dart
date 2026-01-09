import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  final String id;
  String title;
  bool isDone;
  DateTime dueDate;

  Task({
    required this.id,
    required this.title,
    required this.isDone,
    required this.dueDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'isDone': isDone,
      'dueDate': dueDate.toIso8601String(),
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      isDone: map['isDone'],
      dueDate: DateTime.parse(map['dueDate']),
    );
  }
}

class ToDoService extends ChangeNotifier {
  static final ToDoService _instance = ToDoService._internal();
  factory ToDoService() => _instance;
  ToDoService._internal();

  List<Task> tasks = [];
  String? _userId;

  // Call this after login/signup
  void setUser(String userId) {
    _userId = userId;
    fetchTasks();
  }

  // Load tasks for this user from Firestore
  Future<void> fetchTasks() async {
    if (_userId == null) return;
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .collection('tasks')
        .get();

    tasks = snapshot.docs.map((doc) => Task.fromMap(doc.data())).toList();
    notifyListeners();
  }

  // Add new Task - MODIFIED to always fetch after add
  Future<void> addTask(Task task) async {
    if (_userId == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .collection('tasks')
        .doc(task.id)
        .set(task.toMap());

    // Instead of just local add, always fetch from Firestore to ensure up to date
    await fetchTasks(); // <--- THIS LINE fixes your problem!
  }

  // Update a Task (for marking as done, etc.)
  Future<void> updateTask(Task newTask) async {
    if (_userId == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .collection('tasks')
        .doc(newTask.id)
        .set(newTask.toMap());

    await fetchTasks();
  }

  // Remove a Task - always refetch after delete
  Future<void> deleteTask(Task task) async {
    if (_userId == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .collection('tasks')
        .doc(task.id)
        .delete();

    await fetchTasks();
  }
}
