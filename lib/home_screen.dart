// lib/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:badges/badges.dart' as badges;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';

import 'progress_report_service.dart';
import 'analytics_service.dart';
import 'pomodoro_page.dart';
import 'todo_list_page.dart';
import 'categories_page.dart';
import 'calendar_page.dart';
import 'calendar_service.dart';
import 'todo_service.dart';
import 'account_page.dart';
import 'study_material_page.dart';
import 'exam_planner.dart';

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
  bool _hasMarkedMessagesAsRead = false;
  int _lastCompletionValue = PomodoroTimerController.completionNotifier.value;

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
    // Reset timer for this student session — prevents shared timer across students
    PomodoroTimerController.resetForNewUser();
    _lastCompletionValue = PomodoroTimerController.completionNotifier.value;
    // Listen for pomodoro timer completion globally
    PomodoroTimerController.completionNotifier.addListener(_onPomodoroTimerDone);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ThemeProvider>(context, listen: false).setPanel('student');
      _syncDailyProgress();
      _updateAlertCount();
    });
  }

  @override
  void dispose() {
    PomodoroTimerController.completionNotifier.removeListener(_onPomodoroTimerDone);
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

  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? widget.email;

  void _syncDailyProgress() async {
    final userId = _userId;
    final now = DateTime.now();

    final completed = _toDoService.tasks
        .where((t) => t.isDone && _isToday(t.dueDate))
        .length;

    final overdue = _toDoService.tasks
        .where((t) => !t.isDone && t.dueDate.isBefore(now))
        .length;

    final upcoming = _calendarService.events
        .where(
          (e) =>
              e.date.isAfter(now) &&
              e.date.isBefore(now.add(const Duration(days: 7))),
        )
        .length;

    await _progressService.setProgressValue(
      userId,
      "completedTasks",
      completed,
    );
    await _progressService.setProgressValue(userId, "overdueTasks", overdue);
    await _progressService.setProgressValue(userId, "upcomingEvents", upcoming);

    final dailyMap = await _progressService.fetchOrInitToday(userId);

    if (!mounted) return;
    setState(() => _progress = dailyMap);
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.day == now.day && d.month == now.month && d.year == now.year;
  }

  /// Called when the Pomodoro timer completes from ANY page.
  void _onPomodoroTimerDone() {
    // Prevent duplicate handling
    final newVal = PomodoroTimerController.completionNotifier.value;
    if (newVal == _lastCompletionValue) return;
    _lastCompletionValue = newVal;

    // Track analytics
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      AnalyticsService.trackPomodoroCompleted(uid);
    }

    // Update progress
    _incrementPomodoroProgress();

    // Show break popup globally
    if (mounted) {
      final breakMinutes = PomodoroTimerController.recommendedBreakMinutes;
      final tp = Provider.of<ThemeProvider>(context, listen: false);
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          backgroundColor: tp.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            "✅ Session Complete!",
            style: TextStyle(color: tp.primaryText),
          ),
          content: Text(
            "Great work! Take a $breakMinutes minute break.",
            style: TextStyle(color: tp.secondaryText),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: tp.accentTeal,
              ),
              onPressed: () {
                Navigator.pop(context);
                PomodoroTimerController.reset();
              },
              child: const Text(
                "OK",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }
  }

  void _incrementPomodoroProgress() async {
    final userId = _userId;
    await _progressService.incrementPomodoro(userId);

    final dailyMap = await _progressService.fetchOrInitToday(userId);
    if (!mounted) return;
    setState(() => _progress = dailyMap);
  }

  // 🔔 ALERT COUNT
  void _updateAlertCount() {
    final now = DateTime.now();
    final soon = now.add(const Duration(days: 2));

    final urgentEvents = _calendarService.events
        .where(
          (event) =>
              event.date.isAfter(now.subtract(const Duration(days: 1))) &&
              event.date.isBefore(soon) &&
              event.hasReminder,
        )
        .toList();

    final overdueTasks = _toDoService.tasks
        .where((task) => !task.isDone && task.dueDate.isBefore(now))
        .toList();

    setState(() => _alertCount = urgentEvents.length + overdueTasks.length);
  }

  // ALERT POPUP
  void _showAlertsDialog() {
    final now = DateTime.now();
    final soon = now.add(const Duration(days: 2));

    final urgentEvents = _calendarService.events
        .where(
          (e) =>
              e.date.isAfter(now.subtract(const Duration(days: 1))) &&
              e.date.isBefore(soon) &&
              e.hasReminder,
        )
        .toList();

    final overdueTasks = _toDoService.tasks
        .where((t) => !t.isDone && t.dueDate.isBefore(now))
        .toList();

    if (urgentEvents.isEmpty && overdueTasks.isEmpty) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text("✅ All Clear!"),
          content: const Text("No upcoming or overdue items."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "⚠️ You have ${urgentEvents.length + overdueTasks.length} alerts",
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (urgentEvents.isNotEmpty) ...[
                const Text(
                  "Upcoming Events:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...urgentEvents.map(
                  (ev) => Text(
                    "• ${ev.title} on ${DateFormat.yMMMd().format(ev.date)}",
                  ),
                ),
                const SizedBox(height: 10),
              ],
              if (overdueTasks.isNotEmpty) ...[
                const Text(
                  "Overdue Tasks:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...overdueTasks.map(
                  (t) => Text(
                    "• ${t.title} (Due: ${DateFormat.yMMMd().format(t.dueDate)})",
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ======================== UNREAD ADMIN MESSAGE COUNTER ========================
  Stream<int> _unreadAdminCount() {
    final userId = _userId;
    return FirebaseFirestore.instance
        .collection('communications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          if (snapshot.docs.isEmpty) return 0;

          // Batch read: get all read-receipts in one query instead of N+1
          final readSnapshot = await FirebaseFirestore.instance
              .collection('user_reads')
              .doc(userId)
              .collection('communications')
              .get();

          final readIds = readSnapshot.docs.map((d) => d.id).toSet();
          return snapshot.docs.where((doc) => !readIds.contains(doc.id)).length;
        });
  }
  // ===============================================================================

  // Mark admin messages as read — uses batch write for efficiency
  Future<void> _markAdminMessagesAsRead(
    List<QueryDocumentSnapshot> docs,
  ) async {
    final userId = _userId;
    final batch = FirebaseFirestore.instance.batch();
    for (var doc in docs) {
      final ref = FirebaseFirestore.instance
          .collection('user_reads')
          .doc(userId)
          .collection('communications')
          .doc(doc.id);
      batch.set(ref, {'read': true});
    }
    await batch.commit();
  }

  // POPUP FOR ADMIN MESSAGES
  void _showAdminMessagesPopup() {
    final tp = Provider.of<ThemeProvider>(context, listen: false);
    _hasMarkedMessagesAsRead = false; // reset on each popup open
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          backgroundColor: tp.cardBg,
          child: Container(
            constraints: const BoxConstraints(maxHeight: 520),
            child: Column(
              children: [
                // header
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.campaign_outlined, color: tp.primaryText),
                      const SizedBox(width: 6),
                      Text(
                        "Admin Messages",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: tp.primaryText,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(Icons.close, color: tp.iconColor),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: tp.dividerColor),

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

                      // Mark as read only once per popup open
                      if (!_hasMarkedMessagesAsRead && docs.isNotEmpty) {
                        _hasMarkedMessagesAsRead = true;
                        _markAdminMessagesAsRead(docs);
                      }

                      if (docs.isEmpty) {
                        return Center(
                          child: Text(
                            "No admin messages",
                            style: TextStyle(color: tp.secondaryText),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: docs.length,
                        itemBuilder: (_, i) {
                          final data = docs[i].data() as Map<String, dynamic>;

                          final title = data['title'] ?? "";
                          final message = data['message'] ?? "";
                          final ts = (data['timestamp'] as Timestamp?)
                              ?.toDate();
                          final time = ts != null
                              ? DateFormat('dd MMM yyyy • hh:mm a').format(ts)
                              : "";

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: tp.cardHighlight,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: tp.shadowColor,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: tp.primaryText,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  message,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: tp.secondaryText,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: Text(
                                    time,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: tp.inactiveColor,
                                    ),
                                  ),
                                ),
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
                  child: const Text("Close"),
                ),
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
          builder: (_) => const PomodoroPage(),
        ),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AccountPage(
            name: widget.name,
            enrollment: widget.enrollment,
            email: widget.email,
          ),
        ),
      );
    } else if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ExamPlannerPage()),
      );
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
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tp = Provider.of<ThemeProvider>(context);
    final urgentEvent = _calendarService.getMostUrgentEvent();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Exit ClassTrack?'),
            content: const Text('Are you sure you want to exit the app?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: tp.appBarBg),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Exit',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
        if (shouldExit == true) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: tp.scaffoldBg,
        appBar: AppBar(
          backgroundColor: tp.scaffoldBg,
          elevation: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Hello, ${widget.name} 👋",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: tp.primaryText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "Stay on top of your day",
                style: TextStyle(color: tp.secondaryText, fontSize: 13),
              ),
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
                  badgeStyle: badges.BadgeStyle(badgeColor: tp.primaryText),
                  badgeContent: Text(
                    unread.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                  child: IconButton(
                    onPressed: _showAdminMessagesPopup,
                    icon: Icon(
                      Icons.campaign_outlined,
                      color: tp.primaryText,
                      size: 26,
                    ),
                  ),
                );
              },
            ),

            // ==================================================================
            IconButton(
              onPressed: _showAlertsDialog,
              icon: badges.Badge(
                showBadge: _alertCount > 0,
                badgeStyle: badges.BadgeStyle(badgeColor: tp.primaryText),
                badgeContent: Text(
                  '$_alertCount',
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
                child: Icon(Icons.notifications, color: tp.primaryText),
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
            const SizedBox(height: 24),

            // SHORTCUTS
            SizedBox(
              height: 90,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildShortcut(
                    tp,
                    Icons.checklist_rtl,
                    "To-Do",
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ToDoListPage()),
                    ),
                  ),
                  _buildShortcut(
                    tp,
                    Icons.note_alt_outlined,
                    "Notes",
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => CategoriesPage()),
                    ),
                  ),
                  _buildShortcut(
                    tp,
                    Icons.calendar_today,
                    "Calendar",
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => CalendarPage()),
                    ),
                  ),
                  _buildShortcut(
                    tp,
                    Icons.menu_book_outlined,
                    "Material",
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => StudyMaterialPage()),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // NEXT EVENT
            if (urgentEvent != null) ...[
              Text(
                "Next Event",
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: tp.primaryText,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [tp.secondaryText, tp.appBarBg],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: tp.shadowColor,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            urgentEvent.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            DateFormat.yMMMMd().format(urgentEvent.date),
                            style: TextStyle(color: tp.creamColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // PROGRESS REPORT
            Text(
              "Personal Progress Report",
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.bold,
                color: tp.primaryText,
              ),
            ),
            const SizedBox(height: 16),

            _buildAnalyticsCard(
              tp: tp,
              label: "Tasks Completed Today",
              count: _progress["completedTasks"] ?? 0,
              color: tp.tanColor,
              icon: Icons.check_circle_outline,
            ),

            const SizedBox(height: 12),

            _buildAnalyticsCard(
              tp: tp,
              label: "Overdue Tasks",
              count: _progress["overdueTasks"] ?? 0,
              color: tp.appBarBg,
              icon: Icons.error_outline,
            ),

            const SizedBox(height: 12),

            _buildAnalyticsCard(
              tp: tp,
              label: "Upcoming Events (7 days)",
              count: _progress["upcomingEvents"] ?? 0,
              color: tp.secondaryText,
              icon: Icons.event_available,
            ),

            const SizedBox(height: 12),

            _buildAnalyticsCard(
              tp: tp,
              label: "Pomodoro Sessions",
              count: _progress["pomodoroSessions"] ?? 0,
              color: tp.creamColor,
              icon: Icons.timer,
            ),

            const SizedBox(height: 24),

            // QUOTE
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: tp.cardBg,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: tp.shadowColor,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.emoji_emotions, color: tp.secondaryText, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "\"Stay productive, one step at a time 💡\"",
                      style: TextStyle(
                        color: tp.secondaryText,
                        fontStyle: FontStyle.italic,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // BOTTOM NAVIGATION
        bottomNavigationBar: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: tp.bottomNavBg,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: tp.shadowColor,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            selectedItemColor: tp.primaryText,
            unselectedItemColor: tp.secondaryText,
            elevation: 0,
            currentIndex: _currentIndex > 2 ? 0 : _currentIndex,
            onTap: _onNavTapped,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
              BottomNavigationBarItem(
                icon: Icon(Icons.school),
                label: "Exam Planner",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: "Profile",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.timer),
                label: "Pomodoro",
              ),
            ],
          ),
        ),
      ),
    );
  }

  // SHORTCUT BUTTON
  Widget _buildShortcut(
    ThemeProvider tp,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [tp.shortcutGradientStart, tp.shortcutGradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: tp.shadowColor,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: tp.primaryText, size: 24),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(fontSize: 12, color: tp.primaryText)),
          ],
        ),
      ),
    );
  }

  // ANALYTICS CARD
  Widget _buildAnalyticsCard({
    required ThemeProvider tp,
    required String label,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tp.analyticsCardBg(color),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: tp.shadowColor, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(32),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: tp.primaryText,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          Text(
            count.toString(),
            style: TextStyle(
              color: tp.primaryText,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
        ],
      ),
    );
  }
}
