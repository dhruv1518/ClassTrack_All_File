import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import 'calendar_service.dart';

class EventEditorPage extends StatefulWidget {
  final DateTime selectedDate;
  final CalendarEvent? event;

  EventEditorPage({required this.selectedDate, this.event});

  @override
  _EventEditorPageState createState() => _EventEditorPageState();
}

class _EventEditorPageState extends State<EventEditorPage> {
  final _titleController = TextEditingController();
  final CalendarService _calendarService = CalendarService();
  late DateTime _selectedDate;
  late EventCategory _selectedCategory;
  late bool _hasReminder;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.event?.date ?? widget.selectedDate;
    _titleController.text = widget.event?.title ?? '';
    _selectedCategory =
        widget.event?.category ?? _calendarService.categories.first;
    _hasReminder = widget.event?.hasReminder ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _saveEvent() async {
    final tp = Provider.of<ThemeProvider>(context, listen: false);
    if (_titleController.text.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: tp.cardBg,
          title: Text('Missing Title', style: TextStyle(color: tp.primaryText)),
          content: Text(
            'Please enter a title for the event.',
            style: TextStyle(color: tp.secondaryText),
          ),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
      return;
    }

    if (widget.event == null) {
      // Creating a new event
      final newEvent = CalendarEvent.create(
        title: _titleController.text,
        date: _selectedDate,
        category: _selectedCategory,
        hasReminder: _hasReminder,
      );
      await _calendarService.addEvent(newEvent);
    } else {
      // Editing existing event — update in-place to preserve ID
      final updated = CalendarEvent(
        id: widget.event!.id,
        title: _titleController.text,
        date: _selectedDate,
        category: _selectedCategory,
        hasReminder: _hasReminder,
      );
      await _calendarService.updateEvent(updated);
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final tp = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: tp.scaffoldBg,
      appBar: AppBar(
        title: Text(
          widget.event == null ? 'New Event' : 'Edit Event',
          style: TextStyle(color: tp.primaryText, fontWeight: FontWeight.bold),
        ),
        backgroundColor: tp.scaffoldBg,
        elevation: 0,
        iconTheme: IconThemeData(color: tp.iconColor),
        actions: [
          IconButton(
            icon: Icon(Icons.save, color: tp.iconColor),
            onPressed: _saveEvent,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: _titleController,
              style: TextStyle(color: tp.primaryText),
              decoration: InputDecoration(
                labelText: 'Event Title',
                labelStyle: TextStyle(color: tp.secondaryText),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: tp.inactiveColor),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: tp.iconColor),
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Date: ${_selectedDate.toLocal().toString().split(' ')[0]}',
              style: TextStyle(color: tp.secondaryText),
            ),
            SizedBox(height: 20),
            DropdownButtonFormField<EventCategory>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Category',
                labelStyle: TextStyle(color: tp.secondaryText),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: tp.inactiveColor),
                ),
              ),
              dropdownColor: tp.cardBg,
              style: TextStyle(color: tp.primaryText),
              onChanged: (EventCategory? newValue) {
                setState(() {
                  _selectedCategory = newValue!;
                });
              },
              items: _calendarService.categories.map((EventCategory category) {
                return DropdownMenuItem<EventCategory>(
                  value: category,
                  child: Text(
                    category.name,
                    style: TextStyle(color: tp.primaryText),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            SwitchListTile(
              title: Text(
                'Set Reminder',
                style: TextStyle(color: tp.primaryText),
              ),
              value: _hasReminder,
              activeColor: tp.gradientEnd,
              activeTrackColor: tp.gradientStart.withOpacity(0.5),
              inactiveThumbColor: tp.inactiveColor,
              inactiveTrackColor: tp.secondaryText.withOpacity(0.3),
              onChanged: (bool value) {
                setState(() {
                  _hasReminder = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
