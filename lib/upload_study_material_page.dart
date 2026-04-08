import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';

class UploadStudyMaterialPage extends StatefulWidget {
  const UploadStudyMaterialPage({Key? key}) : super(key: key);

  @override
  State<UploadStudyMaterialPage> createState() =>
      _UploadStudyMaterialPageState();
}

class _UploadStudyMaterialPageState extends State<UploadStudyMaterialPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController subjectController = TextEditingController();
  final TextEditingController chapterController = TextEditingController();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController pdfLinkController = TextEditingController();

  bool isUploading = false;

  Future<void> uploadMaterial() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isUploading = true);

    try {
      await FirebaseFirestore.instance.collection('study_materials').add({
        'subject': subjectController.text.trim(),
        'chapter': chapterController.text.trim(),
        'title': titleController.text.trim(),
        'pdfUrl': pdfLinkController.text.trim(),
        'createdAt': Timestamp.now(),
      });

      final tp = Provider.of<ThemeProvider>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Study material uploaded successfully"),
          backgroundColor: tp.appBarBg,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tp = Provider.of<ThemeProvider>(context);
    return Scaffold(
      backgroundColor: tp.scaffoldBg,
      appBar: AppBar(
        title: const Text("Upload Study Material"),
        backgroundColor: tp.appBarBg,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField(
                tp: tp,
                controller: subjectController,
                label: "Subject",
                hint: "e.g. DBMS",
              ),
              _buildTextField(
                tp: tp,
                controller: chapterController,
                label: "Chapter",
                hint: "e.g. Chapter 1",
              ),
              _buildTextField(
                tp: tp,
                controller: titleController,
                label: "Title",
                hint: "Introduction to DBMS",
              ),
              _buildTextField(
                tp: tp,
                controller: pdfLinkController,
                label: "Google Drive PDF Link",
                hint: "https://drive.google.com/...",
                isLink: true,
              ),
              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: isUploading ? null : uploadMaterial,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tp.appBarBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isUploading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Save Material",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- COMMON TEXT FIELD ----------
  Widget _buildTextField({
    required ThemeProvider tp,
    required TextEditingController controller,
    required String label,
    required String hint,
    bool isLink = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        style: TextStyle(color: tp.primaryText),
        keyboardType: isLink ? TextInputType.url : TextInputType.text,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return "$label is required";
          }
          if (isLink && !value.contains("drive.google.com")) {
            return "Please enter a valid Google Drive link";
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: tp.secondaryText),
          hintText: hint,
          hintStyle: TextStyle(color: tp.inactiveColor),
          filled: true,
          fillColor: tp.inputFillColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: tp.accentTeal, width: 1.5),
          ),
        ),
      ),
    );
  }
}
