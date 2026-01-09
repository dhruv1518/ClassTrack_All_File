import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'notes_service.dart';
import 'note_editor_page.dart';

class NotesListPage extends StatefulWidget {
  final Category category;
  NotesListPage({required this.category});

  @override
  _NotesListPageState createState() => _NotesListPageState();
}

class _NotesListPageState extends State<NotesListPage> {
  Future<void> _openNoteEditor(Note note) async {
    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            NoteEditorPage(note: note),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
    setState(() {});
  }

  Future<bool?> _confirmDeleteDialog(Note note) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            "Delete Note",
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            "Are you sure you want to delete this note?",
            style: TextStyle(color: theme.colorScheme.onSurface),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel", style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Delete", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      colorScheme: ColorScheme.light(
        primary: const Color(0xFF1B3C53),
        secondary: const Color(0xFF4A90E2),
        surface: const Color(0xFFF8F4F1),
        background: const Color(0xFFF5F3E7),
        onSurface: const Color(0xFF444444),
      ),
      scaffoldBackgroundColor: const Color(0xFFF5F3E7),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1B3C53),
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
            color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        elevation: 0,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF4A90E2),
      ),
      listTileTheme: const ListTileThemeData(
        tileColor: Color(0xFFF8F4F1),
        textColor: Color(0xFF1B365D),
      ),
    );

    return Theme(
      data: theme,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.category.name),
        ),
        body: widget.category.notes.isEmpty
            ? Center(
          child: Text(
            'No notes in this category yet.',
            style:
            TextStyle(fontSize: 18, color: theme.colorScheme.onSurface),
          ),
        )
            : ListView.builder(
          itemCount: widget.category.notes.length,
          itemBuilder: (context, index) {
            final note = widget.category.notes[index];
            return Dismissible(
              key: ValueKey(note.lastModified.toIso8601String() + note.title),
              direction: DismissDirection.endToStart,
              background: Container(
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.centerRight,
                padding: EdgeInsets.only(right: 24),
                child: Icon(Icons.delete, color: Colors.white, size: 32),
              ),
              confirmDismiss: (direction) async {
                return await _confirmDeleteDialog(note);
              },
              onDismissed: (direction) {
                setState(() {
                  widget.category.notes.removeAt(index);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Note deleted'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.listTileTheme.tileColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(2, 2),
                    )
                  ],
                ),
                child: ListTile(
                  title: Text(
                    note.title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary),
                  ),
                  subtitle: Text(
                    'Last modified: ${DateFormat.yMMMd().format(note.lastModified)}',
                    style: TextStyle(color: theme.colorScheme.onSurface),
                  ),
                  onTap: () => _openNoteEditor(note),
                  onLongPress: () async {
                    final confirm = await _confirmDeleteDialog(note);
                    if (confirm == true) {
                      setState(() {
                        widget.category.notes.remove(note);
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Note deleted'), backgroundColor: Colors.red),
                      );
                    }
                  },
                ),
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            final newNote = Note(
              title: '',
              content: '',
              lastModified: DateTime.now(),
            );
            widget.category.notes.add(newNote);
            _openNoteEditor(newNote);
          },
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}
