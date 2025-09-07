import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:student_management/firebase_options.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:student_management/screens/dashboard_scree,.dart';
import 'package:student_management/screens/landing_page.dart';
import 'package:student_management/screens/login_screen.dart';
import 'package:student_management/screens/add_student_screen.dart';
import 'package:student_management/screens/success_screen.dart';

// Simple AuthService to manage login state
class AuthService {
  static bool _isAuthenticated = false;

  static bool get isAuthenticated => _isAuthenticated;

  static void login() {
    _isAuthenticated = true;
  }

  static void logout() {
    _isAuthenticated = false;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Use hash URLs (with #)
  setUrlStrategy(HashUrlStrategy());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Define color constants
  static const Color primaryGold = Color(0xFFFFB700);
  static const Color lightGold = Color(0xFFFFE082);
  static const Color darkGold = Color(0xFFFF8F00);
  static const Color deepBlue = Color(0xFF1E3A8A);

  // Define the GoRouter configuration
  static final GoRouter _router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const BrightspeakLandingPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const AddStudentScreen(),
      ),
      GoRoute(
        path: '/register-success',
        builder: (context, state) => const StudentEnrollmentSuccessScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) async {
      // Protect the /dashboard route
      if (state.uri.toString() == '/dashboard' &&
          !AuthService.isAuthenticated) {
        return '/login';
      }
      return null; // No redirect needed
    },
    errorBuilder:
        (context, state) => const Scaffold(
          body: Center(
            child: Text(
              '404 - Page not found',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
        ),
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Brightspeak English Academy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: primaryGold,
        scaffoldBackgroundColor: lightGold,
        fontFamily: 'Roboto',
        useMaterial3: true,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryGold,
            foregroundColor: darkGold,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: darkGold),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryGold, width: 2),
          ),
        ),
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.blue, // Retain for compatibility
          accentColor: darkGold,
          backgroundColor: lightGold,
          cardColor: Colors.white.withOpacity(0.95),
        ).copyWith(
          surface: lightGold,
          primary: primaryGold,
          secondary: deepBlue,
        ),
      ),
      routerConfig: _router,
    );
  }
}
