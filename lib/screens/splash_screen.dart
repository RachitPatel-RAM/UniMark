import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'auth/login_screen.dart';
import 'student/student_dashboard.dart';
import 'faculty/faculty_dashboard.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthStatus();
    });
  }

  void _checkAuthStatus() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.isInitialized) {
      _navigate(authProvider);
      return;
    }

    late void Function() listener;
    listener = () {
      if (authProvider.isInitialized) {
        _navigate(authProvider);
        authProvider.removeListener(listener);
      }
    };
    authProvider.addListener(listener);
  }

  void _navigate(AuthProvider authProvider) {
    if (!mounted) return;

    Widget destination;
    if (authProvider.isLoggedIn) {
      if (authProvider.isStudent) {
        destination = const StudentDashboard();
      } else if (authProvider.isFaculty) {
        destination = const FacultyDashboard();
      } else {
        destination = const LoginScreen(); // Default for other roles or if role is null
      }
    } else {
      destination = const LoginScreen();
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo/Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.secondaryColor,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.school,
                  size: 60,
                  color: Colors.white,
                ),
              ).animate().scale(
                duration: 1000.ms,
                curve: Curves.elasticOut,
              ),
              
              const SizedBox(height: 32),
              
              // App Name
              Text(
                'UniMark',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 48,
                ),
              ).animate().fadeIn(
                delay: 500.ms,
                duration: 800.ms,
              ).slideY(
                begin: 0.3,
                end: 0,
                curve: Curves.easeOutBack,
              ),
              
              const SizedBox(height: 16),
              
              // Tagline
              Text(
                'Smart Attendance System',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ).animate().fadeIn(
                delay: 800.ms,
                duration: 600.ms,
              ),
              
              const SizedBox(height: 64),
              
              // Loading Indicator
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withOpacity(0.8),
                  ),
                ),
              ).animate().fadeIn(
                delay: 1200.ms,
                duration: 400.ms,
              ),
            ],
          ),
        ),
      ),
    );
  }
}