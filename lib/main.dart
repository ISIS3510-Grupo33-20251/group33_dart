import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'presentation/auth/login_screen.dart';
import 'presentation/auth/register_screen.dart';
import 'presentation/auth/welcome_screen.dart';
import 'presentation/home/home_screen.dart';
import 'screen_flashcards.dart';
import 'screen_notes.dart';
import 'domain/usecases/auth/login_usecase.dart';
import 'domain/usecases/auth/register_usecase.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/note_repository.dart';
import 'domain/repositories/flashcard_repository.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/note_repository_impl.dart';
import 'data/repositories/flashcard_repository_impl.dart';
import 'presentation/viewmodels/auth/login_viewmodel.dart';
import 'presentation/viewmodels/auth/register_viewmodel.dart';
import 'presentation/viewmodels/notes/note_viewmodel.dart';
import 'presentation/viewmodels/flashcards/flashcard_viewmodel.dart';
import 'domain/usecases/notes/get_notes_usecase.dart';
import 'domain/usecases/flashcards/get_flashcards_usecase.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Auth providers
        Provider<AuthRepository>(
          create: (_) => AuthRepositoryImpl(),
        ),
        ProxyProvider<AuthRepository, LoginUseCase>(
          update: (_, repository, __) => LoginUseCase(repository),
        ),
        ProxyProvider<AuthRepository, RegisterUseCase>(
          update: (_, repository, __) => RegisterUseCase(repository),
        ),
        ChangeNotifierProxyProvider<LoginUseCase, LoginViewModel>(
          create: (context) => LoginViewModel(context.read<LoginUseCase>()),
          update: (_, loginUseCase, __) => LoginViewModel(loginUseCase),
        ),
        ChangeNotifierProxyProvider<RegisterUseCase, RegisterViewModel>(
          create: (context) => RegisterViewModel(context.read<RegisterUseCase>()),
          update: (_, registerUseCase, __) => RegisterViewModel(registerUseCase),
        ),

        // Note providers
        Provider<NoteRepository>(
          create: (_) => NoteRepositoryImpl(),
        ),
        ProxyProvider<NoteRepository, GetNotesUseCase>(
          update: (_, repository, __) => GetNotesUseCase(repository),
        ),
        ChangeNotifierProxyProvider<GetNotesUseCase, NoteViewModel>(
          create: (context) => NoteViewModel(context.read<GetNotesUseCase>()),
          update: (_, getNotesUseCase, __) => NoteViewModel(getNotesUseCase),
        ),

        // Flashcard providers
        Provider<FlashcardRepository>(
          create: (_) => FlashcardRepositoryImpl(),
        ),
        ProxyProvider<FlashcardRepository, GetFlashcardsUseCase>(
          update: (_, repository, __) => GetFlashcardsUseCase(repository),
        ),
        ChangeNotifierProxyProvider<GetFlashcardsUseCase, FlashcardViewModel>(
          create: (context) => FlashcardViewModel(context.read<GetFlashcardsUseCase>()),
          update: (_, getFlashcardsUseCase, __) => FlashcardViewModel(getFlashcardsUseCase),
        ),
      ],
      child: MaterialApp(
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
        initialRoute: '/welcome',
        routes: {
          '/welcome': (context) => const WelcomeScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const HomeScreen(),
          '/flashcards': (context) => const ScreenFlashcard(),
          '/notes': (context) => const ScreenNotes(),
        },
      ),
    );
  }
}

