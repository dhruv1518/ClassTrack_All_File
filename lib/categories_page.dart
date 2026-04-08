import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import 'notes_service.dart';
import 'notes_list_page.dart';

class CategoriesPage extends StatefulWidget {
  @override
  _CategoriesPageState createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final NotesService _notesService = NotesService();
  final TextEditingController _categoryController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _notesService.addListener(_onDataChanged);
    _loadCategories();
  }

  @override
  void dispose() {
    _notesService.removeListener(_onDataChanged);
    _categoryController.dispose();
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadCategories() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _notesService.setUser(user.uid);
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addCategory() async {
    if (_categoryController.text.isNotEmpty) {
      Navigator.of(context).pop();
      await _notesService.addCategory(_categoryController.text);
      _categoryController.clear();
    }
  }

  void _showAddCategoryDialog() {
    final tp = Provider.of<ThemeProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: tp.cardBg,
        title: Text('New Category', style: TextStyle(color: tp.primaryText)),
        content: TextField(
          controller: _categoryController,
          autofocus: true,
          style: TextStyle(color: tp.primaryText),
          decoration: InputDecoration(
            hintText: 'Enter category name',
            hintStyle: TextStyle(color: tp.inactiveColor),
          ),
        ),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(child: const Text('Add'), onPressed: _addCategory),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tp = Provider.of<ThemeProvider>(context);
    final categories = _notesService.categories;

    return Scaffold(
      backgroundColor: tp.scaffoldBg,
      appBar: AppBar(
        title: Text('Note Categories', style: TextStyle(color: Colors.white)),
        backgroundColor: tp.appBarBg,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : categories.isEmpty
          ? Center(
              child: Text(
                'No categories yet.\nTap the + button to add one!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: tp.inactiveColor),
              ),
            )
          : ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];

                return Dismissible(
                  key: ValueKey(category.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  confirmDismiss: (direction) async {
                    return await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Delete Category'),
                        content: Text(
                          'Are you sure you want to delete the category '
                          '"${category.name}"?\n\n'
                          'All notes inside this category will also be deleted. '
                          'This action cannot be undone.',
                          style: const TextStyle(fontSize: 15),
                        ),
                        actions: [
                          TextButton(
                            child: const Text('Cancel'),
                            onPressed: () => Navigator.of(context).pop(false),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: const Text(
                              'Delete',
                              style: TextStyle(color: Colors.white),
                            ),
                            onPressed: () => Navigator.of(context).pop(true),
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (direction) async {
                    await _notesService.deleteCategory(category.id);

                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Category and notes deleted'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  },
                  child: ListTile(
                    title: Text(
                      category.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: tp.primaryText,
                      ),
                    ),
                    subtitle: Text(
                      '${category.notes.length} notes',
                      style: TextStyle(color: tp.secondaryText),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      color: tp.iconColor,
                    ),
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              NotesListPage(category: category),
                        ),
                      );
                      // Refresh after returning from notes list
                      await _notesService.fetchCategories();
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCategoryDialog,
        backgroundColor: tp.appBarBg,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
