import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:salat_pro/models/prayer.dart';
import 'package:salat_pro/utils/constants.dart';
import 'package:provider/provider.dart';
import 'package:salat_pro/providers/trophy_provider.dart';
import 'package:salat_pro/main.dart';

class PrayerProvider with ChangeNotifier {
  late Box<Prayer> _prayerBox;
  DateTime _selectedDate = DateTime.now();
  Map<String, List<Prayer>> _prayerCache = {};
  DateTime? _lastCacheUpdate;
  static const Duration _cacheDuration = Duration(minutes: 5);
  bool _isInitialized = false;
  bool _isLoading = false;

  DateTime get selectedDate => _selectedDate;
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  
  PrayerProvider() {
    _init();
  }

  Future<void> _init() async {
    try {
      _isLoading = true;
      notifyListeners();

      _prayerBox = Hive.box<Prayer>(AppConstants.prayerBox);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      // Check if we have any prayers for today
      final todaysPrayers = _prayerBox.values
          .where((prayer) => prayer.date.toIso8601String().split('T')[0] == today.toIso8601String().split('T')[0])
          .toList();
      
      if (todaysPrayers.isEmpty) {
        await _initializeDefaultPrayers();
      }
      
      _clearCache();
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing PrayerProvider: $e');
      _isInitialized = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _initializeDefaultPrayers() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Create all prayers for today
    for (var prayerName in AppConstants.prayerNames) {
      final defaultTime = AppConstants.defaultPrayerTimes[prayerName]!;
      final scheduledTime = DateTime(
        today.year,
        today.month,
        today.day,
        defaultTime.hour,
        defaultTime.minute,
      );

      final prayer = Prayer.create(
        name: prayerName,
        date: today,
        scheduledTime: scheduledTime,
      );

      await _prayerBox.put(prayer.id, prayer);
    }
    
    _clearCache(); // Clear cache after initialization
  }

  List<Prayer> getPrayersForDate(DateTime date) {
    if (!_isInitialized) return [];
    
    final dateStr = date.toIso8601String().split('T')[0];
    
    // Check cache first
    if (_prayerCache.containsKey(dateStr) && 
        _lastCacheUpdate != null &&
        DateTime.now().difference(_lastCacheUpdate!) < _cacheDuration) {
      return _prayerCache[dateStr]!;
    }

    try {
      final prayers = _prayerBox.values
          .where((prayer) => prayer.date.toIso8601String().split('T')[0] == dateStr)
          .toList()
        ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));

      // If no prayers found for the date, initialize them
      if (prayers.isEmpty) {
        // Don't initialize future dates
        final now = DateTime.now();
        if (!date.isAfter(DateTime(now.year, now.month, now.day))) {
          initializePrayersForDate(date);
          return getPrayersForDate(date);
        }
      }

      // Update cache
      _prayerCache[dateStr] = prayers;
      _lastCacheUpdate = DateTime.now();

      return prayers;
    } catch (e) {
      debugPrint('Error getting prayers for date: $e');
      return [];
    }
  }

  void _clearCache() {
    _prayerCache.clear();
    _lastCacheUpdate = null;
  }

  @override
  void dispose() {
    _clearCache();
    super.dispose();
  }

  Future<void> markPrayerAsCompleted(Prayer prayer, DateTime completionTime) async {
    prayer.markAsCompleted(completionTime);
    await _savePrayers();
    _clearCache(); // Clear cache when data changes
    notifyListeners();
    
    // Check for trophies
    final streak = getConsecutiveCompleteDays();
    Provider.of<TrophyProvider>(navigatorKey.currentContext!, listen: false)
        .checkAndAwardTrophies(streak);
  }

  Future<void> markPrayerAsQaza(Prayer prayer, String qazaDate) async {
    prayer.markAsQaza(qazaDate);
    await _savePrayers();
    _clearCache();
    notifyListeners();
  }

  Future<void> resetPrayer(Prayer prayer) async {
    prayer.reset();
    await _savePrayers();
    _clearCache();
    notifyListeners();
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  Future<void> updatePrayerTime(Prayer prayer, DateTime newTime) async {
    final updatedPrayer = Prayer(
      id: prayer.id,
      name: prayer.name,
      date: prayer.date,
      scheduledTime: newTime,
      isCompleted: prayer.isCompleted,
      isQaza: prayer.isQaza,
      completedTime: prayer.completedTime,
    );

    await _prayerBox.put(prayer.id, updatedPrayer);
    await _savePrayers();
    _clearCache();
    notifyListeners();
  }

  List<Prayer> get todaysPrayers {
    if (!_isInitialized) {
      return [];
    }
    return getPrayersForDate(DateTime.now());
  }

  double getCompletionPercentage(DateTime date) {
    final prayers = getPrayersForDate(date);
    if (prayers.isEmpty) return 0.0;
    
    final completed = prayers.where((p) => p.isCompleted).length;
    return completed / prayers.length;
  }

  int getConsecutiveCompleteDays() {
    final now = DateTime.now();
    int streak = 0;
    
    for (int i = 0; i < 365; i++) {
      final date = now.subtract(Duration(days: i));
      final prayers = getPrayersForDate(date);
      
      if (prayers.isEmpty || prayers.any((p) => !p.isCompleted)) {
        break;
      }
      
      streak++;
    }
    
    return streak;
  }

  Map<String, double> getPrayerWiseStats(DateTime startDate, DateTime endDate) {
    try {
      final Map<String, int> totalPrayers = {};
      final Map<String, int> completedPrayers = {};
      
      for (var name in AppConstants.prayerNames) {
        totalPrayers[name] = 0;
        completedPrayers[name] = 0;
      }

      var currentDate = startDate;
      while (!currentDate.isAfter(endDate)) {
        final prayers = getPrayersForDate(currentDate);
        for (var prayer in prayers) {
          totalPrayers[prayer.name] = (totalPrayers[prayer.name] ?? 0) + 1;
          if (prayer.isCompleted) {
            completedPrayers[prayer.name] = (completedPrayers[prayer.name] ?? 0) + 1;
          }
        }
        currentDate = currentDate.add(const Duration(days: 1));
      }

      final Map<String, double> stats = {};
      for (var name in AppConstants.prayerNames) {
        final total = totalPrayers[name] ?? 0;
        final completed = completedPrayers[name] ?? 0;
        stats[name] = total > 0 ? completed / total : 0.0;
      }

      return stats;
    } catch (e) {
      debugPrint('Error calculating prayer stats: $e');
      return {};
    }
  }

  Future<void> initializePrayersForDate(DateTime date) async {
    try {
      _isLoading = true;
      notifyListeners();

      for (var prayerName in AppConstants.prayerNames) {
        final defaultTime = AppConstants.defaultPrayerTimes[prayerName]!;
        final scheduledTime = DateTime(
          date.year,
          date.month,
          date.day,
          defaultTime.hour,
          defaultTime.minute,
        );

        final prayer = Prayer.create(
          name: prayerName,
          date: date,
          scheduledTime: scheduledTime,
        );

        await _prayerBox.put(prayer.id, prayer);
      }
      
      _clearCache();
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing prayers for date: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Export prayers data
  Future<String> exportData() async {
    try {
      _isLoading = true;
      notifyListeners();

      final List<Map<String, dynamic>> data = _prayerBox.values
          .map((prayer) => prayer.toJson())
          .toList();
      
      return jsonEncode({
        'version': '1.0',
        'timestamp': DateTime.now().toIso8601String(),
        'prayers': data,
      });
    } catch (e) {
      debugPrint('Error exporting data: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Import prayers data
  Future<void> importData(String jsonData) async {
    try {
      _isLoading = true;
      notifyListeners();

      final Map<String, dynamic> data = jsonDecode(jsonData);
      
      if (!data.containsKey('prayers')) {
        throw Exception('Invalid data format');
      }

      final List<dynamic> prayersData = data['prayers'];
      await _prayerBox.clear();
      
      for (var prayerData in prayersData) {
        final prayer = Prayer.fromJson(prayerData as Map<String, dynamic>);
        await _prayerBox.put(prayer.id, prayer);
      }
      
      _clearCache();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error importing data: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get all Qaza prayers
  List<Prayer> getQazaPrayers() {
    return _prayerBox.values
        .where((prayer) => prayer.isQaza)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  // Get prayers statistics including Qaza
  Map<String, int> getPrayerStats() {
    final stats = {
      'total': _prayerBox.values.length,
      'completed': _prayerBox.values.where((p) => p.isCompleted).length,
      'qaza': _prayerBox.values.where((p) => p.isQaza).length,
      'missed': _prayerBox.values.where((p) => !p.isCompleted && !p.isQaza).length,
    };
    return stats;
  }

  Future<void> _loadPrayers() async {
    if (_prayerBox.isEmpty) {
      await initializePrayersForDate(DateTime.now());
    }
  }

  Future<void> _savePrayers() async {
    try {
      await _prayerBox.flush();
    } catch (e) {
      debugPrint('Error saving prayers: $e');
    }
  }
} 