import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/notification_service.dart';
import 'services/token_service.dart';
import 'services/api_service.dart';

import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/add_medicine_screen.dart';
import 'screens/view_medicine_screen.dart';
import 'screens/interaction_screen.dart';
import 'screens/reminder_screen.dart';
import 'screens/splash_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void handleTokenExpiry() {
  TokenService.clearAll();
  navigatorKey.currentState?.pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const LoginScreen()),
    (route) => false,
  );
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    if (kIsWeb) {
      print("Firebase initialization skipped on Web (requires options)");
    } else {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    }
  } catch (e) {
    print("Firebase initialization error: $e");
  }
  
  await NotificationService().init();
  
  runApp(const MediCheckApp());
}

class MediCheckApp extends StatelessWidget {
  const MediCheckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MediCheck AI',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E88E5),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Inter',
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/':               (context) => const SplashScreen(),
        '/login':          (context) => const LoginScreen(),
        '/signup':         (context) => const SignupScreen(),
        '/home':           (context) => const DashboardScreen(),
        '/add-medicine':   (context) => const AddMedicineScreen(),
        '/view-medicines': (context) => const ViewMedicineScreen(),
        '/check-interaction': (context) => const InteractionScreen(),
        '/reminder':       (context) => const ReminderScreen(),
      },
    );
  }
}
