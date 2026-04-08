import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore-backed service for persisting exam planner data.
/// Stores subjects and generated plan items per user.
class ExamPlannerService {
  static final ExamPlannerService _instance = ExamPlannerService._internal();
  factory ExamPlannerService() => _instance;
  ExamPlannerService._internal();

  String? _userId;

  CollectionReference<Map<String, dynamic>> get _subjectsRef =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('examSubjects');

  CollectionReference<Map<String, dynamic>> get _planRef =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('examPlanItems');

  void setUser(String uid) {
    _userId = uid;
  }

  // ─── Subjects ───

  Future<List<Map<String, dynamic>>> fetchSubjects() async {
    if (_userId == null) return [];
    final snap = await _subjectsRef.orderBy('createdAt').get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  Future<void> saveSubject(Map<String, dynamic> data) async {
    if (_userId == null) return;
    final id = data['id'] as String;
    await _subjectsRef.doc(id).set(data);
  }

  Future<void> deleteSubject(String id) async {
    if (_userId == null) return;
    await _subjectsRef.doc(id).delete();
  }

  Future<void> clearSubjects() async {
    if (_userId == null) return;
    final snap = await _subjectsRef.get();
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // ─── Plan Items ───

  Future<List<Map<String, dynamic>>> fetchPlanItems() async {
    if (_userId == null) return [];
    final snap = await _planRef.get();
    return snap.docs.map((d) => d.data()).toList();
  }

  Future<void> savePlanItems(Map<DateTime, List<Map<String, dynamic>>> plan) async {
    if (_userId == null) return;

    // Clear old plan
    final oldSnap = await _planRef.get();
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in oldSnap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();

    // Save new plan — one document per date
    for (final entry in plan.entries) {
      final dateKey = entry.key.toIso8601String().split('T')[0]; // "2025-03-15"
      await _planRef.doc(dateKey).set({
        'date': entry.key.toIso8601String(),
        'items': entry.value,
      });
    }
  }

  Future<void> clearPlan() async {
    if (_userId == null) return;
    final snap = await _planRef.get();
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
