import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:salat_pro/models/prayer.dart';
import 'package:salat_pro/providers/prayer_provider.dart';
import 'package:salat_pro/providers/trophy_provider.dart';
import 'package:intl/intl.dart';

class NotificationBar extends StatelessWidget {
  const NotificationBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<PrayerProvider, TrophyProvider>(
      builder: (context, prayerProvider, trophyProvider, child) {
        final nextPrayer = _getNextPrayer(prayerProvider);
        final streak = prayerProvider.getConsecutiveCompleteDays();
        final trophies = trophyProvider.allTrophies;
        final latestTrophy = trophies.isNotEmpty 
          ? trophies.reduce((a, b) => 
              a.unlockedAt.isAfter(b.unlockedAt) ? a : b)
          : null;

        return Card(
          margin: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (nextPrayer != null)
                ListTile(
                  leading: const Icon(Icons.notifications_active),
                  title: Text('Next Prayer: ${nextPrayer.name}'),
                  subtitle: Text(
                    'Scheduled for ${DateFormat('hh:mm a').format(nextPrayer.scheduledTime)}',
                  ),
                ),
              if (streak > 0)
                ListTile(
                  leading: const Icon(Icons.local_fire_department),
                  title: Text('$streak Day${streak > 1 ? 's' : ''} Streak!'),
                  subtitle: const Text('Keep up the great work!'),
                ),
              if (latestTrophy != null && 
                  DateTime.now().difference(latestTrophy.unlockedAt).inDays < 1)
                ListTile(
                  leading: Text(
                    latestTrophy.icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text('New Trophy: ${latestTrophy.name}'),
                  subtitle: Text(latestTrophy.description),
                ),
            ],
          ),
        );
      },
    );
  }

  Prayer? _getNextPrayer(PrayerProvider provider) {
    final prayers = provider.todaysPrayers;
    final now = DateTime.now();
    
    // Find the next incomplete prayer
    return prayers.firstWhere(
      (prayer) => !prayer.isCompleted && prayer.scheduledTime.isAfter(now),
      orElse: () => prayers.first, // Return first prayer if all are completed
    );
  }
} 