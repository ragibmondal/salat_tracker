import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:salat_pro/models/trophy.dart';
import 'package:salat_pro/utils/constants.dart';

class TrophyProvider with ChangeNotifier {
  late Box<Trophy> _trophyBox;
  
  TrophyProvider() {
    _init();
  }

  Future<void> _init() async {
    _trophyBox = await Hive.openBox<Trophy>(AppConstants.trophyBox);
    notifyListeners();
  }

  List<Trophy> get allTrophies => _trophyBox.values.toList();

  Future<void> checkAndAwardTrophies(int streak) async {
    final trophies = [
      if (streak >= 3 && !hasTrophy('beginner'))
        Trophy.create(
          name: 'Beginner',
          description: 'Complete prayers for 3 days in a row',
          icon: '🌟',
        ),
      if (streak >= 7 && !hasTrophy('consistent'))
        Trophy.create(
          name: 'Consistent',
          description: 'Complete prayers for 7 days in a row',
          icon: '🏆',
        ),
      if (streak >= 10 && !hasTrophy('dedicated'))
        Trophy.create(
          name: 'Dedicated',
          description: 'Complete prayers for 10 days in a row',
          icon: '👑',
        ),
      if (streak >= 30 && !hasTrophy('master'))
        Trophy.create(
          name: 'Prayer Master',
          description: 'Complete prayers for 30 days in a row',
          icon: '🎯',
        ),
      if (streak >= 100 && !hasTrophy('legend'))
        Trophy.create(
          name: 'Prayer Legend',
          description: 'Complete prayers for 100 days in a row',
          icon: '⭐',
        ),
    ];

    for (var trophy in trophies) {
      await _trophyBox.put(trophy.id, trophy);
      notifyListeners();
    }
  }

  bool hasTrophy(String name) {
    return _trophyBox.values.any((trophy) => 
      trophy.name.toLowerCase() == name.toLowerCase()
    );
  }

  Future<void> clearTrophies() async {
    await _trophyBox.clear();
    notifyListeners();
  }
} 