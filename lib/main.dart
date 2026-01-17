import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/loading_screen.dart';
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
      title: 'IIT Bhilai Campus Assist',
      debugShowCheckedModeBanner: false,
      
      // Professional Theme Configuration
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E293B), // Navy Blue
          primary: const Color(0xFF2563EB),   // Royal Blue
        ),
        useMaterial3: true,
        // Set a default font if you have one, or stick to system fonts
        fontFamily: 'Roboto', 
      ),

      // The app now starts with the Splash Screen
      // The Splash Screen handles the logic of checking if a user is already signed in
      home: const SplashScreen(),
      
      // Define routes if you want to use Navigator.pushNamed, 
      // otherwise, we use MaterialPageRoute as we have been doing.
    );
  }
}