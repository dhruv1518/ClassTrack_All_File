import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({Key? key}) : super(key: key);

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  String? selectedEmail;
  List<String> allEmails = [];

  Future<List<String>> fetchAllEmails() async {
    final users = await FirebaseFirestore.instance.collection('users').get();
    return users.docs
        .map((doc) => doc['email'] as String? ?? '')
        .where((e) => e.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 768;
    return Scaffold(
      backgroundColor: const Color(0xFFF3EFEC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B3C53),
        elevation: 0,
        title: const Text(
          "User Analytics",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 20, letterSpacing: 0.5),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<String>>(
        future: fetchAllEmails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Center(child: CircularProgressIndicator());
          }
          final emails = snapshot.data ?? [];
          if (emails.isEmpty) {
            return Center(child: Text("No users available."));
          }
          selectedEmail ??= emails.first;
          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 22),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: LayoutBuilder(
                  builder: (context, constraints) => ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: "Select User",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        fillColor: Colors.white,
                        filled: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      ),
                      value: selectedEmail,
                      style: TextStyle(fontSize: 18, color: Color(0xFF1B3C53), fontWeight: FontWeight.bold),
                      items: emails
                          .map((email) => DropdownMenuItem(
                        value: email,
                        child: Container(
                          width: double.infinity,
                          child: Text(
                            email,
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                          ),
                        ),
                      ))
                          .toList(),
                      onChanged: (email) {
                        setState(() {
                          selectedEmail = email;
                        });
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              if (selectedEmail != null)
                _UserAnalytics(email: selectedEmail!, isMobile: isMobile),
            ],
          );
        },
      ),
    );
  }
}

class _UserAnalytics extends StatelessWidget {
  final String email;
  final bool isMobile;

  const _UserAnalytics({required this.email, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildAnalyticsSection(
          title: "Registration Analytics",
          icon: Icons.person_add_rounded,
          color: Colors.blue,
          isMobile: isMobile,
          futureCounts: [
            countUserReg(Duration(days: 1)),
            countUserReg(Duration(days: 7)),
            countUserReg(Duration(days: 30)),
            countUserReg(null)
          ],
          labels: ["Last 24h", "Last Week", "Last Month", "All Time"],
        ),
        SizedBox(height: isMobile ? 26 : 35),
        buildAnalyticsSection(
          title: "Login Analytics",
          icon: Icons.login_rounded,
          color: Colors.green,
          isMobile: isMobile,
          futureCounts: [
            countUserLogin(Duration(days: 1)),
            countUserLogin(Duration(days: 7)),
            countUserLogin(Duration(days: 30)),
            countUserLogin(null)
          ],
          labels: ["Last 24h", "Last Week", "Last Month", "All Time"],
        ),
        SizedBox(height: 32),
        Text(
          "Login Activity (Past 7 Days)",
          style: TextStyle(
            fontSize: isMobile ? 17 : 19,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B3C53),
          ),
        ),
        SizedBox(height: 9),
        Center(
          child: Container(
            height: 240,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
              boxShadow: [BoxShadow(color: Color(0xFF1B3C53).withOpacity(0.08), blurRadius: 8)],
            ),
            alignment: Alignment.center,
            child: Image.network(
                "https://ppl-ai-code-interpreter-files.s3.amazonaws.com/web/direct-files/db74d5b2b3ec3fdf3fbe02a3583b0959/b32cdaab-8c93-4b06-b750-5d2e3c5f3a72/dc6fd3cd.png",
                fit: BoxFit.cover
            ),
          ),
        ),
        SizedBox(height: 14),
      ],
    );
  }

  Future<int> countUserReg(Duration? range) async {
    Query ref = FirebaseFirestore.instance.collection("users").where("email", isEqualTo: email);
    if (range != null) {
      DateTime start = DateTime.now().subtract(range);
      ref = ref.where("registrationDate", isGreaterThanOrEqualTo: start);
    }
    QuerySnapshot snap = await ref.get();
    return snap.docs.length;
  }

  Future<int> countUserLogin(Duration? range) async {
    Query ref = FirebaseFirestore.instance.collection("user_activity")
        .where("email", isEqualTo: email)
        .where("action", isEqualTo: "Logged In");
    if (range != null) {
      DateTime start = DateTime.now().subtract(range);
      ref = ref.where("timestamp", isGreaterThanOrEqualTo: start);
    }
    QuerySnapshot snap = await ref.get();
    return snap.docs.length;
  }

  Widget buildAnalyticsSection({
    required String title,
    required IconData icon,
    required Color color,
    required bool isMobile,
    required List<Future<int>> futureCounts,
    required List<String> labels,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Color(0xFF1B3C53).withOpacity(0.12), blurRadius: 12, offset: Offset(0,4))
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 28, vertical: isMobile ? 22 : 32),
      margin: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 15),
              Text(
                title,
                style: TextStyle(
                  fontSize: isMobile ? 18 : 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B3C53),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Column(
            children: [
              Row(
                children: [
                  for (int i = 0; i < 2; ++i)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        child: FutureBuilder<int>(
                          future: futureCounts[i],
                          builder: (context, snap) {
                            return buildMetricCard(
                              period: labels[i],
                              count: snap.connectionState == ConnectionState.waiting ? "-" : (snap.hasData ? snap.data.toString() : "-"),
                              primaryColor: color,
                              bgColor: color.withOpacity(0.07),
                              isMobile: isMobile,
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
              Row(
                children: [
                  for (int i = 2; i < 4; ++i)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        child: FutureBuilder<int>(
                          future: futureCounts[i],
                          builder: (context, snap) {
                            return buildMetricCard(
                              period: labels[i],
                              count: snap.connectionState == ConnectionState.waiting ? "-" : (snap.hasData ? snap.data.toString() : "-"),
                              primaryColor: color,
                              bgColor: color.withOpacity(0.07),
                              isMobile: isMobile,
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildMetricCard({
    required String period,
    required String count,
    required Color primaryColor,
    required Color bgColor,
    required bool isMobile,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: isMobile ? 20 : 22),
      margin: EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primaryColor.withOpacity(0.12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(count, style: TextStyle(fontSize: isMobile ? 22 : 27, fontWeight: FontWeight.bold, color: primaryColor)),
          const SizedBox(height: 3),
          Text(period, style: TextStyle(fontSize: isMobile ? 12 : 14, color: Color(0xFF456882), fontWeight: FontWeight.w600), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
