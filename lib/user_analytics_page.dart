import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import 'analytics_service.dart';

// Accent colors preserved for both themes
const _kGreen = Color(0xFF2A9D8F);
const _kAmber = Color(0xFFE9C46A);
const _kRed = Color(0xFFE76F51);

class UserAnalyticsPage extends StatelessWidget {
  final String userId;
  final Map<String, dynamic> userData;
  const UserAnalyticsPage({
    Key? key,
    required this.userId,
    required this.userData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tp = Provider.of<ThemeProvider>(context);
    return Scaffold(
      backgroundColor: tp.scaffoldBg,
      appBar: AppBar(
        backgroundColor: tp.appBarBg,
        elevation: 0,
        title: const Text(
          "Student Analytics",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          final liveData =
              snapshot.data?.data() as Map<String, dynamic>? ?? userData;
          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              _buildProfileHeader(tp, liveData),
              const SizedBox(height: 20),
              _buildEngagementScoreCard(tp, liveData),
              const SizedBox(height: 20),
              _buildStatsGrid(tp, liveData),
              const SizedBox(height: 20),
              _build7DayActivity(tp),
              const SizedBox(height: 24),
              _buildPrivacyNotice(tp),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(ThemeProvider tp, Map<String, dynamic> data) {
    final name = data['name'] ?? 'Unknown';
    final email = data['email'] ?? '';
    final enrollment = data['enrollment'] ?? 'N/A';
    final status = AnalyticsService.activityStatus(data['lastActiveAt']);
    Color badgeColor;
    if (status == 'Active Today') {
      badgeColor = _kGreen;
    } else if (status == 'Active This Week') {
      badgeColor = _kAmber;
    } else {
      badgeColor = _kRed;
    }

    return Card(
      color: tp.cardBg,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: tp.appBarBg,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: tp.primaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: TextStyle(fontSize: 13, color: tp.secondaryText),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Enrollment: $enrollment',
                    style: TextStyle(fontSize: 12, color: tp.secondaryText),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: badgeColor, width: 1),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: badgeColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEngagementScoreCard(
    ThemeProvider tp,
    Map<String, dynamic> data,
  ) {
    final score = AnalyticsService.computeEngagementScore(data);
    final label = AnalyticsService.engagementLabel(score);
    final streak = (data['currentStreak'] as int?) ?? 0;
    Color scoreColor;
    if (score >= 80) {
      scoreColor = _kGreen;
    } else if (score >= 60) {
      scoreColor = const Color(0xFF457B9D);
    } else if (score >= 35) {
      scoreColor = _kAmber;
    } else {
      scoreColor = _kRed;
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [tp.appBarBg, tp.secondaryText],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 100,
              height: 100,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: CircularProgressIndicator(
                      value: score / 100,
                      strokeWidth: 10,
                      backgroundColor: Colors.white24,
                      valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$score',
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        '/100',
                        style: TextStyle(fontSize: 11, color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 22),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Engagement Score',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: scoreColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.local_fire_department,
                        color: Colors.orangeAccent,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$streak day streak',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(ThemeProvider tp, Map<String, dynamic> data) {
    final logins = (data['totalLogins'] as int?) ?? 0;
    final tasks = (data['totalTasksCompleted'] as int?) ?? 0;
    final notes = (data['totalNotesCreated'] as int?) ?? 0;
    final pomodoro = (data['totalPomodoroSessions'] as int?) ?? 0;
    final streak = (data['currentStreak'] as int?) ?? 0;
    final accountAge = _computeAccountAge(data['createdAt']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Activity Overview',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: tp.primaryText,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.95,
          children: [
            _statTile(
              tp,
              Icons.login_rounded,
              '$logins',
              'Logins',
              tp.appBarBg,
            ),
            _statTile(
              tp,
              Icons.task_alt_rounded,
              '$tasks',
              'Tasks Done',
              _kGreen,
            ),
            _statTile(
              tp,
              Icons.note_add_rounded,
              '$notes',
              'Notes',
              const Color(0xFF457B9D),
            ),
            _statTile(
              tp,
              Icons.timer_rounded,
              '$pomodoro',
              'Pomodoro',
              _kAmber,
            ),
            _statTile(
              tp,
              Icons.local_fire_department,
              '$streak',
              'Streak',
              _kRed,
            ),
            _statTile(
              tp,
              Icons.calendar_month,
              accountAge,
              'Account Age',
              tp.secondaryText,
            ),
          ],
        ),
      ],
    );
  }

  Widget _statTile(
    ThemeProvider tp,
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: tp.secondaryText),
          ),
        ],
      ),
    );
  }

  String _computeAccountAge(dynamic createdAt) {
    if (createdAt == null || createdAt is! Timestamp) return 'N/A';
    final days = DateTime.now().difference(createdAt.toDate()).inDays;
    if (days < 30) return '${days}d';
    if (days < 365) return '${(days / 30).floor()}mo';
    return '${(days / 365).floor()}y';
  }

  Widget _build7DayActivity(ThemeProvider tp) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: AnalyticsService.fetch7DayProgress(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          );
        final days = snapshot.data!;
        final maxActivity = days.fold<int>(0, (max, d) {
          final total =
              ((d['completedTasks'] as int?) ?? 0) +
              ((d['pomodoroSessions'] as int?) ?? 0);
          return total > max ? total : max;
        });
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '7-Day Activity',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: tp.primaryText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tasks completed + Pomodoro sessions per day',
              style: TextStyle(fontSize: 12, color: tp.secondaryText),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: days.map((d) {
                final date = d['date'] as DateTime;
                final tasks = (d['completedTasks'] as int?) ?? 0;
                final pomo = (d['pomodoroSessions'] as int?) ?? 0;
                final total = tasks + pomo;
                final fraction = maxActivity > 0 ? total / maxActivity : 0.0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$total',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: tp.primaryText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          height: 10 + (fraction * 80),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _kGreen.withOpacity(0.3 + fraction * 0.7),
                                _kGreen,
                              ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          DateFormat.E().format(date),
                          style: TextStyle(
                            fontSize: 11,
                            color: _isToday(date)
                                ? tp.primaryText
                                : tp.secondaryText,
                            fontWeight: _isToday(date)
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.day == now.day && d.month == now.month && d.year == now.year;
  }

  Widget _buildPrivacyNotice(ThemeProvider tp) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tp.tanColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tp.tanColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.shield_outlined, color: tp.secondaryText, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Analytics show engagement metrics only. Student content (notes, tasks, calendar) is private and not visible to admin.',
              style: TextStyle(fontSize: 11, color: tp.secondaryText),
            ),
          ),
        ],
      ),
    );
  }
}
