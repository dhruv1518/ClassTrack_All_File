import 'package:flutter/material.dart';
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

  // 🎨 Same palette as CalendarPage
  final Color kMainBackground = const Color(0xFFFAF6F2);
  final Color kCardBackground = const Color(0xFFF5EFEA);
  final Color kCardHighlight = const Color(0xFFEAE2DC);
  final Color kPrimaryText = const Color(0xFF1D2B36);
  final Color kSecondaryText = const Color(0xFF6D7B85);
  final Color kIcon = const Color(0xFF2E4057);
  final Color kInactive = const Color(0xFF8D99A6);
  final Color kFabStart = const Color(0xFF2C3E50);
  final Color kFabEnd = const Color(0xFF496D91);

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.event?.date ?? widget.selectedDate;
    _titleController.text = widget.event?.title ?? '';
    _selectedCategory = widget.event?.category ?? _calendarService.categories.first;
    _hasReminder = widget.event?.hasReminder ?? false;
  }

  void _saveEvent() {
    if (_titleController.text.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: kCardBackground,
          title: Text('Missing Title', style: TextStyle(color: kPrimaryText)),
          content: Text('Please enter a title for the event.', style: TextStyle(color: kSecondaryText)),
          actions: [
            TextButton(
              child: Text('OK', style: TextStyle(color: kInactive)),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
      return;
    }

    final eventToSave = CalendarEvent(
      title: _titleController.text,
      date: _selectedDate,
      category: _selectedCategory,
      hasReminder: _hasReminder,
    );

    if (widget.event == null) {
      _calendarService.events.add(eventToSave);
    } else {
      final index = _calendarService.events.indexWhere((e) => e.id == widget.event!.id);
      if (index != -1) {
        _calendarService.events[index] = eventToSave;
      }
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kMainBackground,
      appBar: AppBar(
        title: Text(
          widget.event == null ? 'New Event' : 'Edit Event',
          style: TextStyle(color: kPrimaryText, fontWeight: FontWeight.bold),
        ),
        backgroundColor: kMainBackground,
        elevation: 0,
        iconTheme: IconThemeData(color: kIcon),
        actions: [
          IconButton(
            icon: Icon(Icons.save, color: kIcon),
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
              style: TextStyle(color: kPrimaryText),
              decoration: InputDecoration(
                labelText: 'Event Title',
                labelStyle: TextStyle(color: kSecondaryText),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: kInactive),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: kIcon),
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Date: ${_selectedDate.toLocal().toString().split(' ')[0]}',
              style: TextStyle(color: kSecondaryText),
            ),
            SizedBox(height: 20),
            DropdownButtonFormField<EventCategory>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Category',
                labelStyle: TextStyle(color: kSecondaryText),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: kInactive),
                ),
              ),
              dropdownColor: kCardBackground,
              style: TextStyle(color: kPrimaryText),
              onChanged: (EventCategory? newValue) {
                setState(() {
                  _selectedCategory = newValue!;
                });
              },
              items: _calendarService.categories.map((EventCategory category) {
                return DropdownMenuItem<EventCategory>(
                  value: category,
                  child: Text(category.name, style: TextStyle(color: kPrimaryText)),
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            SwitchListTile(
              title: Text('Set Reminder', style: TextStyle(color: kPrimaryText)),
              value: _hasReminder,
              activeColor: kFabEnd,
              activeTrackColor: kFabStart.withOpacity(0.5),
              inactiveThumbColor: kInactive,
              inactiveTrackColor: kSecondaryText.withOpacity(0.3),
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
