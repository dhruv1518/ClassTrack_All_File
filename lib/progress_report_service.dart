import 'package:cloud_firestore/cloud_firestore.dart';

class ProgressReportService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Key = userId (best from Firebase Auth, for now using email as ID)
  Future<Map<String, int>> fetchOrInitToday(String userId) async {
    final today = DateTime.now();
    final dateStr = "${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}";
    final docRef = _db.collection("users").doc(userId).collection("progress").doc(dateStr);

    final snap = await docRef.get();
    if (snap.exists) return Map<String, int>.from(snap.data()! as Map);

    Map<String, int> zeroData = {
      "completedTasks": 0,
      "overdueTasks": 0,
      "upcomingEvents": 0,
      "pomodoroSessions": 0,
    };
    await docRef.set(zeroData);
    return zeroData;
  }

  Future<void> setProgressValue(String userId, String field, int value) async {
    final today = DateTime.now();
    final dateStr = "${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}";
    final docRef = _db.collection("users").doc(userId).collection("progress").doc(dateStr);
    await docRef.set({field: value}, SetOptions(merge: true));
  }

  Future<void> incrementPomodoro(String userId) async {
    final today = DateTime.now();
    final dateStr = "${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}";
    final docRef = _db.collection("users").doc(userId).collection("progress").doc(dateStr);
    await docRef.set({"pomodoroSessions": FieldValue.increment(1)}, SetOptions(merge: true));
  }
}
