// lib/communications_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class CommunicationsPage extends StatefulWidget {
  const CommunicationsPage({Key? key}) : super(key: key);

  @override
  State<CommunicationsPage> createState() => _CommunicationsPageState();
}

class _CommunicationsPageState extends State<CommunicationsPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _messageCtrl = TextEditingController();
  bool _sending = false;

  // =====================================================
  // 🔔 SEND MESSAGE + PUSH NOTIFICATION
  // =====================================================
  Future<void> _sendMessage() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);

    final title = _titleCtrl.text.trim();
    final message = _messageCtrl.text.trim();

    try {
      // 1️⃣ Save message in Firestore (for history)
      await FirebaseFirestore.instance.collection('communications').add({
        'title': title,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'sender': 'admin',
      });

      // 2️⃣ Call backend API to send push notification
      final response = await http.post(
        Uri.parse(
          "https://classtrack-backend-unmn.onrender.com/send-notification",
        ),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "title": title,
          "message": message,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode != 200 || data["success"] != true) {
        throw Exception("Push notification failed");
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Message & notification sent'),
          backgroundColor: Color(0xFF1B3C53),
        ),
      );

      _titleCtrl.clear();
      _messageCtrl.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  // -------------------- UI: COMPOSE MESSAGE BOX --------------------
  Widget _buildComposeArea(bool isMobile) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 18),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Compose Message",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF1B3C53),
                ),
              ),
              SizedBox(height: 14),

              // Title
              TextFormField(
                controller: _titleCtrl,
                decoration: InputDecoration(
                  labelText: "Title",
                  border: OutlineInputBorder(),
                  labelStyle: TextStyle(color: Color(0xFF456882)),
                ),
                validator: (v) => v!.trim().isEmpty ? "Enter a title" : null,
              ),
              SizedBox(height: 14),

              // Message
              TextFormField(
                controller: _messageCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: "Message",
                  border: OutlineInputBorder(),
                  labelStyle: TextStyle(color: Color(0xFF456882)),
                ),
                validator: (v) => v!.trim().isEmpty ? "Enter a message" : null,
              ),
              SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _sending
                        ? null
                        : () {
                      _titleCtrl.clear();
                      _messageCtrl.clear();
                    },
                    child: Text(
                      "Clear",
                      style: TextStyle(color: Color(0xFF456882)),
                    ),
                  ),
                  SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF1B3C53),
                      foregroundColor: Colors.white,
                      padding:
                      EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _sending ? null : _sendMessage,
                    child: _sending
                        ? SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : Text("Send", style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------- UI: SINGLE MESSAGE TILE --------------------
  Widget _buildMessageTile(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final title = data['title'] ?? '';
    final message = data['message'] ?? '';
    final sender = data['sender'] ?? '';
    final ts = (data['timestamp'] as Timestamp?)?.toDate();

    final timeStr = ts != null
        ? "${ts.day.toString().padLeft(2, '0')}-${ts.month.toString().padLeft(2, '0')}-${ts.year} "
        "${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}"
        : '';

    return ListTile(
      leading: Icon(Icons.message_rounded, color: Color(0xFF456882)),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 6),
          Text(message),
          SizedBox(height: 8),
          Row(
            children: [
              Text(
                sender,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Spacer(),
              Text(
                timeStr,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          )
        ],
      ),
      isThreeLine: true,
      trailing: PopupMenuButton<String>(
        onSelected: (v) async {
          if (v == 'delete') {
            await FirebaseFirestore.instance
                .collection('communications')
                .doc(doc.id)
                .delete();

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Deleted'),
                backgroundColor: Color(0xFF1B3C53),
              ),
            );
          }
        },
        itemBuilder: (_) => [
          PopupMenuItem(
            value: 'delete',
            child: Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------- PAGE BUILD --------------------
  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: Color(0xFFF3EFEC),
      body: Column(
        children: [
          _buildComposeArea(isMobile),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('communications')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return Center(child: CircularProgressIndicator());

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                  return Center(child: Text("No communications yet."));

                final docs = snapshot.data!.docs;

                return ListView.separated(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 8 : 24,
                    vertical: 8,
                  ),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => Divider(height: 1),
                  itemBuilder: (context, index) {
                    return _buildMessageTile(docs[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
