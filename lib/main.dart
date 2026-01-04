import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AI Campus Helpdesk',
      home: const EmailLoginPage(),
    );
  }
}

class EmailLoginPage extends StatelessWidget {
  const EmailLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Campus Helpdesk'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Login with College Email',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'College Email',
                hintText: 'yourname@iitbhilai.ac.in',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Firebase logic comes later
              },
              child: const Text('Send OTP'),
            ),
          ],
        ),
      ),
    );
  }
}