import 'package:flutter/material.dart';

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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Problem report submitted")),
    );
    _problemController.clear();
  }

  void _submitFeedback() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Feedback submitted")),
    );
    _feedbackController.clear();
    setState(() => _selectedRating = 0);
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF264653))),
            SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F2EC), // soft beige
      appBar: AppBar(
        title: Text("Support"),
        backgroundColor: Color(0xFF264653), // dark navy
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // FAQs
          _sectionCard(
            title: "FAQs",
            child: ExpansionPanelList.radio(
              children: [
                ExpansionPanelRadio(
                  value: "q1",
                  headerBuilder: (context, isExpanded) =>
                      ListTile(title: Text("How do I reset my password?")),
                  body: ListTile(
                    title: Text(
                        "Go to Settings > Change Password and follow the instructions."),
                  ),
                ),
                ExpansionPanelRadio(
                  value: "q2",
                  headerBuilder: (context, isExpanded) =>
                      ListTile(title: Text("How can I update my email?")),
                  body: ListTile(
                    title: Text("Edit your email in Account > Edit Profile."),
                  ),
                ),
              ],
            ),
          ),

          // Contact Support
          _sectionCard(
            title: "Contact Support",
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.email, color: Color(0xFF2A9D8F)),
                  title: Text("Email Us"),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Launching email app...")));
                  },
                ),
                ListTile(
                  leading: Icon(Icons.phone, color: Color(0xFFE9C46A)),
                  title: Text("Call Support"),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Calling support...")));
                  },
                ),
              ],
            ),
          ),

          // Report Problem
          _sectionCard(
            title: "Report a Problem",
            child: Column(
              children: [
                TextField(
                  controller: _problemController,
                  decoration: InputDecoration(
                      hintText: "Describe the issue...",
                      border: OutlineInputBorder()),
                  maxLines: 3,
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF2A9D8F), // teal
                  ),
                  onPressed: _submitProblem,
                  child: Text("Submit"),
                ),
              ],
            ),
          ),

          // Feedback
          _sectionCard(
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
                        color: Colors.amber,
                      ),
                      onPressed: () {
                        setState(() => _selectedRating = index + 1);
                      },
                    );
                  }),
                ),
                TextField(
                  controller: _feedbackController,
                  decoration: InputDecoration(
                      hintText: "Your suggestions...",
                      border: OutlineInputBorder()),
                  maxLines: 3,
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF264653), // navy
                  ),
                  onPressed: _submitFeedback,
                  child: Text("Submit"),
                ),
              ],
            ),
          ),

          // App Info
          _sectionCard(
            title: "App Info",
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.info, color: Color(0xFF264653)),
                  title: Text("App Version: 1.0.0"),
                ),
                ListTile(
                  leading: Icon(Icons.policy, color: Color(0xFF2A9D8F)),
                  title: Text("Privacy Policy"),
                  onTap: () {},
                ),
                ListTile(
                  leading: Icon(Icons.article, color: Color(0xFFE9C46A)),
                  title: Text("Terms of Service"),
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
