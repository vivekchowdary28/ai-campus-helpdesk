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

  void _verify() async {
    setState(() => _loading = true);

    final ok = await _service.verifyOtp(
      widget.email,
      _otpController.text.trim(),
    );

    setState(() => _loading = false);

    if (!mounted) return;

    if (ok) {
       // Logic to choose the screen based on the email
      Widget nextScreen;
      String email = widget.email.trim().toLowerCase();

       if (email == 'admin@iitbhilai.ac.in') {
          nextScreen = const AdminHomeScreen();
       } else {
          nextScreen = StudentHomeScreen(email: widget.email); // Removed const
       }

       Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => nextScreen),
          (_) => false,
         );
        } else {
             ScaffoldMessenger.of(context)
               .showSnackBar(const SnackBar(content: Text('Invalid OTP')));
    }
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