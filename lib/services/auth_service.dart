import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:io';
import '../models/user_model.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get unique device ID
  Future<String> getDeviceId() async {
    String deviceId = '';
    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await _deviceInfo.androidInfo;
        deviceId = androidInfo.id;
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await _deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? '';
      }
      
      // Create a hash of the device ID for security
      var bytes = utf8.encode(deviceId);
      var digest = sha256.convert(bytes);
      return digest.toString();
    } catch (e) {
      throw Exception('Failed to get device ID: $e');
    }
  }

  // Check if device is rooted/jailbroken (basic check)
  Future<bool> isDeviceSecure() async {
    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await _deviceInfo.androidInfo;
        // Basic check for rooted device indicators
        return !androidInfo.isPhysicalDevice || 
               androidInfo.model.toLowerCase().contains('emulator') ||
               androidInfo.product.toLowerCase().contains('sdk');
      }
      return true; // For iOS, assume secure for now
    } catch (e) {
      return false; // If we can't check, assume insecure
    }
  }

  // Register student
  Future<UserCredential?> registerStudent({
    required String name,
    required String enrollmentNumber,
    required String course,
    required int classNumber,
    String? batch,
    required String password,
  }) async {
    try {
      // Check device security
      if (!await isDeviceSecure()) {
        throw Exception('Device security check failed. Rooted/jailbroken devices are not allowed.');
      }

      String deviceId = await getDeviceId();
      String email = '${enrollmentNumber.toLowerCase()}@unimark.edu';
      
      // Check if enrollment number already exists
      final existingStudent = await _firestore
          .collection('users')
          .where('enrollmentNumber', isEqualTo: enrollmentNumber)
          .get();
      
      if (existingStudent.docs.isNotEmpty) {
        throw Exception('Enrollment number already registered');
      }

      // Create Firebase Auth user
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create student document
      final student = StudentModel(
        id: userCredential.user!.uid,
        name: name,
        email: email,
        enrollmentNumber: enrollmentNumber,
        course: course.toUpperCase(),
        classNumber: classNumber,
        batch: batch,
        deviceId: deviceId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(student.toMap());

      return userCredential;
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  // Register faculty
  Future<UserCredential?> registerFaculty({
    required String name,
    required String email,
    required String password,
    required String department,
    required List<String> assignedCourses,
    required List<int> assignedClasses,
  }) async {
    try {
      // Create Firebase Auth user
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create faculty document
      final faculty = FacultyModel(
        id: userCredential.user!.uid,
        name: name,
        email: email,
        department: department,
        assignedCourses: assignedCourses.map((c) => c.toUpperCase()).toList(),
        assignedClasses: assignedClasses,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(faculty.toMap());

      return userCredential;
    } catch (e) {
      throw Exception('Faculty registration failed: $e');
    }
  }

  // Login with device binding check
  Future<UserCredential?> login(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Get user document
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        await _auth.signOut();
        throw Exception('User data not found');
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      
      // Check if user is active
      if (userData['isActive'] != true) {
        await _auth.signOut();
        throw Exception('Account is deactivated');
      }

      // For students, check device binding
      if (userData['role'] == 'student') {
        String currentDeviceId = await getDeviceId();
        String? registeredDeviceId = userData['deviceId'];

        if (registeredDeviceId != null && registeredDeviceId != currentDeviceId) {
          await _auth.signOut();
          throw Exception('This account is bound to another device');
        }

        // Update device ID if not set
        if (registeredDeviceId == null) {
          await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .update({
            'deviceId': currentDeviceId,
            'updatedAt': DateTime.now(),
          });
        }
      }

      return userCredential;
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  // Get current user data
  Future<UserModel?> getCurrentUserData() async {
    try {
      if (currentUser == null) return null;

      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .get();

      if (!userDoc.exists) return null;

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      
      switch (userData['role']) {
        case 'student':
          return StudentModel.fromMap(userData);
        case 'faculty':
          return FacultyModel.fromMap(userData);
        case 'admin':
          return UserModel.fromMap(userData);
        default:
          return UserModel.fromMap(userData);
      }
    } catch (e) {
      throw Exception('Failed to get user data: $e');
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Logout failed: $e');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception('Password reset failed: $e');
    }
  }

  // Update user profile
  Future<void> updateUserProfile(Map<String, dynamic> updates) async {
    try {
      if (currentUser == null) throw Exception('No user logged in');
      
      updates['updatedAt'] = DateTime.now();
      
      await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .update(updates);
    } catch (e) {
      throw Exception('Profile update failed: $e');
    }
  }

  // Check if enrollment number exists
  Future<bool> enrollmentNumberExists(String enrollmentNumber) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('enrollmentNumber', isEqualTo: enrollmentNumber)
          .get();
      
      return query.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Validate course name
  List<String> get validCourses => [
    'BTECH',
    'CIVIL',
    'MECHANICAL',
    'ELECTRICAL',
    'COMPUTER',
    'ELECTRONICS',
    'CHEMICAL',
    'AEROSPACE',
    'BIOMEDICAL',
    'ENVIRONMENTAL'
  ];

  bool isValidCourse(String course) {
    return validCourses.contains(course.toUpperCase());
  }
}