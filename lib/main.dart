import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:salat_pro/models/prayer.dart';
import 'package:salat_pro/models/trophy.dart';
import 'package:salat_pro/providers/prayer_provider.dart';
import 'package:salat_pro/providers/theme_provider.dart';
import 'package:salat_pro/providers/trophy_provider.dart';
import 'package:salat_pro/screens/home_screen.dart';
import 'package:salat_pro/utils/constants.dart';
import 'package:salat_pro/providers/settings_provider.dart';

// Add global navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Hive
    await Hive.initFlutter();
    
    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(PrayerAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(TrophyAdapter());
    }
    
    // Open boxes
    await Hive.openBox<Prayer>(AppConstants.prayerBox);
    await Hive.openBox<Trophy>(AppConstants.trophyBox);

    // Initialize SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    
    runApp(MyApp(prefs: prefs));
  } catch (e) {
    debugPrint('Error initializing app: $e');
    // Handle initialization error gracefully
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Error initializing app: $e'),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;

  const MyApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(prefs),
        ),
        ChangeNotifierProvider(
          create: (_) => PrayerProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(prefs),
        ),
        ChangeNotifierProvider(
          create: (_) => TrophyProvider(),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            navigatorKey: navigatorKey,  // Add navigator key here
            title: 'Salat Pro',
            theme: themeProvider.theme,
            home: const HomeScreen(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
