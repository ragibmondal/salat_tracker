import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:salat_pro/providers/prayer_provider.dart';
import 'package:salat_pro/models/prayer.dart';
import 'package:intl/intl.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prayer History'),
      ),
      body: Consumer<PrayerProvider>(
        builder: (context, prayerProvider, child) {
          return Column(
            children: [
              TableCalendar(
                firstDay: DateTime.utc(2024, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                  prayerProvider.setSelectedDate(selectedDay);
                },
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                calendarStyle: CalendarStyle(
                  markerDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, date, events) {
                    final percentage = prayerProvider.getCompletionPercentage(date);
                    if (percentage > 0) {
                      return Positioned(
                        bottom: 1,
                        child: Container(
                          width: 35,
                          height: 3,
                          decoration: BoxDecoration(
                            color: _getColorForPercentage(percentage),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }
                    return null;
                  },
                ),
              ),
              const Divider(),
              if (_selectedDay != null) ...[
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Prayers for ${DateFormat('MMMM d, y').format(_selectedDay!)}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Expanded(
                  child: _buildPrayerList(prayerProvider.getPrayersForDate(_selectedDay!)),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Color _getColorForPercentage(double percentage) {
    if (percentage >= 1.0) return Colors.green;
    if (percentage >= 0.7) return Colors.lightGreen;
    if (percentage >= 0.4) return Colors.orange;
    return Colors.red;
  }

  Widget _buildPrayerList(List<Prayer> prayers) {
    return ListView.builder(
      itemCount: prayers.length,
      itemBuilder: (context, index) {
        final prayer = prayers[index];
        final timeFormat = DateFormat('hh:mm a');

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: Icon(
              prayer.isCompleted
                  ? Icons.check_circle
                  : prayer.isQaza
                      ? Icons.warning
                      : Icons.schedule,
              color: prayer.isCompleted
                  ? Colors.green
                  : prayer.isQaza
                      ? Colors.orange
                      : Theme.of(context).colorScheme.primary,
            ),
            title: Text(prayer.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Scheduled: ${timeFormat.format(prayer.scheduledTime)}'),
                if (prayer.completedTime != null)
                  Text('Completed: ${timeFormat.format(prayer.completedTime!)}'),
                if (prayer.isQaza) const Text('Status: Qaza', style: TextStyle(color: Colors.orange)),
              ],
            ),
          ),
        );
      },
    );
  }
} 