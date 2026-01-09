import 'package:flutter/material.dart';
import 'notes_service.dart';

class NoteEditorPage extends StatefulWidget {
  final Note note;

  const NoteEditorPage({required this.note, Key? key}) : super(key: key);

  @override
  _NoteEditorPageState createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;

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

  void _saveNote() {
    setState(() {
      widget.note.title = _titleController.text;
      widget.note.content = _contentController.text;
      widget.note.lastModified = DateTime.now();
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F4F1), // Beige background
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A5F), // Navy
        title: const Text(
          "Edit Note",
          style: TextStyle(color: Colors.white),
        ),
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
                filled: true,
                fillColor: const Color(0xFFE8DCD2), // Sand beige
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3A5F), // Navy
              ),
            ),
            const SizedBox(height: 16),

            // Content field
            Expanded(
              child: TextField(
                controller: _contentController,
                maxLines: null, // allow multiline, but no expands!
                decoration: InputDecoration(
                  hintText: "Write your note here...",
                  alignLabelWithHint: true, // ensures alignment stays top left
                  filled: true,
                  fillColor: const Color(0xFFE8DCD2), // Sand beige
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.start, // top-left by default
              ),
            ),
          ],
        ),
      ),
    );
  }
}
