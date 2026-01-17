import 'package:flutter/material.dart';
import '../services/otp_auth_service.dart';
import 'student_home_screen.dart';
import 'admin_home_screen.dart';

class OtpScreen extends StatefulWidget {
  final String email;
  const OtpScreen({super.key, required this.email});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();
  final _service = OtpAuthService();
  bool _loading = false;

  Future<void> _verify() async {
    setState(() => _loading = true);

    final ok = await _service.verifyOtp(
      widget.email,
      _otpController.text.trim(),
    );

    setState(() => _loading = false);
    if (!mounted) return;

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid OTP')),
      );
      return;
    }

    final email = widget.email.trim().toLowerCase();
    late Widget nextScreen;

    if (email == 'admin@iitbhilai.ac.in') {
      nextScreen = AdminHomeScreen(email: email);
    } else {
      nextScreen = StudentHomeScreen(email: email);
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => nextScreen),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('OTP sent to ${widget.email}'),
            const SizedBox(height: 20),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Enter OTP',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _verify,
                child: _loading
                    ? const CircularProgressIndicator()
                    : const Text('Verify'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}