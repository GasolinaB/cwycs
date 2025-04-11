import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const CyberApp());
}

class CyberApp extends StatelessWidget {
  const CyberApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CYBERSPACE',
      themeMode: ThemeMode.dark,
      darkTheme: _buildCyberTheme(),
      initialRoute: '/',
      onGenerateRoute: _generateRoute,
    );
  }

  ThemeData _buildCyberTheme() {
    const cyberGradient = LinearGradient(
      colors: [Color(0xFF6C2B9B), Color(0xFF2D1B33)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: const Color(0xFF0F0F1A),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF7E57C2),
        secondary: Color(0xFF00BCD4),
        surface: Color(0xFF1A1A2E),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
          color: Colors.white,
        ),
        iconTheme: IconThemeData(color: Colors.white70),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: 2.0,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: Colors.white70,
          height: 1.5,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF252542),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 24, vertical: 18),
        hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.4)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15)),
          backgroundColor: const Color(0xFF7E57C2),
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: Colors.purpleAccent.withOpacity(0.3),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF00BCD4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          textStyle: const TextStyle(
            decoration: TextDecoration.underline,
            decorationThickness: 2,
          ),
        ),
      ),
      cardTheme: CardTheme(
        color: const Color(0xFF1E1E3D),
        elevation: 6,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        margin: const EdgeInsets.all(12),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: const Color(0xFF252542),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25)),
      ),
    );
  }

  Route<dynamic> _generateRoute(RouteSettings settings) {
    final user = FirebaseAuth.instance.currentUser;

    switch (settings.name) {
      case '/':
        return MaterialPageRoute(
          builder: (_) => user != null
              ? const ProfileScreen()
              : const LoginScreen(),
        );
      case '/register':
        return _buildPageRoute(const RegisterScreen());
      case '/forgot-password':
        return _buildPageRoute(const ForgotPasswordScreen());
      case '/profile':
        return _buildPageRoute(const ProfileScreen());
      default:
        return _buildPageRoute(const LoginScreen());
    }
  }

  PageRouteBuilder<dynamic> _buildPageRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutQuart;

        var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }
}