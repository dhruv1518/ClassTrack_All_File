import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login.dart'; // Your login widget for logout
import 'analytics_page.dart'; // Import your analytics page here
import 'admin_setting.dart'; // Import your settings page
import 'communications_page.dart'; // add this near your other imports


class AdminDashboard extends StatefulWidget {
  @override
  AdminDashboardState createState() => AdminDashboardState();
}

class AdminDashboardState extends State<AdminDashboard> {
  int selectedIndex = 0;
  final List<String> pageTitles = [
    "Dashboard", "Students", "Analytics", "Communications", "Settings",
  ];
  final List<IconData> pageIcons = [
    Icons.dashboard_rounded, Icons.people_rounded, Icons.analytics_rounded, Icons.message_rounded, Icons.settings_rounded,
  ];

  void doLogout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => StudentLoginPage()),
          (route) => false,
    );
  }

  void showLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Confirm Logout", style: TextStyle(color: Color(0xFF1B3C53))),
        content: Text("Are you sure you want to logout?"),
        actions: [
          TextButton(child: Text("Cancel"), onPressed: () => Navigator.of(context).pop()),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF1B3C53)),
            child: Text("Logout", style: TextStyle(color: Colors.white)),
            onPressed: () {
              Navigator.of(context).pop();
              doLogout();
            },
          ),
        ],
      ),
    );
  }

  void showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Color(0xFF1B3C53)),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 768;
    return Scaffold(
      backgroundColor: Color(0xFFF3EFEC),
      appBar: AppBar(
        title: Text(
          isMobile ? "ClassTrack Admin" : "ClassTrack Admin - ${pageTitles[selectedIndex]}",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Color(0xFF1B3C53),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () => showSnackbar("Notifications feature coming soon!"),
          ),
          IconButton(
            icon: Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: showLogoutDialog,
          ),
        ],
      ),
      body: isMobile ? buildMobileBody() : buildWebBody(),
      bottomNavigationBar: isMobile ? buildBottomNavigation() : null,
      drawer: isMobile ? buildMobileDrawer() : null,
    );
  }

  // Navigation logic for all pages including Analytics!
  Widget buildMobileBody() {
    if (selectedIndex == 0) return DashboardHomePage();
    if (selectedIndex == 1) return StudentsManagementPage();
    if (selectedIndex == 2) return AnalyticsPage();
    if (selectedIndex == 3) return CommunicationsPage();  // ✅ Load your new page
    if (selectedIndex == 4) return AdminSettingsPage(); // Link to your settings page!
    return PlaceholderPage(title: pageTitles[selectedIndex], icon: pageIcons[selectedIndex]);
  }


  Widget buildWebBody() {
    return Row(
      children: [
        buildSidebar(),
        Expanded(child: buildMobileBody()),
      ],
    );
  }

  Widget buildSidebar() {
    return Container(
      width: 240,
      color: Colors.white,
      child: Column(
        children: [
          DrawerHeader(
            child: ListTile(
              leading: Icon(Icons.admin_panel_settings_rounded, size: 40, color: Color(0xFF1B3C53)),
              title: Text("Administrator", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("ClassTrack System"),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: pageTitles.length,
              itemBuilder: (context, index) => ListTile(
                leading: Icon(pageIcons[index], color: selectedIndex == index ? Color(0xFF1B3C53) : Color(0xFF456882)),
                title: Text(pageTitles[index], style: TextStyle(fontWeight: FontWeight.w600)),
                selected: selectedIndex == index,
                onTap: () => setState(() => selectedIndex = index),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildBottomNavigation() {
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: (index) => setState(() => selectedIndex = index),
      selectedItemColor: Color(0xFF1B3C53),
      unselectedItemColor: Color(0xFF456882),
      items: List.generate(
        pageTitles.length,
            (index) => BottomNavigationBarItem(
          icon: Icon(pageIcons[index]),
          label: pageTitles[index],
        ),
      ),
    );
  }

  Widget buildMobileDrawer() {
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            child: ListTile(
              leading: Icon(Icons.admin_panel_settings_rounded, size: 40, color: Color(0xFF1B3C53)),
              title: Text("Administrator", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("ClassTrack System"),
            ),
          ),
          ...List.generate(pageTitles.length, (index) => ListTile(
            leading: Icon(pageIcons[index], color: selectedIndex == index ? Color(0xFF1B3C53) : Color(0xFF456882)),
            title: Text(pageTitles[index]),
            selected: selectedIndex == index,
            onTap: () {
              setState(() => selectedIndex = index);
              Navigator.pop(context);
            },
          )),
        ],
      ),
    );
  }
}

// Dashboard main/home page
class DashboardHomePage extends StatelessWidget {
  const DashboardHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 768;
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeCard(isMobile),
          SizedBox(height: isMobile ? 18 : 30),
          buildStatsGrid(isMobile),
          SizedBox(height: isMobile ? 24 : 32),
          buildRecentActivity(isMobile),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 14 : 28),
      decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF1B3C53), Color(0xFF6B8CAE)]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Color(0xFF1B3C53).withOpacity(0.22), blurRadius: 12, offset: Offset(0, 4))]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Welcome to ClassTrack Admin", style: TextStyle(fontSize: isMobile ? 18 : 24, fontWeight: FontWeight.bold, color: Colors.white)),
          SizedBox(height: 7),
          Text("Manage your student management system efficiently.",
              style: TextStyle(fontSize: isMobile ? 12 : 15, color: Colors.white.withOpacity(0.9))),
        ],
      ),
    );
  }

  // Dashboard grid (students, active today, etc.)
  Widget buildStatsGrid(bool isMobile) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        int total = 0;
        int activeToday = 0;
        final now = DateTime.now();
        if (snapshot.hasData) {
          total = snapshot.data!.docs.length;
          activeToday = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final lastLogin = data['lastLogin'];
            if (lastLogin is Timestamp) {
              final loginDt = lastLogin.toDate();
              return loginDt.year == now.year && loginDt.month == now.month && loginDt.day == now.day;
            }
            return false;
          }).length;
        }
        return GridView.count(
          shrinkWrap: true,
          crossAxisCount: isMobile ? 2 : 4,
          crossAxisSpacing: isMobile ? 12 : 16,
          mainAxisSpacing: isMobile ? 12 : 16,
          childAspectRatio: isMobile ? 1.3 : 1.0,
          physics: NeverScrollableScrollPhysics(),
          children: [
            buildStatCard("Total Students", "$total", Icons.people_rounded, Colors.blue, isMobile),
            buildStatCard("Active Today", "$activeToday", Icons.today_rounded, Colors.green, isMobile),
            buildStatCard("App Features", "12", Icons.apps, Colors.deepPurple, isMobile),
            buildStatCard("Add Feature", "-", Icons.add_circle_outline, Colors.grey, isMobile),
          ],
        );
      },
    );
  }

  static Widget buildStatCard(String title, String value, IconData icon, Color color, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 18, vertical: isMobile ? 12 : 18),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Color(0xFF1B3C53).withOpacity(0.16), blurRadius: 4, offset: Offset(0, 2))]
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: isMobile ? 20 : 28),
          ),
          SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: isMobile ? 16 : 22, fontWeight: FontWeight.bold, color: Color(0xFF1B3C53))),
          SizedBox(height: 3),
          Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: isMobile ? 11 : 14, color: Color(0xFF456882), fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget buildRecentActivity(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Recent Activity", style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 16 : 18, color: Color(0xFF1B3C53))),
        SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Color(0xFF1B3C53).withOpacity(0.08), blurRadius: 3)]),
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('user_activity').orderBy('timestamp', descending: true).limit(25).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting)
                return Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                return Center(child: Padding(padding: EdgeInsets.all(18), child: Text("No recent activity.")));
              final activities = snapshot.data!.docs;
              return ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: activities.length,
                itemBuilder: (context, i) {
                  final activity = activities[i].data() as Map<String, dynamic>;
                  final name = activity['name'] ?? "";
                  final action = activity['action'] ?? "";
                  final timestamp = (activity['timestamp'] as Timestamp?)?.toDate();
                  final email = activity['email'] ?? "";
                  IconData icon = Icons.fiber_manual_record_rounded;
                  Color color = Colors.blueGrey;
                  if (action.toLowerCase() == "logged in") { icon = Icons.login_rounded; color = Colors.green; }
                  else if (action.toLowerCase() == "logged out") { icon = Icons.logout_rounded; color = Colors.orange; }
                  String timeStr = timestamp != null ? _formatTimeAgo(timestamp) : "";
                  return ListTile(
                    leading: Icon(icon, color: color),
                    title: Text("$name - $action", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    subtitle: Text("$email\n$timeStr", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    isThreeLine: true,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return "${diff.inMinutes} min ago";
    if (diff.inHours < 24) return "${diff.inHours} hr ago";
    return "${diff.inDays} days ago";
  }
}

// Students management with Firestore stream
class StudentsManagementPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 768;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
          return Center(child: Text("No students registered."));
        final students = snapshot.data!.docs;
        return ListView.builder(
          itemCount: students.length,
          itemBuilder: (context, i) {
            final student = students[i].data() as Map<String, dynamic>;
            final name = student['name'] ?? '';
            final email = student['email'] ?? '';
            final registrationDate = (student['registrationDate'] as Timestamp?)?.toDate();
            return ListTile(
              leading: CircleAvatar(child: Text(name.isNotEmpty ? name[0] : '?')),
              title: Text(name),
              subtitle: Text('$email\nJoined: ${registrationDate ?? ''}'),
              isThreeLine: true,
            );
          },
        );
      },
    );
  }
}

class PlaceholderPage extends StatelessWidget {
  final String title;
  final IconData icon;
  const PlaceholderPage({required this.title, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 60, color: Color(0xFF456882)),
        SizedBox(height: 16),
        Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1B3C53))),
        SizedBox(height: 8),
        Text("Feature under construction", style: TextStyle(fontSize: 16, color: Colors.grey)),
      ]),
    );
  }
}
