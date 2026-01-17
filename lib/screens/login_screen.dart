import 'package:flutter/material.dart';
import '../services/otp_auth_service.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _otpService = OtpAuthService();

  bool _loading = false;

  void _sendOtp() async {
    final email = _emailController.text.trim();

    if (!email.endsWith('@iitbhilai.ac.in')) {
      _show('Use IIT Bhilai email only');
      return;
    }

    setState(() => _loading = true);

    await _otpService.sendOtp(email);

    setState(() => _loading = false);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OtpScreen(email: email),
      ),
    );
  }

  void _show(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Campus Helpdesk')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Login with College Email',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'College Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _sendOtp,
                child: _loading
                    ? const CircularProgressIndicator()
                    : const Text('Send OTP'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

