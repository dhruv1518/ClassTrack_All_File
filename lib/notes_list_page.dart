import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import 'notes_service.dart';
import 'note_editor_page.dart';

class NotesListPage extends StatefulWidget {
  final Category category;

  NotesListPage({required this.category});

  @override
  _NotesListPageState createState() => _NotesListPageState();
}

class _NotesListPageState extends State<NotesListPage> {
  final NotesService _notesService = NotesService();

  Future<void> _openNoteEditor(Note note, {bool isNewNote = false}) async {
    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => NoteEditorPage(
          note: note,
          categoryId: widget.category.id,
          isNewNote: isNewNote,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
    // Refresh from Firestore after editing
    await _notesService.fetchCategories();
    _refreshCategory();
  }

  void _refreshCategory() {
    // Find the updated version of this category from the service
    final updated = _notesService.categories.firstWhere(
      (c) => c.id == widget.category.id,
      orElse: () => widget.category,
    );
    setState(() {
      widget.category.notes
        ..clear()
        ..addAll(updated.notes);
    });
  }

  Future<bool?> _confirmDeleteDialog(Note note) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text("Delete Note"),
          content: Text("Are you sure you want to delete this note?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel", style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                "Delete",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tp = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: tp.scaffoldBg,
      appBar: AppBar(
        title: Text(
          widget.category.name,
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: tp.appBarBg,
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: widget.category.notes.isEmpty
          ? Center(
              child: Text(
                'No notes in this category yet.',
                style: TextStyle(fontSize: 18, color: tp.secondaryText),
              ),
            )
          : ListView.builder(
              itemCount: widget.category.notes.length,
              itemBuilder: (context, index) {
                final note = widget.category.notes[index];

                return Dismissible(
                  key: ValueKey(note.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  confirmDismiss: (direction) async {
                    return await _confirmDeleteDialog(note);
                  },
                  onDismissed: (direction) async {
                    await _notesService.deleteNote(widget.category.id, note.id);
                    _refreshCategory();

                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Note deleted'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: tp.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: tp.shadowColor,
                          blurRadius: 4,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      title: Text(
                        note.title.isEmpty ? 'Untitled' : note.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: tp.primaryText,
                        ),
                      ),
                      subtitle: Text(
                        'Last modified: ${DateFormat.yMMMd().format(note.lastModified)}',
                        style: TextStyle(color: tp.secondaryText),
                      ),
                      onTap: () => _openNoteEditor(note),
                      onLongPress: () async {
                        final confirm = await _confirmDeleteDialog(note);
                        if (confirm == true) {
                          await _notesService.deleteNote(
                            widget.category.id,
                            note.id,
                          );
                          _refreshCategory();
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Note deleted'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: tp.appBarBg,
        onPressed: () async {
          final newNote = await _notesService.addNote(widget.category.id);
          _refreshCategory();
          _openNoteEditor(newNote, isNewNote: true);
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
