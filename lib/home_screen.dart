// lib/home_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:badges/badges.dart' as badges;
import 'package:cloud_firestore/cloud_firestore.dart';

import 'progress_report_service.dart';
import 'pomodoro_page.dart';
import 'todo_list_page.dart';
import 'categories_page.dart';
import 'calendar_page.dart';
import 'calendar_service.dart';
import 'todo_service.dart';
import 'account_page.dart';
import 'study_material_page.dart';
import 'exam_planner.dart';

// 🎨 Palette
const kDarkBlue = Color(0xFF1B3C53);
const kMedBlue = Color(0xFF456882);
const kTan = Color(0xFFD2C1B6);
const kCream = Color(0xFFF9F3EF);
const kOffWhite = Color(0xFFFAF5F1);

class HomeScreen extends StatefulWidget {
  final String name;
  final String enrollment;
  final String email;

  const HomeScreen({
    super.key,
    required this.name,
    required this.enrollment,
    required this.email,
  });

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final CalendarService _calendarService = CalendarService();
  final ToDoService _toDoService = ToDoService();
  final ProgressReportService _progressService = ProgressReportService();

  int _currentIndex = 0;
  int _alertCount = 0;

  Map<String, int> _progress = {
    "completedTasks": 0,
    "overdueTasks": 0,
    "upcomingEvents": 0,
    "pomodoroSessions": 0,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncDailyProgress();
      _updateAlertCount();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() {
        _updateAlertCount();
        _syncDailyProgress();
      });
    }
  }

  void _syncDailyProgress() async {
    String userId = widget.email;
    final now = DateTime.now();

    final completed = _toDoService.tasks.where((t) =>
    t.isDone && _isToday(t.dueDate)).length;

    final overdue = _toDoService.tasks.where((t) =>
    !t.isDone && t.dueDate.isBefore(now)).length;

    final upcoming = _calendarService.events.where((e) =>
    e.date.isAfter(now) &&
        e.date.isBefore(now.add(const Duration(days: 7)))).length;

    await _progressService.setProgressValue(userId, "completedTasks", completed);
    await _progressService.setProgressValue(userId, "overdueTasks", overdue);
    await _progressService.setProgressValue(userId, "upcomingEvents", upcoming);

    final dailyMap = await _progressService.fetchOrInitToday(userId);

    setState(() => _progress = dailyMap);
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.day == now.day && d.month == now.month && d.year == now.year;
  }

  void _onPomodoroComplete() async {
    String userId = widget.email;
    await _progressService.incrementPomodoro(userId);

    final dailyMap = await _progressService.fetchOrInitToday(userId);
    setState(() => _progress = dailyMap);
  }

  // 🔔 ALERT COUNT
  void _updateAlertCount() {
    final now = DateTime.now();
    final soon = now.add(const Duration(days: 2));

    final urgentEvents = _calendarService.events.where((event) =>
    event.date.isAfter(now.subtract(const Duration(days: 1))) &&
        event.date.isBefore(soon) &&
        event.hasReminder).toList();

    final overdueTasks = _toDoService.tasks.where(
            (task) => !task.isDone && task.dueDate.isBefore(now)).toList();

    setState(() => _alertCount = urgentEvents.length + overdueTasks.length);
  }

  // ALERT POPUP
  void _showAlertsDialog() {
    final now = DateTime.now();
    final soon = now.add(const Duration(days: 2));

    final urgentEvents = _calendarService.events.where((e) =>
    e.date.isAfter(now.subtract(const Duration(days: 1))) &&
        e.date.isBefore(soon) &&
        e.hasReminder).toList();

    final overdueTasks = _toDoService.tasks.where(
            (t) => !t.isDone && t.dueDate.isBefore(now)).toList();

    if (urgentEvents.isEmpty && overdueTasks.isEmpty) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("✅ All Clear!"),
          content: const Text("No upcoming or overdue items."),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("⚠️ You have ${urgentEvents.length + overdueTasks.length} alerts"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (urgentEvents.isNotEmpty) ...[
                const Text("Upcoming Events:", style: TextStyle(fontWeight: FontWeight.bold)),
                ...urgentEvents.map((ev) =>
                    Text("• ${ev.title} on ${DateFormat.yMMMd().format(ev.date)}")),
                const SizedBox(height: 10),
              ],
              if (overdueTasks.isNotEmpty) ...[
                const Text("Overdue Tasks:", style: TextStyle(fontWeight: FontWeight.bold)),
                ...overdueTasks.map((t) =>
                    Text("• ${t.title} (Due: ${DateFormat.yMMMd().format(t.dueDate)})")),
              ]
            ],
          ),
        ),
      ),
    );
  }

  // ======================== NEW: UNREAD ADMIN MESSAGE COUNTER ========================
  Stream<int> _unreadAdminCount() {
    return FirebaseFirestore.instance
        .collection('communications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      int unread = 0;

      for (var doc in snapshot.docs) {
        final readDoc = await FirebaseFirestore.instance
            .collection('user_reads')
            .doc(widget.email)
            .collection('communications')
            .doc(doc.id)
            .get();

        if (!readDoc.exists) unread++;
      }
      return unread;
    });
  }
  // ===============================================================================

  // Mark admin messages as read
  void _markAdminMessagesAsRead(List<QueryDocumentSnapshot> docs) async {
    for (var doc in docs) {
      await FirebaseFirestore.instance
          .collection('user_reads')
          .doc(widget.email)
          .collection('communications')
          .doc(doc.id)
          .set({'read': true});
    }
  }

  // POPUP FOR ADMIN MESSAGES
  void _showAdminMessagesPopup() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 520),
            child: Column(
              children: [
                // header
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.campaign_outlined, color: kDarkBlue),
                      const SizedBox(width: 6),
                      const Text("Admin Messages",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kDarkBlue)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      )
                    ],
                  ),
                ),
                const Divider(height: 1),

                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('communications')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final docs = snapshot.data!.docs;

                      // → Mark as read
                      _markAdminMessagesAsRead(docs);

                      if (docs.isEmpty) {
                        return const Center(child: Text("No admin messages"));
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: docs.length,
                        itemBuilder: (_, i) {
                          final data = docs[i].data() as Map<String, dynamic>;

                          final title = data['title'] ?? "";
                          final message = data['message'] ?? "";
                          final ts = (data['timestamp'] as Timestamp?)?.toDate();
                          final time = ts != null
                              ? DateFormat('dd MMM yyyy • hh:mm a').format(ts)
                              : "";

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [
                                BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                    offset: Offset(0, 2))
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(title,
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: kDarkBlue)),
                                const SizedBox(height: 6),
                                Text(message,
                                    style:
                                    const TextStyle(fontSize: 14, color: kMedBlue)),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: Text(time,
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[600])),
                                )
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Close"))
              ],
            ),
          ),
        );
      },
    );
  }

  // bottom navigation handler
  void _onNavTapped(int index) {
    if (index == 3) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => PomodoroPage(onSessionComplete: _onPomodoroComplete)));
    } else if (index == 2) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => AccountPage(
                name: widget.name,
                enrollment: widget.enrollment,
                email: widget.email,
              )));
    } else if (index == 1) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => ExamPlannerPage()));
    } else {
      setState(() => _currentIndex = index);
    }
  }

  // profile tap
  void _onProfileTapped() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => AccountPage(
              name: widget.name,
              enrollment: widget.enrollment,
              email: widget.email,
            )));
  }

  @override
  Widget build(BuildContext context) {
    final urgentEvent = _calendarService.getMostUrgentEvent();

    return Scaffold(
      backgroundColor: kOffWhite,
      appBar: AppBar(
        backgroundColor: kOffWhite,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Hello, ${widget.name} 👋",
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: kDarkBlue)),
            const SizedBox(height: 2),
            const Text("Stay on top of your day",
                style: TextStyle(color: kMedBlue, fontSize: 13)),
          ],
        ),
        actions: [
          // ====================== NEW BADGE ADMIN ICON ======================
          StreamBuilder<int>(
            stream: _unreadAdminCount(),
            builder: (context, snapshot) {
              final unread = snapshot.data ?? 0;

              return badges.Badge(
                showBadge: unread > 0,
                badgeStyle: badges.BadgeStyle(badgeColor: kDarkBlue),
                badgeContent: Text(
                  unread.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
                child: IconButton(
                  onPressed: _showAdminMessagesPopup,
                  icon: const Icon(Icons.campaign_outlined,
                      color: kDarkBlue, size: 26),
                ),
              );
            },
          ),
          // ==================================================================

          IconButton(
            onPressed: _showAlertsDialog,
            icon: badges.Badge(
              showBadge: _alertCount > 0,
              badgeStyle: badges.BadgeStyle(badgeColor: kDarkBlue),
              badgeContent: Text(
                '$_alertCount',
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
              child: const Icon(Icons.notifications, color: kDarkBlue),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: GestureDetector(
              onTap: _onProfileTapped,
              child: const CircleAvatar(
                radius: 18,
                backgroundImage: AssetImage('images/profile2.jpeg'),
              ),
            ),
          ),
        ],
      ),

      // BODY
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // SEARCH BAR
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 3))
                ]),
            child: const TextField(
              decoration: InputDecoration(
                  hintText: "Search...",
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: kMedBlue)),
            ),
          ),

          const SizedBox(height: 24),

          // SHORTCUTS
          SizedBox(
            height: 90,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildShortcut(Icons.checklist_rtl, "To-Do",
                        () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => ToDoListPage()))),
                _buildShortcut(Icons.note_alt_outlined, "Notes",
                        () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => CategoriesPage()))),
                _buildShortcut(Icons.calendar_today, "Calendar",
                        () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => CalendarPage()))),
                _buildShortcut(Icons.menu_book_outlined, "Material",
                        () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => StudyMaterialPage()))),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // NEXT EVENT
          if (urgentEvent != null) ...[
            Text("Next Event",
                style: Theme.of(context)
                    .textTheme
                    .titleMedium!
                    .copyWith(fontWeight: FontWeight.bold, color: kDarkBlue)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [kMedBlue, kDarkBlue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        offset: Offset(0, 3))
                  ]),
              child: Row(
                children: [
                  const Icon(Icons.event, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(urgentEvent.title,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        Text(
                            DateFormat.yMMMMd().format(urgentEvent.date),
                            style: const TextStyle(color: kCream)),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // PROGRESS REPORT
          Text("Personal Progress Report",
              style: Theme.of(context)
                  .textTheme
                  .titleMedium!
                  .copyWith(fontWeight: FontWeight.bold, color: kDarkBlue)),
          const SizedBox(height: 16),

          _buildAnalyticsCard(
              label: "Tasks Completed Today",
              count: _progress["completedTasks"] ?? 0,
              color: kTan,
              icon: Icons.check_circle_outline),

          const SizedBox(height: 12),

          _buildAnalyticsCard(
              label: "Overdue Tasks",
              count: _progress["overdueTasks"] ?? 0,
              color: kDarkBlue,
              icon: Icons.error_outline),

          const SizedBox(height: 12),

          _buildAnalyticsCard(
              label: "Upcoming Events (7 days)",
              count: _progress["upcomingEvents"] ?? 0,
              color: kMedBlue,
              icon: Icons.event_available),

          const SizedBox(height: 12),

          _buildAnalyticsCard(
              label: "Pomodoro Sessions",
              count: _progress["pomodoroSessions"] ?? 0,
              color: kCream,
              icon: Icons.timer),

          const SizedBox(height: 24),

          // QUOTE
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2))
                ]),
            child: Row(
              children: [
                Icon(Icons.emoji_emotions, color: kMedBlue, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                    child: Text(
                        "\"Stay productive, one step at a time 💡\"",
                        style: TextStyle(
                            color: kMedBlue,
                            fontStyle: FontStyle.italic,
                            fontSize: 13)))
              ],
            ),
          )
        ],
      ),

      // BOTTOM NAVIGATION
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  offset: Offset(0, 3))
            ]),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          selectedItemColor: kDarkBlue,
          unselectedItemColor: kMedBlue,
          elevation: 0,
          currentIndex: _currentIndex > 2 ? 0 : _currentIndex,
          onTap: _onNavTapped,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(icon: Icon(Icons.school), label: "Exam Planner"),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
            BottomNavigationBarItem(icon: Icon(Icons.timer), label: "Pomodoro"),
          ],
        ),
      ),
    );
  }

  // SHORTCUT BUTTON
  Widget _buildShortcut(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [kTan, kCream],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black12,
                  blurRadius: 5,
                  offset: Offset(0, 3))
            ]),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: kDarkBlue, size: 24),
            const SizedBox(height: 6),
            Text(label,
                style: const TextStyle(fontSize: 12, color: kDarkBlue)),
          ],
        ),
      ),
    );
  }

  // ANALYTICS CARD
  Widget _buildAnalyticsCard({
    required String label,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 3))
          ]),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration:
            BoxDecoration(color: color, borderRadius: BorderRadius.circular(32)),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    color: kDarkBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          ),
          Text(count.toString(),
              style: const TextStyle(
                  color: kDarkBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 24)),
        ],
      ),
    );
  }
}
