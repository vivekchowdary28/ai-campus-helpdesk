import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/otp_utils.dart';

class OtpAuthService {
  final _db = FirebaseFirestore.instance;

  Future<void> sendOtp(String email) async {
    final otp = OtpUtils.generateOtp();

    await _db.collection('otp_logins').doc(email).set({
      'otp': otp,
      'expiresAt': OtpUtils.expiryTime(),
    });

    // TEMP: print OTP for simulator/demo
    print('OTP for $email → $otp');
  }

  Future<bool> verifyOtp(String email, String inputOtp) async {
    final doc =
        await _db.collection('otp_logins').doc(email).get();

    if (!doc.exists) return false;

    final data = doc.data()!;
    final storedOtp = data['otp'];
    final expiresAt = (data['expiresAt'] as Timestamp).toDate();

    if (DateTime.now().isAfter(expiresAt)) return false;

    return storedOtp == inputOtp;
  }
}