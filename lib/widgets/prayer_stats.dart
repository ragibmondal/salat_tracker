import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:salat_pro/providers/prayer_provider.dart';

class PrayerStats extends StatelessWidget {
  const PrayerStats({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PrayerProvider>(
      builder: (context, prayerProvider, child) {
        final streak = prayerProvider.getConsecutiveCompleteDays();
        final todayPercentage = prayerProvider.getCompletionPercentage(DateTime.now());
        final completedToday = prayerProvider.todaysPrayers.where((p) => p.isCompleted).length;
        final totalToday = prayerProvider.todaysPrayers.length;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _StatItem(
                      title: 'Streak',
                      value: '$streak days',
                      icon: Icons.local_fire_department,
                      color: Colors.orange,
                    ),
                    _StatItem(
                      title: "Today's Progress",
                      value: '$completedToday/$totalToday',
                      icon: Icons.check_circle_outline,
                      color: Colors.green,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: todayPercentage,
                  minHeight: 10,
                  backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatItem extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 32,
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
} 