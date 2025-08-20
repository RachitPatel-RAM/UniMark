import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitialized = false;

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null;
  bool get isInitialized => _isInitialized;
  bool get isStudent => _currentUser?.role == UserRole.student;
  bool get isFaculty => _currentUser?.role == UserRole.faculty;
  bool get isAdmin => _currentUser?.role == UserRole.admin;

  AuthProvider() {
    _initializeAuth();
  }

  // Initialize authentication state
  Future<void> _initializeAuth() async {
    try {
      _setLoading(true);
      
      // Listen to auth state changes
      _authService.authStateChanges.listen((User? user) async {
        if (user != null) {
          await _loadUserData();
        } else {
          _currentUser = null;
          notifyListeners();
        }
      });
      
      // Load current user if already logged in
      if (_authService.currentUser != null) {
        await _loadUserData();
      }
      
      _isInitialized = true;
    } catch (e) {
      _setError('Failed to initialize authentication: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load user data from Firestore
  Future<void> _loadUserData() async {
    try {
      _currentUser = await _authService.getCurrentUserData();
      _clearError();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load user data: $e');
    }
  }

  // Register student
  Future<bool> registerStudent({
    required String name,
    required String enrollmentNumber,
    required String course,
    required int classNumber,
    String? batch,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      // Validate inputs
      if (name.trim().isEmpty) {
        throw Exception('Name is required');
      }
      
      if (enrollmentNumber.trim().isEmpty) {
        throw Exception('Enrollment number is required');
      }
      
      if (course.trim().isEmpty) {
        throw Exception('Course is required');
      }
      
      if (!_authService.isValidCourse(course)) {
        throw Exception('Invalid course. Valid courses: ${_authService.validCourses.join(', ')}');
      }
      
      if (classNumber < 1 || classNumber > 9) {
        throw Exception('Class must be between 1 and 9');
      }
      
      if (password.length < 6) {
        throw Exception('Password must be at least 6 characters');
      }
      
      if (password != confirmPassword) {
        throw Exception('Passwords do not match');
      }

      // Check if enrollment number already exists
      if (await _authService.enrollmentNumberExists(enrollmentNumber)) {
        throw Exception('Enrollment number already registered');
      }

      // Register student
      await _authService.registerStudent(
        name: name.trim(),
        enrollmentNumber: enrollmentNumber.trim().toUpperCase(),
        course: course.trim().toUpperCase(),
        classNumber: classNumber,
        batch: batch?.trim(),
        password: password,
      );

      // Load user data after successful registration
      await _loadUserData();
      
      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Register faculty
  Future<bool> registerFaculty({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    required String department,
    required List<String> assignedCourses,
    required List<int> assignedClasses,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      // Validate inputs
      if (name.trim().isEmpty) {
        throw Exception('Name is required');
      }
      
      if (email.trim().isEmpty) {
        throw Exception('Email is required');
      }
      
      if (!_isValidEmail(email)) {
        throw Exception('Invalid email format');
      }
      
      if (department.trim().isEmpty) {
        throw Exception('Department is required');
      }
      
      if (assignedCourses.isEmpty) {
        throw Exception('At least one course must be assigned');
      }
      
      if (assignedClasses.isEmpty) {
        throw Exception('At least one class must be assigned');
      }
      
      if (password.length < 6) {
        throw Exception('Password must be at least 6 characters');
      }
      
      if (password != confirmPassword) {
        throw Exception('Passwords do not match');
      }

      // Validate courses
      for (String course in assignedCourses) {
        if (!_authService.isValidCourse(course)) {
          throw Exception('Invalid course: $course');
        }
      }

      // Register faculty
      await _authService.registerFaculty(
        name: name.trim(),
        email: email.trim().toLowerCase(),
        password: password,
        department: department.trim(),
        assignedCourses: assignedCourses.map((c) => c.trim().toUpperCase()).toList(),
        assignedClasses: assignedClasses,
      );

      // Load user data after successful registration
      await _loadUserData();
      
      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Login
  Future<bool> login(String emailOrEnrollment, String password) async {
    try {
      _setLoading(true);
      _clearError();

      if (emailOrEnrollment.trim().isEmpty) {
        throw Exception('Email or enrollment number is required');
      }
      
      if (password.isEmpty) {
        throw Exception('Password is required');
      }

      String email = emailOrEnrollment.trim();
      
      // If it's not an email, assume it's an enrollment number
      if (!email.contains('@')) {
        email = '${email.toLowerCase()}@unimark.edu';
      }

      await _authService.login(email, password);
      await _loadUserData();
      
      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      _setLoading(true);
      await _authService.logout();
      _currentUser = null;
      _clearError();
    } catch (e) {
      _setError('Failed to logout: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    try {
      _setLoading(true);
      _clearError();

      if (email.trim().isEmpty) {
        throw Exception('Email is required');
      }
      
      if (!_isValidEmail(email)) {
        throw Exception('Invalid email format');
      }

      await _authService.resetPassword(email.trim());
      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update profile
  Future<bool> updateProfile(Map<String, dynamic> updates) async {
    try {
      _setLoading(true);
      _clearError();

      await _authService.updateUserProfile(updates);
      await _loadUserData(); // Reload user data
      
      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Refresh user data
  Future<void> refreshUserData() async {
    await _loadUserData();
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Get valid courses
  List<String> get validCourses => _authService.validCourses;

  // Check if enrollment number exists
  Future<bool> checkEnrollmentNumber(String enrollmentNumber) async {
    try {
      return await _authService.enrollmentNumberExists(enrollmentNumber);
    } catch (e) {
      return false;
    }
  }
}