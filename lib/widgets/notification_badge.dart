import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:salat_pro/models/prayer.dart';
import 'package:salat_pro/providers/prayer_provider.dart';
import 'package:intl/intl.dart';

class NotificationBadge extends StatelessWidget {
  const NotificationBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PrayerProvider>(
      builder: (context, provider, child) {
        final nextPrayer = _getNextPrayer(provider);
        final uncompletedPrayers = _getUncompletedPrayers(provider);
        
        return Badge(
          label: Text(uncompletedPrayers.length.toString()),
          isLabelVisible: uncompletedPrayers.isNotEmpty,
          child: IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => _showNotificationsDialog(
              context, 
              nextPrayer,
              uncompletedPrayers,
            ),
          ),
        );
      },
    );
  }

  List<Prayer> _getUncompletedPrayers(PrayerProvider provider) {
    final prayers = provider.todaysPrayers;
    final now = DateTime.now();
    return prayers.where((prayer) => 
      !prayer.isCompleted && 
      prayer.scheduledTime.isBefore(now)
    ).toList();
  }

  Prayer? _getNextPrayer(PrayerProvider provider) {
    final prayers = provider.todaysPrayers;
    final now = DateTime.now();
    
    try {
      return prayers.firstWhere(
        (prayer) => !prayer.isCompleted && prayer.scheduledTime.isAfter(now),
      );
    } catch (e) {
      return null;
    }
  }

  void _showNotificationsDialog(
    BuildContext context,
    Prayer? nextPrayer,
    List<Prayer> uncompletedPrayers,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Prayer Notifications'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (nextPrayer != null) ...[
                Text(
                  'Next Prayer',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.access_time),
                  title: Text(nextPrayer.name),
                  subtitle: Text(
                    'At ${DateFormat('hh:mm a').format(nextPrayer.scheduledTime)}',
                  ),
                ),
                const Divider(),
              ],
              if (uncompletedPrayers.isNotEmpty) ...[
                Text(
                  'Missed Prayers',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ...uncompletedPrayers.map((prayer) => ListTile(
                  leading: const Icon(Icons.warning, color: Colors.orange),
                  title: Text(prayer.name),
                  subtitle: Text(
                    'Scheduled for ${DateFormat('hh:mm a').format(prayer.scheduledTime)}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.check_circle_outline),
                    onPressed: () {
                      Provider.of<PrayerProvider>(context, listen: false)
                          .markPrayerAsCompleted(prayer, DateTime.now());
                      Navigator.pop(context);
                    },
                  ),
                )),
              ],
              if (nextPrayer == null && uncompletedPrayers.isEmpty)
                const Text('No pending prayers for today!'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
} 