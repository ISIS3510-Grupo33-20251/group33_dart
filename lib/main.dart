import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'presentation/auth/login_screen.dart';
import 'presentation/auth/register_screen.dart';
import 'presentation/auth/welcome_screen.dart';
import 'presentation/home/home_screen.dart';
import 'screen_flashcards.dart';
import 'screen_notes.dart';
import 'domain/usecases/login_usecase.dart';
import 'domain/usecases/auth/register_usecase.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/note_repository.dart';
import 'domain/repositories/flashcard_repository.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/note_repository_impl.dart';
import 'data/repositories/flashcard_repository_impl.dart';
import 'presentation/viewmodels/login_viewmodel.dart';
import 'presentation/viewmodels/auth/register_viewmodel.dart';
import 'presentation/viewmodels/notes/note_viewmodel.dart';
import 'presentation/viewmodels/flashcards/flashcard_viewmodel.dart';
import 'domain/usecases/notes/get_notes_usecase.dart';
import 'domain/usecases/flashcards/get_flashcards_usecase.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final authRepository = AuthRepositoryImpl(prefs);
  final loginUseCase = LoginUseCase(authRepository);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => LoginViewModel(loginUseCase),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UniVerse',
      theme: ThemeData(
        primaryColor: const Color(0xFF7D91FA),
        scaffoldBackgroundColor: Colors.white,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
      },
    );
  }
}

