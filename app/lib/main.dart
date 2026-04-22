import 'package:flutter/material.dart';

// Import your screen files here when you create them
// import 'package:app/screens/login_screen.dart';
// import 'package:app/screens/signup_screen.dart';
// import 'package:app/screens/home_screen.dart';

void main() {
  runApp(const MediCheckApp());
}

class MediCheckApp extends StatelessWidget {
  const MediCheckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MediCheck AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E88E5), // Medical Blue
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Inter', // Recommend using a clean font like Inter or Roboto
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
      // Define the initial route
      initialRoute: '/login',
      // Define all the routes for the application
      routes: {
        '/login': (context) => const PlaceholderScreen(title: 'Login Screen'),
        '/signup': (context) => const PlaceholderScreen(title: 'Signup Screen'),
        '/home': (context) => const PlaceholderScreen(title: 'Home Screen'),
        
        // Uncomment these and remove the placeholders when screens are created
        // '/login': (context) => const LoginScreen(),
        // '/signup': (context) => const SignupScreen(),
        // '/home': (context) => const HomeScreen(),
      },
    );
  }
}

/// A temporary placeholder screen to avoid compilation errors 
/// before the actual screens are implemented.
class PlaceholderScreen extends StatelessWidget {
  final String title;

  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.medical_services_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Backend Base URL: http://10.0.2.2:5000/api',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            if (title == 'Login Screen') ...[
              ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
                child: const Text('Simulate Login (Go to Home)'),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/signup'),
                child: const Text('Don\'t have an account? Sign up'),
              ),
            ] else if (title == 'Signup Screen') ...[
              ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                child: const Text('Simulate Signup (Go to Login)'),
              ),
            ] else if (title == 'Home Screen') ...[
              ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                child: const Text('Logout'),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
