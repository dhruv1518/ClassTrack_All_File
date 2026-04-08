import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import 'notes_service.dart';
import 'analytics_service.dart';

class NoteEditorPage extends StatefulWidget {
  final Note note;
  final String categoryId;
  final bool isNewNote;

  const NoteEditorPage({
    required this.note,
    required this.categoryId,
    this.isNewNote = false,
    super.key,
  });

  @override
  _NoteEditorPageState createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  final NotesService _notesService = NotesService();
  bool _hasTrackedCreation = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);
    _contentController = TextEditingController(text: widget.note.content);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    widget.note.title = _titleController.text;
    widget.note.content = _contentController.text;

    await _notesService.updateNote(widget.categoryId, widget.note);

    // 📊 Track note creation (only once for new notes)
    if (widget.isNewNote && !_hasTrackedCreation) {
      _hasTrackedCreation = true;
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        AnalyticsService.trackNoteCreated(uid);
      }
    }

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final tp = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: tp.scaffoldBg,
      appBar: AppBar(
        backgroundColor: tp.appBarBg,
        title: const Text("Edit Note", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: Colors.white),
            onPressed: _saveNote,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Title field
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: "Title",
                hintStyle: TextStyle(color: tp.inactiveColor),
                filled: true,
                fillColor: tp.cardHighlight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: tp.primaryText,
              ),
            ),
            const SizedBox(height: 16),

            // Content field
            Expanded(
              child: TextField(
                controller: _contentController,
                maxLines: null,
                decoration: InputDecoration(
                  hintText: "Write your note here...",
                  hintStyle: TextStyle(color: tp.inactiveColor),
                  alignLabelWithHint: true,
                  filled: true,
                  fillColor: tp.cardHighlight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: TextStyle(fontSize: 16, color: tp.primaryText),
                textAlign: TextAlign.start,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
