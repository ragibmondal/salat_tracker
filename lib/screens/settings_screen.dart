import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:salat_pro/providers/prayer_provider.dart';
import 'package:salat_pro/providers/theme_provider.dart';
import 'package:salat_pro/models/prayer.dart';
import 'package:salat_pro/screens/prayer_history_screen.dart';
import 'package:salat_pro/screens/statistics_screen.dart';
import 'package:salat_pro/utils/constants.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:salat_pro/providers/settings_provider.dart';
import 'package:file_picker/file_picker.dart';

// Conditionally import dart:html for web
import 'package:salat_pro/utils/web_utils.dart' if (dart.library.html) 'dart:html' as html;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer3<PrayerProvider, ThemeProvider, SettingsProvider>(
        builder: (context, prayerProvider, themeProvider, settingsProvider, child) {
          final prayers = prayerProvider.todaysPrayers;
          final stats = prayerProvider.getPrayerStats();
          final streak = prayerProvider.getConsecutiveCompleteDays();
          
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              if (streak > 0)
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          size: 48,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$streak Day${streak > 1 ? 's' : ''} Streak!',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text('Keep up the great work!'),
                      ],
                    ),
                ),
              ),
              const SizedBox(height: 16),
              _SectionHeader(title: 'Prayer Times'),
              ...prayers.map((prayer) => _PrayerTimeSettings(prayer: prayer)),
              const SizedBox(height: 24),
              _SectionHeader(title: 'Appearance'),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Dark Mode'),
                      subtitle: const Text('Switch between light and dark theme'),
                      value: themeProvider.isDarkMode,
                      onChanged: (value) => themeProvider.toggleTheme(),
                    ),
                    const Divider(),
                    ListTile(
                      title: const Text('App Color'),
                      subtitle: const Text('Choose your preferred accent color'),
                      trailing: _ColorPickerButton(
                        currentColor: themeProvider.accentColor,
                        onColorChanged: (color) => themeProvider.setAccentColor(color),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _SectionHeader(title: 'Notifications'),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Prayer Time Reminders'),
                      subtitle: const Text('Get notified when it\'s time to pray'),
                      value: settingsProvider.notificationsEnabled,
                      onChanged: (value) => settingsProvider.toggleNotifications(value),
                    ),
                    const Divider(),
                    ListTile(
                      title: const Text('Reminder Sound'),
                      subtitle: Text(
                        settingsProvider.notificationSound == 'azan'
                            ? 'Azan'
                            : 'Default Notification',
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => _showSoundPicker(context),
                    ),
                    const Divider(),
                    ListTile(
                      title: const Text('Reminder Time'),
                      subtitle: const Text('Set how early you want to be reminded'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => _showReminderTimePicker(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _SectionHeader(title: 'Prayer History'),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('View Prayer History'),
                  subtitle: const Text('View and manage past prayers'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PrayerHistoryScreen(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _SectionHeader(title: 'Data Management'),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.upload_file),
                      title: const Text('Export Data'),
                      subtitle: const Text('Save your prayer data to a file'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => _exportData(context),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.download_rounded),
                      title: const Text('Import Data'),
                      subtitle: const Text('Restore your prayer data from a backup file'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => _importData(context),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Note: Make sure to backup your data regularly to prevent loss.',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _SectionHeader(
                title: 'Statistics',
                subtitle: 'Track your prayer journey',
              ),
              Card(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: _StatBox(
                              title: 'Total\nPrayers',
                              value: stats['total'].toString(),
                              icon: Icons.calendar_today,
                              color: Theme.of(context).colorScheme.primary,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const StatisticsScreen(),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: _StatBox(
                              title: 'Completed\nPrayers',
                              value: stats['completed'].toString(),
                              icon: Icons.check_circle,
                              color: Colors.green,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const StatisticsScreen(),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: _StatBox(
                              title: 'Qaza\nPrayers',
                              value: stats['qaza'].toString(),
                              icon: Icons.warning,
                              color: Colors.orange,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const StatisticsScreen(),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      title: const Text('View Detailed Statistics'),
                      subtitle: const Text('See your complete prayer history and trends'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const StatisticsScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _SectionHeader(title: 'About'),
              Card(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Theme.of(context).colorScheme.primaryContainer,
                                ),
                                child: Icon(
                                  Icons.mosque_outlined,
                                  size: 32,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                                    const Text(
                        'SalatTracker Pro',
                        style: TextStyle(
                                        fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                                      'Version: 1.0.0',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                        'A simple and elegant way to track your daily prayers. '
                        'This app helps you maintain your prayer schedule and build consistency in your worship.',
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.code),
                      title: const Text('Developer'),
                      subtitle: const Text('@ragibmondal'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.link),
                            onPressed: () => _launchUrl('https://github.com/ragibmondal'),
                            tooltip: 'GitHub Profile',
                          ),
                        ],
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: const Text('Privacy Policy'),
                      onTap: () => _showPrivacyPolicy(context),
                    ),
                    ListTile(
                      leading: const Icon(Icons.star_outline),
                      title: const Text('Rate App'),
                      onTap: () {
                        _launchUrl('https://github.com/ragibmondal/salat_tracker');
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.share),
                      title: const Text('Share App'),
                      onTap: () => _shareApp(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Center(
                child: Text(
                  '© ${DateTime.now().year} SalatTracker Pro',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  Future<void> _exportData(BuildContext context) async {
    final provider = Provider.of<PrayerProvider>(context, listen: false);
    
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final data = await provider.exportData();
      
      // Close loading dialog
      Navigator.pop(context);

      // For mobile platforms only
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/salat_pro_backup_${DateFormat('yyyyMMdd').format(DateTime.now())}.json');
      await file.writeAsString(data);
      
      if (!mounted) return;
      
      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'SalatPro Backup',
        text: 'Prayer data backup from SalatPro',
      );
    } catch (e) {
      if (!mounted) return;
      
      // Show error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Export Error'),
          content: Text('Failed to export data: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _importData(BuildContext context) async {
    final provider = Provider.of<PrayerProvider>(context, listen: false);

    try {
      if (kIsWeb) {
        // Show not supported dialog for web
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Not Supported'),
            content: const Text('Import functionality is not available on web platform.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }

      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Import Data'),
          content: const Text(
            'This will replace all existing data with the imported data. '
            'Are you sure you want to continue?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Continue'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // Pick file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) return;

      final file = File(result.files.first.path!);
      final jsonData = await file.readAsString();

      // Show loading dialog
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      await provider.importData(jsonData);
      
      // Close loading dialog
      if (!mounted) return;
      Navigator.pop(context);

      // Show success dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Success'),
          content: const Text('Data imported successfully.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      // Close loading dialog if open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (!mounted) return;
      
      // Show error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Import Error'),
          content: Text('Failed to import data: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _launchUrl(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    }
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'SalatTracker Pro respects your privacy and does not collect any personal information. '
            'All prayer data is stored locally on your device. The app does not track your location '
            'or any other personal information.\n\n'
            'The only permissions required are for:\n'
            '• Storage: To save and restore prayer data backups\n'
            '• Notifications: To remind you of prayer times\n\n'
            'Your data is never shared with third parties or uploaded to any servers.',
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

  Future<void> _shareApp(BuildContext context) async {
    const text = 'Check out SalatTracker Pro - A beautiful prayer tracking app!\n'
        'https://github.com/ragibmondal';
    await Share.share(text);
  }

  void _showSoundPicker(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Reminder Sound'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile(
              title: const Text('Azan'),
              value: 'azan',
              groupValue: settingsProvider.notificationSound,
              onChanged: (value) {
                settingsProvider.setNotificationSound(value.toString());
                Navigator.pop(context);
              },
            ),
            RadioListTile(
              title: const Text('Default Notification'),
              value: 'default',
              groupValue: settingsProvider.notificationSound,
              onChanged: (value) {
                settingsProvider.setNotificationSound(value.toString());
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showReminderTimePicker(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reminder Time'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile(
              title: const Text('At prayer time'),
              value: 0,
              groupValue: settingsProvider.reminderTime,
              onChanged: (value) {
                settingsProvider.setReminderTime(value as int);
                Navigator.pop(context);
              },
            ),
            RadioListTile(
              title: const Text('5 minutes before'),
              value: 5,
              groupValue: settingsProvider.reminderTime,
              onChanged: (value) {
                settingsProvider.setReminderTime(value as int);
                Navigator.pop(context);
              },
            ),
            RadioListTile(
              title: const Text('10 minutes before'),
              value: 10,
              groupValue: settingsProvider.reminderTime,
              onChanged: (value) {
                settingsProvider.setReminderTime(value as int);
                Navigator.pop(context);
              },
            ),
            RadioListTile(
              title: const Text('15 minutes before'),
              value: 15,
              groupValue: settingsProvider.reminderTime,
              onChanged: (value) {
                settingsProvider.setReminderTime(value as int);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _SectionHeader({
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _StatBox({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 12),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorPickerButton extends StatelessWidget {
  final Color currentColor;
  final ValueChanged<Color> onColorChanged;

  const _ColorPickerButton({
    required this.currentColor,
    required this.onColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showColorPicker(context),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: currentColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: Theme.of(context).dividerColor,
            width: 2,
          ),
        ),
      ),
    );
  }

  void _showColorPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose App Color'),
        content: SingleChildScrollView(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Colors.blue,
              Colors.indigo,
              Colors.purple,
              Colors.pink,
              Colors.red,
              Colors.orange,
              Colors.amber,
              Colors.green,
              Colors.teal,
              Colors.cyan,
            ].map((color) => _ColorOption(
              color: color,
              isSelected: currentColor == color,
              onTap: () {
                onColorChanged(color);
                Navigator.pop(context);
              },
            )).toList(),
          ),
        ),
      ),
    );
  }
}

class _ColorOption extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorOption({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 3,
          ),
        ),
      ),
    );
  }
}

class _PrayerTimeSettings extends StatelessWidget {
  final Prayer prayer;

  const _PrayerTimeSettings({required this.prayer});

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('hh:mm a');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          ListTile(
        title: Text(prayer.name),
        subtitle: Text('Scheduled: ${timeFormat.format(prayer.scheduledTime)}'),
        trailing: IconButton(
          icon: const Icon(Icons.access_time),
              onPressed: () => _updateTime(context),
            ),
          ),
          if (prayer.isQaza && prayer.qazaDate != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Qaza from: ${prayer.qazaDate}',
                style: const TextStyle(
                  color: Colors.red,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _updateTime(BuildContext context) async {
            final TimeOfDay? newTime = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.fromDateTime(prayer.scheduledTime),
            );

            if (newTime != null) {
              final now = DateTime.now();
              final newDateTime = DateTime(
                now.year,
                now.month,
                now.day,
                newTime.hour,
                newTime.minute,
              );

              // ignore: use_build_context_synchronously
              Provider.of<PrayerProvider>(context, listen: false)
                  .updatePrayerTime(prayer, newDateTime);
            }
  }
} 