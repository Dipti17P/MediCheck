import 'package:flutter/material.dart';
import '../services/token_service.dart';

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
      // Token exists, auto-login
      Navigator.pushReplacementNamed(context, '/home');
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
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(50),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.medical_services_rounded,
                size: 80,
                color: Color(0xFF1565C0),
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
