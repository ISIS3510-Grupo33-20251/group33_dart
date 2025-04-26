import 'package:flutter/material.dart';
import 'package:group33_dart/core/network/actionQueueManager.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'services/schedule_service.dart';
import 'presentation/menu/main_menu.dart';
import 'presentation/auth/login_screen.dart';
import 'presentation/auth/register_screen.dart';
import 'presentation/auth/welcome_screen.dart';
import 'presentation/flashcards/screen_flashcards.dart';
import 'presentation/notes/screen_notes.dart';
import 'presentation/schedule/schedule_screen.dart';
import 'data/adapters/time_of_day_adapter.dart';
import 'data/adapters/color_adapter.dart';
import 'domain/models/class_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register all custom adapters
  Hive.registerAdapter(TimeOfDayAdapter());
  Hive.registerAdapter(ColorAdapter());
  Hive.registerAdapter(ClassModelAdapter());

  // Open all boxes you'll need
  await Hive.openBox('storage');
  await Hive.openBox('scheduleBox');
  await Hive.openBox('classesBox');

  // Initialize action queue
  ActionQueueManager().init();

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => ScheduleService(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'UniVerse',
        theme: ThemeData(
          fontFamily: 'Montserrat',
          primarySwatch: Colors.blue,
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              textStyle: const TextStyle(
                fontSize: 16,
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const WelcomeScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const MainMenuPage(),
          '/flashcards': (context) => const ScreenFlashcard(),
          '/notes': (context) => const ScreenNotes(),
          '/schedule': (context) => const ScheduleScreen(),
        },
      ),
    );
  }
}
