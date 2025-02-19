import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:salat_pro/models/prayer.dart';
import 'package:salat_pro/providers/prayer_provider.dart';
import 'package:intl/intl.dart';

class PrayerList extends StatelessWidget {
  const PrayerList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PrayerProvider>(
      builder: (context, prayerProvider, child) {
        final prayers = prayerProvider.todaysPrayers;
        
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: prayers.length,
          itemBuilder: (context, index) {
            final prayer = prayers[index];
            return PrayerListItem(prayer: prayer);
          },
        );
      },
    );
  }
}

class PrayerListItem extends StatelessWidget {
  final Prayer prayer;

  const PrayerListItem({
    super.key,
    required this.prayer,
  });

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('hh:mm a');
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
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
                  : theme.colorScheme.primary,
        ),
        title: Text(
          prayer.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Scheduled: ${timeFormat.format(prayer.scheduledTime)}'),
            if (prayer.completedTime != null)
              Text('Completed: ${timeFormat.format(prayer.completedTime!)}'),
            if (prayer.isQaza && prayer.qazaDate != null)
              Text(
                'Qaza from: ${prayer.qazaDate}',
                style: const TextStyle(
                  color: Colors.orange,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            final provider = Provider.of<PrayerProvider>(context, listen: false);
            switch (value) {
              case 'complete':
                provider.markPrayerAsCompleted(prayer, DateTime.now());
                break;
              case 'qaza':
                final now = DateTime.now();
                final dateStr = DateFormat('yyyy-MM-dd').format(now);
                provider.markPrayerAsQaza(prayer, dateStr);
                break;
              case 'reset':
                provider.resetPrayer(prayer);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'complete',
              child: Text('Mark as Completed'),
            ),
            const PopupMenuItem(
              value: 'qaza',
              child: Text('Mark as Qaza'),
            ),
            const PopupMenuItem(
              value: 'reset',
              child: Text('Reset'),
            ),
          ],
        ),
      ),
    );
  }
} 