import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:salat_pro/models/prayer.dart';
import 'package:salat_pro/providers/prayer_provider.dart';
import 'package:intl/intl.dart';

class PrayerHistoryScreen extends StatefulWidget {
  const PrayerHistoryScreen({super.key});

  @override
  State<PrayerHistoryScreen> createState() => _PrayerHistoryScreenState();
}

class _PrayerHistoryScreenState extends State<PrayerHistoryScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prayer History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
          ),
        ],
      ),
      body: Consumer<PrayerProvider>(
        builder: (context, provider, child) {
          if (!provider.isInitialized || provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final prayers = provider.getPrayersForDate(_selectedDate);
          
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _isLoading = true;
              });
              await provider.initializePrayersForDate(_selectedDate);
              setState(() {
                _isLoading = false;
              });
            },
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          DateFormat('MMMM d, yyyy').format(_selectedDate),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        if (prayers.isEmpty) ...[
                          const SizedBox(height: 32),
                          const Icon(Icons.history, size: 48, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            'No prayers found for this date',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () {
                              provider.initializePrayersForDate(_selectedDate);
                            },
                            child: const Text('Initialize Prayers'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (prayers.isNotEmpty)
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final prayer = prayers[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: _PrayerHistoryItem(prayer: prayer),
                        );
                      },
                      childCount: prayers.length,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }
}

class _PrayerHistoryItem extends StatelessWidget {
  final Prayer prayer;

  const _PrayerHistoryItem({
    required this.prayer,
  });

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('hh:mm a');
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: () => _showPrayerDetails(context),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
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
                  const SizedBox(width: 8),
                  Text(
                    prayer.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Scheduled: ${timeFormat.format(prayer.scheduledTime)}'),
              if (prayer.completedTime != null)
                Text(
                  'Completed: ${timeFormat.format(prayer.completedTime!)}',
                  style: const TextStyle(color: Colors.green),
                ),
              if (prayer.isQaza && prayer.qazaDate != null)
                Text(
                  'Qaza from: ${prayer.qazaDate}',
                  style: const TextStyle(color: Colors.orange),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPrayerDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Consumer<PrayerProvider>(
        builder: (context, provider, child) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  prayer.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.schedule),
                  title: const Text('Scheduled Time'),
                  subtitle: Text(DateFormat('hh:mm a').format(prayer.scheduledTime)),
                ),
                if (prayer.completedTime != null)
                  ListTile(
                    leading: const Icon(Icons.check_circle, color: Colors.green),
                    title: const Text('Completed Time'),
                    subtitle: Text(DateFormat('hh:mm a').format(prayer.completedTime!)),
                  ),
                if (prayer.isQaza && prayer.qazaDate != null)
                  ListTile(
                    leading: const Icon(Icons.warning, color: Colors.orange),
                    title: const Text('Qaza Date'),
                    subtitle: Text(prayer.qazaDate!),
                  ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () {
                        provider.resetPrayer(prayer);
                        Navigator.pop(context);
                      },
                      child: const Text('Reset Status'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (!prayer.isCompleted) {
                          provider.markPrayerAsCompleted(prayer, DateTime.now());
                        }
                        Navigator.pop(context);
                      },
                      child: Text(prayer.isCompleted ? 'Completed' : 'Mark as Completed'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
} 