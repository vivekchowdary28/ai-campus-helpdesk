import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'login_screen.dart';
import 'student_home_screen.dart';
import 'admin_home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_controller);

    _controller.forward();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null || user.email == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    final email = user.email!.toLowerCase();

    final adminDoc = await FirebaseFirestore.instance
        .collection('admins')
        .doc(email)
        .get();

    if (!mounted) return;

    if (adminDoc.exists) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AdminHomeScreen(email: email),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => StudentHomeScreen(email: email),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.school,
                  size: 80,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                "IIT BHILAI",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: Color(0xFF1E293B),
                ),
              ),
              const Text(
                "CAMPUS ASSIST",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 4,
                  color: Colors.blueGrey,
                ),
              ),
              const SizedBox(height: 50),
              const CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                strokeWidth: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}