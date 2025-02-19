import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:salat_pro/models/prayer.dart';
import 'package:salat_pro/providers/prayer_provider.dart';
import 'package:salat_pro/providers/theme_provider.dart';
import 'package:salat_pro/widgets/prayer_list.dart';
import 'package:salat_pro/widgets/prayer_stats.dart';
import 'package:salat_pro/screens/settings_screen.dart';
import 'package:salat_pro/screens/calendar_screen.dart';
import 'package:salat_pro/screens/statistics_screen.dart';
import 'package:salat_pro/widgets/notification_badge.dart';
import 'package:salat_pro/widgets/notification_bar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SalatTracker Pro'),
        actions: [
          IconButton(
            icon: Icon(
              Provider.of<ThemeProvider>(context).isDarkMode
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: () {
              Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
            },
          ),
          const NotificationBadge(),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'calendar':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CalendarScreen(),
                    ),
                  );
                  break;
                case 'statistics':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StatisticsScreen(),
                    ),
                  );
                  break;
                case 'settings':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'calendar',
                child: Row(
                  children: [
                    Icon(Icons.calendar_month),
                    SizedBox(width: 8),
                    Text('Prayer History'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'statistics',
                child: Row(
                  children: [
                    Icon(Icons.bar_chart),
                    SizedBox(width: 8),
                    Text('Statistics'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('Settings'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<PrayerProvider>(
        builder: (context, provider, child) {
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: NotificationBar(),
                ),
              ),
              const SliverPadding(
                padding: EdgeInsets.all(8.0),
                sliver: PrayerListView(),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Consumer<PrayerProvider>(
        builder: (context, provider, child) {
          final prayers = provider.todaysPrayers;
          if (prayers.isEmpty) return const SizedBox.shrink();
          
          return FloatingActionButton(
            onPressed: () {
              final now = DateTime.now();
              final prayer = prayers.firstWhere(
                (p) => !p.isCompleted,
                orElse: () => prayers.last,
              );

              provider.markPrayerAsCompleted(prayer, now);
            },
            child: const Icon(Icons.check),
          );
        },
      ),
    );
  }
}

class PrayerListView extends StatelessWidget {
  const PrayerListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<PrayerProvider>(
      builder: (context, provider, child) {
        if (!provider.isInitialized) {
          return const SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final prayers = provider.todaysPrayers;
        
        if (prayers.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.warning, size: 48, color: Colors.orange),
                  const SizedBox(height: 16),
                  Text(
                    'No prayers found for today',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      provider.initializePrayersForDate(DateTime.now());
                    },
                    child: const Text('Initialize Prayers'),
                  ),
                ],
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index >= prayers.length) return null;
              final prayer = prayers[index];
              
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: RepaintBoundary(
                  child: Card(
                    child: ListTile(
                      title: Text(
                        prayer.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Scheduled: ${TimeOfDay.fromDateTime(prayer.scheduledTime).format(context)}',
                          ),
                          if (prayer.completedTime != null)
                            Text(
                              'Completed: ${TimeOfDay.fromDateTime(prayer.completedTime!).format(context)}',
                              style: const TextStyle(color: Colors.green),
                            ),
                          if (prayer.isQaza && prayer.qazaDate != null)
                            Text(
                              'Qaza from: ${prayer.qazaDate}',
                              style: const TextStyle(color: Colors.orange),
                            ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (prayer.isCompleted)
                            const Icon(Icons.check_circle, color: Colors.green)
                          else if (prayer.isQaza)
                            const Icon(Icons.warning, color: Colors.orange)
                          else
                            Icon(Icons.circle_outlined, 
                              color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Icon(Icons.more_vert, 
                            color: Theme.of(context).colorScheme.primary),
                        ],
                      ),
                      onTap: () => _showPrayerActions(context, prayer, provider),
                    ),
                  ),
                ),
              );
            },
            childCount: prayers.length,
          ),
        );
      },
    );
  }

  void _showPrayerActions(BuildContext context, Prayer prayer, PrayerProvider provider) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.check_circle, color: Colors.green),
            title: const Text('Mark as Completed'),
            onTap: () {
              provider.markPrayerAsCompleted(prayer, DateTime.now());
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.warning, color: Colors.orange),
            title: const Text('Mark as Qaza'),
            onTap: () {
              provider.markPrayerAsQaza(prayer, DateTime.now().toIso8601String());
              Navigator.pop(context);
            },
          ),
          if (prayer.isCompleted || prayer.isQaza)
            ListTile(
              leading: const Icon(Icons.restore),
              title: const Text('Reset Status'),
              onTap: () {
                provider.resetPrayer(prayer);
                Navigator.pop(context);
              },
            ),
        ],
      ),
    );
  }
} 