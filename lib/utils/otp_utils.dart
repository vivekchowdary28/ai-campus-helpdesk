import 'dart:math';

class OtpUtils {
  static String generateOtp() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  static DateTime expiryTime() {
    return DateTime.now().add(const Duration(minutes: 5));
  }
}