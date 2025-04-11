import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password_screen.dart'; // Создайте этот файл позже

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CWYCS',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1E1E1E),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurpleAccent,
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1A1A),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white),
          headlineSmall: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurpleAccent,
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFF2B2B2B),
          border: InputBorder.none,
          labelStyle: TextStyle(color: Colors.white70),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurpleAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.deepPurpleAccent,
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => FirebaseAuth.instance.currentUser == null
            ? const LoginScreen()
            : const ProfileScreen(),
        '/register': (context) => const RegisterScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
      },
    );
  }
}