import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';

import 'login.dart';
import 'admin_setting.dart';
import 'communications_page.dart';
import 'admin_study_material_page.dart';
import 'admin_inquiry_page.dart';
import 'students_page.dart';
import 'analytics_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ThemeProvider>(context, listen: false).setPanel('admin');
    });
  }

  // Bottom Navigation (Mobile Main Pages)
  final List<String> pageTitles = [
    "Dashboard",
    "Students",
    "Inquiries",
    "Settings",
  ];

  final List<IconData> pageIcons = [
    Icons.dashboard_rounded,
    Icons.people_rounded,
    Icons.support_agent_rounded,
    Icons.settings_rounded,
  ];

  void handleNavigation(int index) {
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const StudentsPage()),
      );
      return;
    }

    setState(() => selectedIndex = index);
  }

  void doLogout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => StudentLoginPage()),
      (route) => false,
    );
  }

  void showLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Provider.of<ThemeProvider>(
                context,
                listen: false,
              ).appBarBg,
            ),
            onPressed: () {
              Navigator.pop(context);
              doLogout();
            },
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }

  Widget buildBody() {
    switch (selectedIndex) {
      case 0:
        return const DashboardHomePage();
      case 2:
        return AdminInquiryPage();
      case 3:
        return AdminSettingsPage();
      default:
        return const DashboardHomePage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 768;

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
            title: const Text('Exit Admin Dashboard?'),
            content: const Text('Are you sure you want to exit?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Provider.of<ThemeProvider>(
                    context,
                    listen: false,
                  ).appBarBg,
                ),
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
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Provider.of<ThemeProvider>(context).scaffoldBg,
        appBar: AppBar(
          backgroundColor: Provider.of<ThemeProvider>(context).appBarBg,
          title: Text(
            isMobile
                ? "ClassTrack Admin"
                : "ClassTrack Admin - ${pageTitles[selectedIndex]}",
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              onPressed: showLogoutDialog,
            ),
          ],
        ),
        drawer: isMobile ? buildDrawer() : null,
        bottomNavigationBar: isMobile ? buildBottomNav() : null,
        body: isMobile
            ? buildBody()
            : Row(
                children: [
                  buildWebSidebar(),
                  Expanded(child: buildBody()),
                ],
              ),
      ),
    );
  }

  ////////////////////////////////////////////////////////
  /// MOBILE BOTTOM NAVIGATION
  ////////////////////////////////////////////////////////

  Widget buildBottomNav() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: selectedIndex,
      selectedItemColor: Provider.of<ThemeProvider>(context).primaryText,
      unselectedItemColor: Provider.of<ThemeProvider>(context).inactiveColor,
      backgroundColor: Provider.of<ThemeProvider>(context).cardBg,
      showUnselectedLabels: true,
      onTap: handleNavigation,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_rounded),
          label: "Dashboard",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people_rounded),
          label: "Students",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.support_agent_rounded),
          label: "Inquiries",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings_rounded),
          label: "Settings",
        ),
      ],
    );
  }

  ////////////////////////////////////////////////////////
  /// MOBILE DRAWER (Secondary Pages)
  ////////////////////////////////////////////////////////

  Widget buildDrawer() {
    final tp = Provider.of<ThemeProvider>(context);
    return Drawer(
      backgroundColor: tp.cardBg,
      child: ListView(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: tp.appBarBg),
            child: const Text(
              "ClassTrack Admin",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.campaign),
            title: const Text("Communications"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CommunicationsPage()),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.menu_book),
            title: const Text("Study Materials"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AdminStudyMaterialPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  ////////////////////////////////////////////////////////
  /// WEB SIDEBAR
  ////////////////////////////////////////////////////////

  Widget buildWebSidebar() {
    final tp = Provider.of<ThemeProvider>(context);
    return Container(
      width: 240,
      color: tp.cardBg,
      child: ListView(
        children: [
          const SizedBox(height: 20),

          ListTile(
            leading: const Icon(Icons.dashboard_rounded),
            title: const Text("Dashboard"),
            selected: selectedIndex == 0,
            onTap: () => handleNavigation(0),
          ),

          ListTile(
            leading: const Icon(Icons.people_rounded),
            title: const Text("Students"),
            onTap: () => handleNavigation(1),
          ),

          ListTile(
            leading: const Icon(Icons.support_agent),
            title: const Text("Inquiries"),
            selected: selectedIndex == 2,
            onTap: () => handleNavigation(2),
          ),

          ListTile(
            leading: const Icon(Icons.campaign),
            title: const Text("Communications"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CommunicationsPage()),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.menu_book),
            title: const Text("Study Materials"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AdminStudyMaterialPage()),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.settings_rounded),
            title: const Text("Settings"),
            selected: selectedIndex == 3,
            onTap: () => handleNavigation(3),
          ),
        ],
      ),
    );
  }
}

//////////////////////////////////////////////////////////
// PALETTE
//////////////////////////////////////////////////////////

const _kNavy = Color(0xFF1B3C53);
const _kMedBlue = Color(0xFF456882);
const _kTeal = Color(0xFF2A9D8F);
const _kAmber = Color(0xFFE9C46A);
const _kCoral = Color(0xFFE76F51);

//////////////////////////////////////////////////////////
// DASHBOARD HOME PAGE — PROFESSIONAL REDESIGN
//////////////////////////////////////////////////////////

class DashboardHomePage extends StatelessWidget {
  const DashboardHomePage({Key? key}) : super(key: key);

  // ── Data Helpers ──────────────────────────────

  Future<int> _getCount(String collection) async {
    final snapshot = await FirebaseFirestore.instance
        .collection(collection)
        .get();
    return snapshot.size;
  }

  Future<int> _getPendingInquiries() async {
    final snapshot = await FirebaseFirestore.instance
        .collection("inquiries")
        .where("status", isEqualTo: "pending")
        .get();
    return snapshot.size;
  }

  Future<int> _getActiveUsersLast7Days() async {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('lastActiveAt', isGreaterThan: Timestamp.fromDate(sevenDaysAgo))
        .get();
    return snapshot.size;
  }

  Future<int> _getAvgEngagementScore() async {
    final snapshot = await FirebaseFirestore.instance.collection('users').get();
    if (snapshot.docs.isEmpty) return 0;
    int total = 0;
    for (final doc in snapshot.docs) {
      total += AnalyticsService.computeEngagementScore(doc.data());
    }
    return total ~/ snapshot.docs.length;
  }

  // ── BUILD ─────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Section A: Welcome Header ───
          _buildWelcomeHeader(),
          const SizedBox(height: 22),

          // ─── Section B: Key Metrics ───
          _buildSectionTitle("Key Metrics"),
          const SizedBox(height: 12),
          _buildKeyMetrics(),
          const SizedBox(height: 24),

          // ─── Section C: Quick Actions ───
          _buildSectionTitle("Quick Actions"),
          const SizedBox(height: 12),
          _buildQuickActions(context),
          const SizedBox(height: 24),

          // ─── Section D: Recent Activity ───
          _buildSectionTitle("Recent Activity"),
          const SizedBox(height: 12),
          _buildRecentActivity(),
          const SizedBox(height: 24),

          // ─── Section E: Top Students ───
          _buildSectionTitle("Top Students"),
          const SizedBox(height: 12),
          _buildTopStudents(),
          const SizedBox(height: 24),

          // ─── Section F: 7-Day Engagement ───
          _buildSectionTitle("7-Day Platform Activity"),
          const SizedBox(height: 12),
          _build7DayChart(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  //  SECTION A: Welcome Header
  // ──────────────────────────────────────────────

  Widget _buildWelcomeHeader() {
    final hour = DateTime.now().hour;
    String greeting;
    IconData greetIcon;
    if (hour < 12) {
      greeting = "Good Morning";
      greetIcon = Icons.wb_sunny_rounded;
    } else if (hour < 17) {
      greeting = "Good Afternoon";
      greetIcon = Icons.wb_cloudy_rounded;
    } else {
      greeting = "Good Evening";
      greetIcon = Icons.nights_stay_rounded;
    }

    final dateStr = DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now());

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kNavy, Color(0xFF2C5F7C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _kNavy.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(greetIcon, color: _kAmber, size: 20),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '$greeting, Admin',
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Here's what's happening in ClassTrack today.",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  //  SECTION B: Key Metrics (Colored Stat Cards)
  // ──────────────────────────────────────────────

  Widget _buildKeyMetrics() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 1.1,
      children: [
        _coloredStatCard(
          "Total Students",
          Icons.people_rounded,
          _getCount("users"),
          const [Color(0xFF1B3C53), Color(0xFF2C5F7C)],
        ),
        _coloredStatCard(
          "Active (7 Days)",
          Icons.trending_up_rounded,
          _getActiveUsersLast7Days(),
          const [Color(0xFF1F7A6D), Color(0xFF2A9D8F)],
        ),
        _coloredStatCard(
          "Pending Inquiries",
          Icons.pending_actions_rounded,
          _getPendingInquiries(),
          const [Color(0xFFD4A843), Color(0xFFE9C46A)],
        ),
        _coloredStatCard(
          "Avg Engagement",
          Icons.insights_rounded,
          _getAvgEngagementScore(),
          const [Color(0xFFD15A3E), Color(0xFFE76F51)],
        ),
      ],
    );
  }

  Widget _coloredStatCard(
    String title,
    IconData icon,
    Future<int> future,
    List<Color> gradientColors,
  ) {
    return FutureBuilder<int>(
      future: future,
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        final isLoading = !snapshot.hasData;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: gradientColors[0].withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const Spacer(),
              isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white70,
                      ),
                    )
                  : Text(
                      count.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
              const SizedBox(height: 2),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ──────────────────────────────────────────────
  //  SECTION C: Quick Actions
  // ──────────────────────────────────────────────

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _QuickAction(
        icon: Icons.campaign_rounded,
        label: "Send\nCommunication",
        color: _kNavy,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CommunicationsPage()),
        ),
      ),
      _QuickAction(
        icon: Icons.upload_file_rounded,
        label: "Upload\nMaterial",
        color: _kTeal,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AdminStudyMaterialPage()),
        ),
      ),
      _QuickAction(
        icon: Icons.school_rounded,
        label: "View\nStudents",
        color: const Color(0xFF457B9D),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StudentsPage()),
        ),
      ),
      _QuickAction(
        icon: Icons.support_agent_rounded,
        label: "Manage\nInquiries",
        color: _kCoral,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AdminInquiryPage()),
        ),
      ),
    ];

    return Row(
      children: actions.map((a) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: a.onTap,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 18,
                  horizontal: 6,
                ),
                decoration: BoxDecoration(
                  color: Provider.of<ThemeProvider>(context).cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: a.color.withValues(alpha: 0.15)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: a.color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(a.icon, color: a.color, size: 22),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      a.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Provider.of<ThemeProvider>(context).primaryText,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ──────────────────────────────────────────────
  //  SECTION D: Recent Activity Feed
  // ──────────────────────────────────────────────

  Widget _buildRecentActivity() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('user_activity')
          .orderBy('timestamp', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _cardShell(
            child: const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _cardShell(
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'No recent activity yet',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          );
        }

        final docs = snapshot.data!.docs;

        return _cardShell(
          child: Column(
            children: List.generate(docs.length, (i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final name = data['name'] ?? 'Unknown';
              final action = data['action'] ?? '';
              final ts = data['timestamp'] as Timestamp?;
              final timeAgo = ts != null ? _timeAgo(ts.toDate()) : '';

              IconData actIcon;
              Color actColor;
              if (action.toString().toLowerCase().contains('log')) {
                actIcon = Icons.login_rounded;
                actColor = _kTeal;
              } else if (action.toString().toLowerCase().contains('task')) {
                actIcon = Icons.task_alt_rounded;
                actColor = _kAmber;
              } else {
                actIcon = Icons.bolt_rounded;
                actColor = _kMedBlue;
              }

              return Column(
                children: [
                  ListTile(
                    dense: true,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: actColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(actIcon, color: actColor, size: 18),
                    ),
                    title: Text(
                      name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Provider.of<ThemeProvider>(context).primaryText,
                      ),
                    ),
                    subtitle: Text(
                      action,
                      style: TextStyle(
                        fontSize: 12,
                        color: Provider.of<ThemeProvider>(
                          context,
                        ).secondaryText,
                      ),
                    ),
                    trailing: Text(
                      timeAgo,
                      style: TextStyle(
                        fontSize: 11,
                        color: Provider.of<ThemeProvider>(
                          context,
                        ).inactiveColor,
                      ),
                    ),
                  ),
                  if (i < docs.length - 1)
                    Divider(
                      height: 1,
                      color: Provider.of<ThemeProvider>(context).dividerColor,
                    ),
                ],
              );
            }),
          ),
        );
      },
    );
  }

  // ──────────────────────────────────────────────
  //  SECTION E: Top Students Leaderboard
  // ──────────────────────────────────────────────

  Widget _buildTopStudents() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance.collection('users').get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _cardShell(
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          );
        }

        // Compute scores, sort, take top 5
        final scored = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'name': data['name'] ?? 'Unknown',
            'enrollment': data['enrollment'] ?? '',
            'score': AnalyticsService.computeEngagementScore(data),
          };
        }).toList();
        scored.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
        final top = scored.take(5).toList();

        if (top.isEmpty) {
          return _cardShell(
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'No students yet',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          );
        }

        const medals = ['🥇', '🥈', '🥉'];

        return _cardShell(
          child: Column(
            children: List.generate(top.length, (i) {
              final s = top[i];
              final score = s['score'] as int;
              final name = s['name'] as String;
              final enrollment = s['enrollment'] as String;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        // Rank
                        SizedBox(
                          width: 32,
                          child: Text(
                            i < 3 ? medals[i] : '#${i + 1}',
                            style: TextStyle(
                              fontSize: i < 3 ? 20 : 14,
                              fontWeight: FontWeight.bold,
                              color: _kMedBlue,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Name + enrollment
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Provider.of<ThemeProvider>(
                                    context,
                                  ).primaryText,
                                ),
                              ),
                              if (enrollment.isNotEmpty)
                                Text(
                                  enrollment,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Provider.of<ThemeProvider>(
                                      context,
                                    ).inactiveColor,
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Score bar + number
                        SizedBox(
                          width: 100,
                          child: Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: score / 100,
                                    minHeight: 8,
                                    backgroundColor: _kTeal.withValues(
                                      alpha: 0.12,
                                    ),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      score >= 80
                                          ? _kTeal
                                          : score >= 60
                                          ? _kMedBlue
                                          : score >= 35
                                          ? _kAmber
                                          : _kCoral,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$score',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Provider.of<ThemeProvider>(
                                    context,
                                  ).primaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (i < top.length - 1)
                    Divider(
                      height: 1,
                      color: Provider.of<ThemeProvider>(context).dividerColor,
                    ),
                ],
              );
            }),
          ),
        );
      },
    );
  }

  // ──────────────────────────────────────────────
  //  SECTION F: 7-Day Platform Activity Chart
  // ──────────────────────────────────────────────

  Widget _build7DayChart() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance.collection('users').get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _cardShell(
            child: const SizedBox(
              height: 160,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          );
        }

        final userIds = snapshot.data!.docs.map((d) => d.id).toList();

        return FutureBuilder<List<int>>(
          future: _aggregate7DayActivity(userIds),
          builder: (context, aggSnap) {
            if (!aggSnap.hasData) {
              return _cardShell(
                child: const SizedBox(
                  height: 160,
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            }

            final dailyTotals = aggSnap.data!;
            final maxVal = dailyTotals.fold<int>(0, (m, v) => v > m ? v : m);

            return _cardShell(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tasks + Pomodoro sessions across all users',
                      style: TextStyle(
                        fontSize: 12,
                        color: Provider.of<ThemeProvider>(
                          context,
                        ).secondaryText,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 130,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: List.generate(7, (i) {
                          final day = DateTime.now().subtract(
                            Duration(days: 6 - i),
                          );
                          final total = dailyTotals[i];
                          final fraction = maxVal > 0 ? total / maxVal : 0.0;

                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    '$total',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Provider.of<ThemeProvider>(
                                        context,
                                      ).primaryText,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 500),
                                    height: 8 + (fraction * 60),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          _kTeal.withValues(
                                            alpha: 0.3 + fraction * 0.7,
                                          ),
                                          _kTeal,
                                        ],
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    DateFormat.E().format(day),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: _isToday(day)
                                          ? Provider.of<ThemeProvider>(
                                              context,
                                            ).primaryText
                                          : Provider.of<ThemeProvider>(
                                              context,
                                            ).inactiveColor,
                                      fontWeight: _isToday(day)
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Aggregates daily activity (completedTasks + pomodoroSessions) across
  /// all users for the last 7 days.
  Future<List<int>> _aggregate7DayActivity(List<String> userIds) async {
    final List<int> totals = List.filled(7, 0);
    final now = DateTime.now();

    for (int i = 0; i < 7; i++) {
      final day = now.subtract(Duration(days: 6 - i));
      final dateStr =
          "${day.year}${day.month.toString().padLeft(2, '0')}${day.day.toString().padLeft(2, '0')}";

      for (final uid in userIds) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('progress')
            .doc(dateStr)
            .get();
        if (doc.exists) {
          totals[i] += ((doc.data()?['completedTasks'] as int?) ?? 0);
          totals[i] += ((doc.data()?['pomodoroSessions'] as int?) ?? 0);
        }
      }
    }
    return totals;
  }

  // ──────────────────────────────────────────────
  //  SHARED HELPERS
  // ──────────────────────────────────────────────

  Widget _buildSectionTitle(String title, [ThemeProvider? tp]) {
    return Builder(
      builder: (context) {
        final t = tp ?? Provider.of<ThemeProvider>(context);
        return Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: t.primaryText,
          ),
        );
      },
    );
  }

  Widget _cardShell({required Widget child}) {
    return Builder(
      builder: (context) {
        final tp = Provider.of<ThemeProvider>(context);
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: tp.cardBg,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: tp.shadowColor,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: child,
          ),
        );
      },
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat.MMMd().format(dt);
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.day == now.day && d.month == now.month && d.year == now.year;
  }
}

//////////////////////////////////////////////////////////
// QUICK ACTION DATA CLASS
//////////////////////////////////////////////////////////

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}
