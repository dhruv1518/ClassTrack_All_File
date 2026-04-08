// lib/analytics_service.dart
// Privacy-balanced analytics: tracks only aggregate counters, never personal content.

import 'package:cloud_firestore/cloud_firestore.dart';

class AnalyticsService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Reference to a user document
  static DocumentReference _userDoc(String uid) =>
      _db.collection('users').doc(uid);

  // ────────────────────────────────────────────
  //  STREAK HELPER (private)
  // ────────────────────────────────────────────

  static String _todayStr() {
    final now = DateTime.now();
    return "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}";
  }

  static String _yesterdayStr() {
    final y = DateTime.now().subtract(const Duration(days: 1));
    return "${y.year}${y.month.toString().padLeft(2, '0')}${y.day.toString().padLeft(2, '0')}";
  }

  /// Updates the streak on the user document.
  /// If lastStreakDate == today → no change.
  /// If lastStreakDate == yesterday → increment streak.
  /// Otherwise → reset streak to 1.
  static Future<void> _updateStreak(String uid) async {
    final today = _todayStr();
    final yesterday = _yesterdayStr();

    final doc = await _userDoc(uid).get();
    final data = doc.data() as Map<String, dynamic>? ?? {};

    final lastDate = data['lastStreakDate'] as String? ?? '';
    final currentStreak = data['currentStreak'] as int? ?? 0;

    if (lastDate == today) {
      // Already counted today → no change
      return;
    }

    int newStreak;
    if (lastDate == yesterday) {
      newStreak = currentStreak + 1;
    } else {
      newStreak = 1;
    }

    await _userDoc(uid).set({
      'currentStreak': newStreak,
      'lastStreakDate': today,
    }, SetOptions(merge: true));
  }

  // ────────────────────────────────────────────
  //  PUBLIC TRACKING METHODS
  // ────────────────────────────────────────────

  /// Track login: increment totalLogins, update lastActiveAt, update streak.
  static Future<void> trackLogin(String uid) async {
    await _userDoc(uid).set({
      'totalLogins': FieldValue.increment(1),
      'lastActiveAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _updateStreak(uid);
  }

  /// Track task completed: increment totalTasksCompleted, update streak.
  static Future<void> trackTaskCompleted(String uid) async {
    await _userDoc(uid).set({
      'totalTasksCompleted': FieldValue.increment(1),
      'lastActiveAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _updateStreak(uid);
  }

  /// Track note created: increment totalNotesCreated, update streak.
  static Future<void> trackNoteCreated(String uid) async {
    await _userDoc(uid).set({
      'totalNotesCreated': FieldValue.increment(1),
      'lastActiveAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _updateStreak(uid);
  }

  /// Track pomodoro session completed: increment totalPomodoroSessions, update streak.
  static Future<void> trackPomodoroCompleted(String uid) async {
    await _userDoc(uid).set({
      'totalPomodoroSessions': FieldValue.increment(1),
      'lastActiveAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _updateStreak(uid);
  }

  // ────────────────────────────────────────────
  //  ENGAGEMENT SCORE (read-only, computed)
  // ────────────────────────────────────────────

  /// Computes engagement score (0-100) from aggregate counters.
  /// Weights: logins×2, tasks×3, notes×3, pomodoro×4, streak×5.
  static int computeEngagementScore(Map<String, dynamic> userData) {
    final logins = (userData['totalLogins'] as int?) ?? 0;
    final tasks = (userData['totalTasksCompleted'] as int?) ?? 0;
    final notes = (userData['totalNotesCreated'] as int?) ?? 0;
    final pomodoro = (userData['totalPomodoroSessions'] as int?) ?? 0;
    final streak = (userData['currentStreak'] as int?) ?? 0;

    final raw = logins * 2 + tasks * 3 + notes * 3 + pomodoro * 4 + streak * 5;
    return raw > 100 ? 100 : raw;
  }

  /// Returns a label for the engagement score.
  static String engagementLabel(int score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 35) return 'Average';
    return 'Needs Attention';
  }

  /// Returns an activity status based on lastActiveAt.
  static String activityStatus(dynamic lastActiveAt) {
    if (lastActiveAt == null || lastActiveAt is! Timestamp) {
      return 'Never Active';
    }

    final lastActive = lastActiveAt.toDate();
    final now = DateTime.now();
    final diff = now.difference(lastActive).inDays;

    if (diff == 0) return 'Active Today';
    if (diff <= 7) return 'Active This Week';
    return 'Inactive (${diff}d)';
  }

  /// Fetches the last 7 days of progress data for a user.
  static Future<List<Map<String, dynamic>>> fetch7DayProgress(
    String uid,
  ) async {
    final List<Map<String, dynamic>> result = [];
    final now = DateTime.now();

    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dateStr =
          "${day.year}${day.month.toString().padLeft(2, '0')}${day.day.toString().padLeft(2, '0')}";

      final doc = await _db
          .collection('users')
          .doc(uid)
          .collection('progress')
          .doc(dateStr)
          .get();

      result.add({
        'date': day,
        'completedTasks': doc.data()?['completedTasks'] ?? 0,
        'pomodoroSessions': doc.data()?['pomodoroSessions'] ?? 0,
      });
    }

    return result;
  }
}
