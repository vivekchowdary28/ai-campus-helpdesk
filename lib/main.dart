import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/student_home_screen.dart';
import 'screens/admin_home_screen.dart';
import 'screens/student_chat_screen.dart';
import 'screens/splash_screen.dart';

void main() async {
  // 1. Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Firebase with platform-specific options
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
      title: 'IIT Bhilai Campus AI Assistant',
      debugShowCheckedModeBanner: false,

      // Professional Theme Configuration
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E293B), // Navy Blue
          primary: const Color(0xFF2563EB), // Royal Blue
          secondary: const Color(0xFF1B7F5C), // Green (for admin)
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',

        // AppBar Theme
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2563EB),
          foregroundColor: Colors.white,
          elevation: 2,
          centerTitle: true,
        ),

        // Button Theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),

        // Card Theme
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),

        // Input Decoration Theme
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
      ),

      // The app starts with the Splash Screen
      // The Splash Screen handles the logic of checking if a user is already signed in
      home: const SplashScreen(),

      // Define routes for easy navigation
      routes: {
        '/login': (context) => const LoginScreen(),
        '/student-home': (context) => const StudentHomeScreen(email: ''),
        '/admin-home': (context) => const AdminHomeScreen(email: ''),
        '/student-chat': (context) => const StudentChatScreen(),
      },

      // Handle unknown routes
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        );
      },
    );
  }
}
