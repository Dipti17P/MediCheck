import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static final _auth = LocalAuthentication();

  static Future<bool> canAuthenticate() async {
    return await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
  }

  static Future<bool> authenticate() async {
    if (kIsWeb) return true; // Biometrics not supported on web
    try {
      if (!await canAuthenticate()) return false;
      
      return await _auth.authenticate(
        localizedReason: 'Please authenticate to access your health records',
      );
    } on PlatformException catch (e) {
      print('Biometric auth error: $e');
      return false;
    }
  }
}
