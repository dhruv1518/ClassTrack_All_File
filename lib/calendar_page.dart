import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'calendar_service.dart';
import 'event_editor_page.dart';

class CalendarPage extends StatefulWidget {
  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final CalendarService _calendarService = CalendarService();
  late DateTime _focusedDay;
  late DateTime _selectedDay;

  // 🎨 Palette from your UI image
  final Color kMainBackground = const Color(0xFFFAF6F2); // page bg
  final Color kCardBackground = const Color(0xFFF5EFEA); // card beige
  final Color kCardHighlight = const Color(0xFFEAE2DC); // beige gradient stop
  final Color kPrimaryText = const Color(0xFF1D2B36); // dark titles
  final Color kSecondaryText = const Color(0xFF6D7B85); // gray-blue subtitles
  final Color kIcon = const Color(0xFF2E4057); // navy icons
  final Color kInactive = const Color(0xFF8D99A6); // inactive gray
  final Color kFabStart = const Color(0xFF2C3E50); // FAB gradient start
  final Color kFabEnd = const Color(0xFF496D91); // FAB gradient end

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = _focusedDay;
  }

  List<CalendarEvent> _getEventsForDay(DateTime day) {
    return _calendarService.events.where((event) => isSameDay(event.date, day)).toList();
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
  }

  void _showDeleteConfirmation(CalendarEvent event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Event?', style: TextStyle(color: kPrimaryText)),
        content: Text(
          'Are you sure you want to delete "${event.title}"?',
          style: TextStyle(color: kSecondaryText),
        ),
        actions: [
          TextButton(
            child: Text('Cancel', style: TextStyle(color: kInactive)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete', style: TextStyle(color: Colors.white)),
            onPressed: () {
              setState(() {
                _calendarService.events.removeWhere((e) => e.id == event.id);
              });
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kMainBackground,
      appBar: AppBar(
        title: Text(
          'Calendar',
          style: TextStyle(color: kPrimaryText, fontWeight: FontWeight.bold),
        ),
        backgroundColor: kMainBackground,
        elevation: 0,
        iconTheme: IconThemeData(color: kIcon),
        actions: [
          IconButton(
            icon: Icon(Icons.today, color: kIcon),
            onPressed: () {
              setState(() {
                _focusedDay = DateTime.now();
                _selectedDay = _focusedDay;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: _onDaySelected,
            eventLoader: _getEventsForDay,
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: kIcon,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kFabStart, kFabEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              defaultTextStyle: TextStyle(color: kPrimaryText),
              weekendTextStyle: TextStyle(color: kSecondaryText),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                color: kPrimaryText,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              leftChevronIcon: Icon(Icons.chevron_left, color: kIcon),
              rightChevronIcon: Icon(Icons.chevron_right, color: kIcon),
            ),
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: ListView.builder(
              itemCount: _getEventsForDay(_selectedDay).length,
              itemBuilder: (context, index) {
                final event = _getEventsForDay(_selectedDay)[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [kCardBackground, kCardHighlight],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: event.category.color,
                        child: event.hasReminder
                            ? Icon(Icons.notifications, color: Colors.white, size: 16)
                            : null,
                      ),
                      title: Text(event.title, style: TextStyle(color: kPrimaryText)),
                      subtitle: Text(
                        DateFormat.jm().format(event.date),
                        style: TextStyle(color: kSecondaryText),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete_outline, color: Colors.red[700]),
                        onPressed: () => _showDeleteConfirmation(event),
                      ),
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => EventEditorPage(
                              selectedDate: _selectedDay,
                              event: event,
                            ),
                          ),
                        );
                        setState(() {});
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [kFabStart, kFabEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
        ),
        child: FloatingActionButton(
          onPressed: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => EventEditorPage(selectedDate: _selectedDay),
              ),
            );
            setState(() {});
          },
          child: Icon(Icons.add, color: kMainBackground),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
    );
  }
}
