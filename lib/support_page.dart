import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';

class SupportPage extends StatefulWidget {
  @override
  _SupportPageState createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  final _problemController = TextEditingController();
  final _feedbackController = TextEditingController();
  int _selectedRating = 0;

  @override
  void dispose() {
    _problemController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  void _submitProblem() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Problem report submitted")));
    _problemController.clear();
  }

  void _submitFeedback() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Feedback submitted")));
    _feedbackController.clear();
    setState(() => _selectedRating = 0);
  }

  Widget _sectionCard(
    ThemeProvider tp, {
    required String title,
    required Widget child,
  }) {
    return Card(
      color: tp.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: tp.primaryText,
              ),
            ),
            SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tp = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: tp.scaffoldBg,
      appBar: AppBar(title: Text("Support"), backgroundColor: tp.appBarBg),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // FAQs
          _sectionCard(
            tp,
            title: "FAQs",
            child: ExpansionPanelList.radio(
              children: [
                ExpansionPanelRadio(
                  value: "q1",
                  headerBuilder: (context, isExpanded) => ListTile(
                    title: Text(
                      "How do I reset my password?",
                      style: TextStyle(color: tp.primaryText),
                    ),
                  ),
                  body: ListTile(
                    title: Text(
                      "Go to Settings > Change Password and follow the instructions.",
                      style: TextStyle(color: tp.secondaryText),
                    ),
                  ),
                ),
                ExpansionPanelRadio(
                  value: "q2",
                  headerBuilder: (context, isExpanded) => ListTile(
                    title: Text(
                      "How can I update my email?",
                      style: TextStyle(color: tp.primaryText),
                    ),
                  ),
                  body: ListTile(
                    title: Text(
                      "Edit your email in Account > Edit Profile.",
                      style: TextStyle(color: tp.secondaryText),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Contact Support
          _sectionCard(
            tp,
            title: "Contact Support",
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.email, color: tp.accentTeal),
                  title: Text(
                    "Email Us",
                    style: TextStyle(color: tp.primaryText),
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Launching email app...")),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.phone, color: tp.accentAmber),
                  title: Text(
                    "Call Support",
                    style: TextStyle(color: tp.primaryText),
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Calling support...")),
                    );
                  },
                ),
              ],
            ),
          ),

          // Report Problem
          _sectionCard(
            tp,
            title: "Report a Problem",
            child: Column(
              children: [
                TextField(
                  controller: _problemController,
                  style: TextStyle(color: tp.primaryText),
                  decoration: InputDecoration(
                    hintText: "Describe the issue...",
                    hintStyle: TextStyle(color: tp.inactiveColor),
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tp.accentTeal,
                  ),
                  onPressed: _submitProblem,
                  child: Text("Submit"),
                ),
              ],
            ),
          ),

          // Feedback
          _sectionCard(
            tp,
            title: "Feedback & Suggestions",
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < _selectedRating
                            ? Icons.star
                            : Icons.star_border,
                        color: tp.accentAmber,
                      ),
                      onPressed: () {
                        setState(() => _selectedRating = index + 1);
                      },
                    );
                  }),
                ),
                TextField(
                  controller: _feedbackController,
                  style: TextStyle(color: tp.primaryText),
                  decoration: InputDecoration(
                    hintText: "Your suggestions...",
                    hintStyle: TextStyle(color: tp.inactiveColor),
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: tp.appBarBg),
                  onPressed: _submitFeedback,
                  child: Text("Submit"),
                ),
              ],
            ),
          ),

          // App Info
          _sectionCard(
            tp,
            title: "App Info",
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.info, color: tp.primaryText),
                  title: Text(
                    "App Version: 1.0.0",
                    style: TextStyle(color: tp.primaryText),
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.policy, color: tp.accentTeal),
                  title: Text(
                    "Privacy Policy",
                    style: TextStyle(color: tp.primaryText),
                  ),
                  onTap: () {},
                ),
                ListTile(
                  leading: Icon(Icons.article, color: tp.accentAmber),
                  title: Text(
                    "Terms of Service",
                    style: TextStyle(color: tp.primaryText),
                  ),
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
