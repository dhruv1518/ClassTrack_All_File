import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';

class AdminInquiryPage extends StatefulWidget {
  @override
  State<AdminInquiryPage> createState() => _AdminInquiryPageState();
}

class _AdminInquiryPageState extends State<AdminInquiryPage> {
  final _formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final courseCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  DateTime? reminderDate;

  Future<void> saveInquiry() async {
    if (!_formKey.currentState!.validate() || reminderDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields & reminder date")),
      );
      return;
    }
    await FirebaseFirestore.instance.collection('inquiries').add({
      "name": nameCtrl.text.trim(),
      "phone": phoneCtrl.text.trim(),
      "course": courseCtrl.text.trim(),
      "description": descCtrl.text.trim(),
      "reminderAt": Timestamp.fromDate(reminderDate!),
      "reminderSent": false,
      "status": "pending",
      "createdAt": FieldValue.serverTimestamp(),
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Inquiry saved. Reminder scheduled.")),
    );
    _formKey.currentState!.reset();
    nameCtrl.clear();
    phoneCtrl.clear();
    courseCtrl.clear();
    descCtrl.clear();
    reminderDate = null;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final tp = Provider.of<ThemeProvider>(context);
    return Scaffold(
      backgroundColor: tp.scaffoldBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Add Inquiry",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: tp.primaryText,
                ),
              ),
              const SizedBox(height: 16),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    buildField(tp, "Name", nameCtrl),
                    const SizedBox(height: 12),
                    buildField(
                      tp,
                      "Phone",
                      phoneCtrl,
                      keyboard: TextInputType.phone,
                      maxLength: 10,
                      isPhone: true,
                    ),
                    const SizedBox(height: 12),
                    buildField(tp, "Course", courseCtrl),
                    const SizedBox(height: 12),
                    buildField(tp, "Description", descCtrl, maxLines: 3),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.alarm),
                      label: Text(
                        reminderDate == null
                            ? "Pick Reminder Date"
                            : DateFormat(
                                'dd MMM yyyy, hh:mm a',
                              ).format(reminderDate!),
                      ),
                      onPressed: pickReminderDate,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: saveInquiry,
                    child: const Text("Save"),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Divider(color: tp.dividerColor),
              Text(
                "Inquiry History",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: tp.primaryText,
                ),
              ),
              const SizedBox(height: 12),
              inquiryList(tp),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildField(
    ThemeProvider tp,
    String label,
    TextEditingController ctrl, {
    int maxLines = 1,
    TextInputType keyboard = TextInputType.text,
    int? maxLength,
    bool isPhone = false,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboard,
      maxLength: maxLength,
      style: TextStyle(color: tp.primaryText),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return "Required";
        if (isPhone && !RegExp(r'^\d{10}$').hasMatch(v.trim()))
          return "Enter 10 digit phone number";
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: tp.secondaryText),
        counterText: "",
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: tp.cardHighlight,
      ),
    );
  }

  Future<void> pickReminderDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      initialDate: DateTime.now(),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;
    reminderDate = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    setState(() {});
  }

  Widget inquiryList(ThemeProvider tp) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('inquiries')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (_, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty)
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              "No inquiries yet.",
              style: TextStyle(color: tp.secondaryText),
            ),
          );
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (_, index) {
            final doc = snapshot.data!.docs[index];
            final d = doc.data() as Map<String, dynamic>;
            final createdAt = (d['createdAt'] as Timestamp?)?.toDate();
            final reminderAt = (d['reminderAt'] as Timestamp?)?.toDate();
            return Card(
              color: tp.cardBg,
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: Icon(Icons.person, color: _statusColor(d['status'])),
                title: Text(
                  d['name'] ?? '',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: tp.primaryText,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${d['phone']} • ${d['course']}",
                      style: TextStyle(color: tp.secondaryText),
                    ),
                    if (createdAt != null)
                      Text(
                        "Added: ${DateFormat('dd MMM yyyy').format(createdAt)}",
                        style: TextStyle(fontSize: 12, color: tp.secondaryText),
                      ),
                    if (reminderAt != null)
                      Text(
                        "Reminder: ${DateFormat('dd MMM yyyy, hh:mm a').format(reminderAt)}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.redAccent,
                        ),
                      ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.circle,
                        color: _statusColor(d['status']),
                        size: 14,
                      ),
                      onSelected: (value) {
                        FirebaseFirestore.instance
                            .collection('inquiries')
                            .doc(doc.id)
                            .update({"status": value});
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: "pending",
                          child: Text("🟡 Pending"),
                        ),
                        PopupMenuItem(
                          value: "called",
                          child: Text("🟢 Called"),
                        ),
                        PopupMenuItem(value: "closed", child: Text("⚪ Closed")),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        FirebaseFirestore.instance
                            .collection('inquiries')
                            .doc(doc.id)
                            .delete();
                      },
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

  Color _statusColor(String? status) {
    switch (status) {
      case "called":
        return Colors.green;
      case "closed":
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }
}
