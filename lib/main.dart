import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/loading_screen.dart';
import 'screens/student_home_screen.dart';
import 'screens/admin_home_screen.dart';
import 'screens/student_chat_screen.dart';

Future<void> main() async {
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
      home: FutureBuilder<SharedPreferences>(
        future: SharedPreferences.getInstance(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingScreen();
          }

          final prefs = snapshot.data!;
          final savedEmail = prefs.getString('signed_in_email');

          // 1️⃣ No session → Login
          if (savedEmail == null || savedEmail.isEmpty) {
            return const LoginScreen();
          }

          // 2️⃣ Session exists → route by email ONLY
          final email = savedEmail.trim().toLowerCase();
          final isAdmin = email == 'admin@iitbhilai.ac.in';

          return isAdmin
              ? const AdminHomeScreen()
              : StudentHomeScreen(email: email);
        },
      ),
    );
  }
}