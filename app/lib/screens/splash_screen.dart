import 'package:flutter/material.dart';
import '../services/token_service.dart';
import '../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // Optional: Add a slight delay for a smooth splash screen experience
    await Future.delayed(const Duration(seconds: 1));
    
    final bool loggedIn = await TokenService.isLoggedIn();
    
    if (!mounted) return;

    if (loggedIn) {
      // Token exists, check biometrics
      final bool authenticated = await AuthService.authenticate();
      if (!mounted) return;
      
      if (authenticated) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        // If auth fails or cancelled, go to login for security
        Navigator.pushReplacementNamed(context, '/login');
      }
    } else {
      // No token, go to login
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1565C0), // Primary blue
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Hero(
              tag: 'logo',
              child: Image.asset(
                'assets/logo.png',
                height: 150,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'MediCheck AI',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
