import 'package:flutter/material.dart';
import 'notes_service.dart'; // Renamed from notes/notes_service.dart if moved
import 'notes_list_page.dart'; // Renamed from notes/notes_list_page.dart if moved

class CategoriesPage extends StatefulWidget {
  @override
  _CategoriesPageState createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final NotesService _notesService = NotesService();
  final TextEditingController _categoryController = TextEditingController();

  void _addCategory() {
    if (_categoryController.text.isNotEmpty) {
      setState(() {
        _notesService.categories.add(Category(name: _categoryController.text));
      });
      Navigator.of(context).pop();
      _categoryController.clear();
    }
  }

  void _showAddCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('New Category'),
        content: TextField(
          controller: _categoryController,
          autofocus: true,
          decoration: InputDecoration(hintText: 'Enter category name'),
        ),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            child: Text('Add'),
            onPressed: _addCategory,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = _notesService.categories;

    return Scaffold(
      appBar: AppBar(
        title: Text('Note Categories'),
      ),
      body: categories.isEmpty
          ? Center(
        child: Text(
          'No categories yet.\nTap the + button to add one!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      )
          : ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return Dismissible(
            key: ValueKey(category.name),
            direction: DismissDirection.endToStart, // swipe left to delete
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: EdgeInsets.only(right: 24),
              child: Icon(Icons.delete, color: Colors.white, size: 32),
            ),
            confirmDismiss: (direction) async {
              return await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Delete Category'),
                  content: Text(
                    'Are you sure you want to delete the category "${category.name}"?\n\n'
                        'All notes inside this category will also be deleted. This action cannot be undone.',
                    style: TextStyle(fontSize: 15),
                  ),
                  actions: [
                    TextButton(
                      child: Text('Cancel'),
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: Text('Delete', style: TextStyle(color: Colors.white)),
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                  ],
                ),
              );
            },
            onDismissed: (direction) {
              setState(() {
                _notesService.categories.removeAt(index);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Category and notes deleted'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: ListTile(
              title: Text(category.name, style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${category.notes.length} notes'),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => NotesListPage(category: category),
                  ),
                );
                setState(() {});
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCategoryDialog,
        child: Icon(Icons.add),
      ),
    );
  }
}
