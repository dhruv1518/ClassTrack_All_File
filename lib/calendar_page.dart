import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';
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

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = _focusedDay;
    _calendarService.fetchEvents().then((_) {
      if (mounted) setState(() {});
    });
  }

  List<CalendarEvent> _getEventsForDay(DateTime day) {
    return _calendarService.events
        .where((event) => isSameDay(event.date, day))
        .toList();
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
        title: Text('Delete Event?'),
        content: Text('Are you sure you want to delete "${event.title}"?'),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete', style: TextStyle(color: Colors.white)),
            onPressed: () async {
              Navigator.of(context).pop();
              await _calendarService.deleteEvent(event.id);
              if (mounted) setState(() {});
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tp = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: tp.scaffoldBg,
      appBar: AppBar(
        title: Text(
          'Calendar',
          style: TextStyle(color: tp.primaryText, fontWeight: FontWeight.bold),
        ),
        backgroundColor: tp.scaffoldBg,
        elevation: 0,
        iconTheme: IconThemeData(color: tp.iconColor),
        actions: [
          IconButton(
            icon: Icon(Icons.today, color: tp.iconColor),
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
                color: tp.iconColor,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [tp.gradientStart, tp.gradientEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              defaultTextStyle: TextStyle(color: tp.primaryText),
              weekendTextStyle: TextStyle(color: tp.secondaryText),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                color: tp.primaryText,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              leftChevronIcon: Icon(Icons.chevron_left, color: tp.iconColor),
              rightChevronIcon: Icon(Icons.chevron_right, color: tp.iconColor),
            ),
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: Builder(
              builder: (context) {
                final selectedDayEvents = _getEventsForDay(_selectedDay);
                return ListView.builder(
                  itemCount: selectedDayEvents.length,
                  itemBuilder: (context, index) {
                    final event = selectedDayEvents[index];
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [tp.cardBg, tp.cardHighlight],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: event.category.color,
                            child: event.hasReminder
                                ? Icon(
                                    Icons.notifications,
                                    color: Colors.white,
                                    size: 16,
                                  )
                                : null,
                          ),
                          title: Text(
                            event.title,
                            style: TextStyle(color: tp.primaryText),
                          ),
                          subtitle: Text(
                            DateFormat.jm().format(event.date),
                            style: TextStyle(color: tp.secondaryText),
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              Icons.delete_outline,
                              color: tp.accentCoral,
                            ),
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
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [tp.gradientStart, tp.gradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
        ),
        child: FloatingActionButton(
          onPressed: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) =>
                    EventEditorPage(selectedDate: _selectedDay),
              ),
            );
            setState(() {});
          },
          child: Icon(Icons.add, color: tp.scaffoldBg),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
    );
  }
}
