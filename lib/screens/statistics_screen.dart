import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:salat_pro/providers/prayer_provider.dart';
import 'package:salat_pro/utils/constants.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  bool _isLoading = false;

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });
    
    // Wait a bit to show loading state
    await Future.delayed(const Duration(milliseconds: 500));
    
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prayer Statistics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: () => _selectDateRange(context),
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

          final stats = provider.getPrayerWiseStats(_startDate, _endDate);
          final streak = provider.getConsecutiveCompleteDays();
          
          if (stats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.warning, size: 48, color: Colors.orange),
                  const SizedBox(height: 16),
                  Text(
                    'No data available for selected date range',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _startDate = DateTime.now().subtract(const Duration(days: 7));
                        _endDate = DateTime.now();
                      });
                    },
                    child: const Text('Reset Date Range'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshData,
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildDateRangeCard(),
                const SizedBox(height: 16),
                _buildStreakCard(streak),
                const SizedBox(height: 16),
                _buildPrayerStatsChart(stats),
                const SizedBox(height: 16),
                _buildPrayerStatsList(stats),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateRangeCard() {
    final dateFormat = DateFormat('MMM d, yyyy');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Statistics for',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '${dateFormat.format(_startDate)} - ${dateFormat.format(_endDate)}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakCard(int streak) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              Icons.local_fire_department,
              size: 48,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Streak',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  Text(
                    '$streak Day${streak != 1 ? 's' : ''}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerStatsChart(Map<String, double> stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Prayer Completion Rate',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 1,
                  barGroups: _createBarGroups(stats),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final prayers = AppConstants.prayerNames;
                          if (value >= 0 && value < prayers.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                prayers[value.toInt()][0],
                                style: const TextStyle(
                                  fontSize: 12,
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text('${(value * 100).toInt()}%');
                        },
                        reservedSize: 40,
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<BarChartGroupData> _createBarGroups(Map<String, double> stats) {
    final prayers = AppConstants.prayerNames;
    return List.generate(prayers.length, (index) {
      final prayer = prayers[index];
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: stats[prayer] ?? 0,
            color: Theme.of(context).colorScheme.primary,
            width: 20,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(4),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildPrayerStatsList(Map<String, double> stats) {
    return Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Detailed Statistics',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          ...AppConstants.prayerNames.map((prayer) {
            final percentage = stats[prayer] ?? 0;
            return ListTile(
              title: Text(prayer),
              subtitle: LinearProgressIndicator(
                value: percentage,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
              trailing: Text(
                '${(percentage * 100).toInt()}%',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final initialDateRange = DateTimeRange(
      start: _startDate,
      end: _endDate,
    );

    final pickedDateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: initialDateRange,
    );

    if (pickedDateRange != null) {
      setState(() {
        _startDate = pickedDateRange.start;
        _endDate = pickedDateRange.end;
      });
    }
  }
} 