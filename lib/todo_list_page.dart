import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import 'todo_service.dart';
import 'analytics_service.dart';

class ToDoListPage extends StatefulWidget {
  @override
  _ToDoListPageState createState() => _ToDoListPageState();
}

class _ToDoListPageState extends State<ToDoListPage> {
  final ToDoService _toDoService = ToDoService();
  final TextEditingController _taskController = TextEditingController();

  void _addTask() async {
    if (_taskController.text.isNotEmpty) {
      final newTask = Task(
        id: UniqueKey().toString(),
        title: _taskController.text,
        isDone: false,
        dueDate: DateTime.now(),
      );
      await _toDoService.addTask(newTask);
      await _toDoService.fetchTasks(); // <--- ensures task shows instantly
      _taskController.clear();
      setState(() {});
      Navigator.of(context).pop();
    }
  }

  void _showAddTaskDialog() {
    final tp = Provider.of<ThemeProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: tp.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text('Add a new task', style: TextStyle(color: tp.primaryText)),
        content: TextField(
          controller: _taskController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Enter task here...',
            hintStyle: TextStyle(color: tp.secondaryText.withOpacity(0.7)),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: tp.secondaryText),
            ),
          ),
          style: TextStyle(color: tp.primaryText),
        ),
        actions: [
          TextButton(
            child: Text('Cancel', style: TextStyle(color: tp.secondaryText)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: tp.secondaryText,
              foregroundColor: Colors.white,
            ),
            child: Text('Add'),
            onPressed: _addTask,
          ),
        ],
      ),
    );
  }

  void _showTaskCompletedDialog(Task task, int index) async {
    final tp = Provider.of<ThemeProvider>(context, listen: false);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: tp.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text('Task Completed!', style: TextStyle(color: tp.primaryText)),
        content: Container(
          decoration: BoxDecoration(color: Colors.transparent),
          child: Text(
            'You have completed:\n\n"${task.title}"',
            style: TextStyle(color: tp.primaryText),
          ),
        ),
        actions: [
          TextButton(
            child: Text('Delete Task', style: TextStyle(color: Colors.red)),
            onPressed: () async {
              Navigator.of(context).pop();
              await _toDoService.deleteTask(task);
              await _toDoService.fetchTasks();
              setState(() {});
            },
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: tp.secondaryText,
              foregroundColor: Colors.white,
            ),
            child: Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _toDoService.fetchTasks();
  }

  @override
  Widget build(BuildContext context) {
    final tp = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: tp.scaffoldBg,
      appBar: AppBar(
        title: Text(
          'My To-Do List',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: tp.appBarBg,
        elevation: 4,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: _toDoService.tasks.isEmpty
          ? Center(
              child: Text(
                'No tasks yet. Add one!',
                style: TextStyle(
                  fontSize: 18,
                  color: tp.secondaryText,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(12),
              itemCount: _toDoService.tasks.length,
              itemBuilder: (context, index) {
                final task = _toDoService.tasks[index];
                return Dismissible(
                  key: Key(task.id),
                  onDismissed: (direction) async {
                    await _toDoService.deleteTask(task);
                    await _toDoService.fetchTasks();
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${task.title} deleted'),
                        backgroundColor: tp.secondaryText,
                      ),
                    );
                  },
                  background: Container(
                    color: Colors.redAccent,
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.symmetric(horizontal: 20.0),
                    child: Icon(Icons.delete, color: Colors.white),
                  ),
                  child: Card(
                    color: tp.cardBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                    margin: EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: Checkbox(
                        activeColor: tp.secondaryText,
                        value: task.isDone,
                        onChanged: (bool? value) async {
                          if (value == true && !task.isDone) {
                            task.isDone = true;
                            await _toDoService.updateTask(task);
                            await _toDoService.fetchTasks();
                            setState(() {});
                            // 📊 Track task completion
                            final uid = FirebaseAuth.instance.currentUser?.uid;
                            if (uid != null) {
                              AnalyticsService.trackTaskCompleted(uid);
                            }
                            _showTaskCompletedDialog(task, index);
                          } else if (value == false) {
                            task.isDone = false;
                            await _toDoService.updateTask(task);
                            await _toDoService.fetchTasks();
                            setState(() {});
                          }
                        },
                        checkColor: Colors.white,
                      ),
                      title: Text(
                        task.title,
                        style: TextStyle(
                          decoration: task.isDone
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          color: task.isDone
                              ? tp.inactiveColor
                              : tp.primaryText,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: task.isDone
                          ? Text(
                              'Completed',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        child: Icon(Icons.add, color: Colors.white),
        backgroundColor: tp.secondaryText,
      ),
    );
  }
}
