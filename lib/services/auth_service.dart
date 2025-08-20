import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:io';
import '../models/user_model.dart';
import '../services/exceptions.dart';
import '../config.dart';

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
    try {
      String deviceId = '';
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
      throw AuthException('Failed to get device ID: $e');
    }
  }

  // Check if device is rooted/jailbroken (basic check)
  Future<void> isDeviceSecure() async {
    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await _deviceInfo.androidInfo;
        // Basic check for rooted device indicators
        if (androidInfo.isPhysicalDevice ||
               androidInfo.model.toLowerCase().contains('emulator') ||
               androidInfo.product.toLowerCase().contains('sdk')) {
          throw AuthException('Device security check failed. Rooted/jailbroken devices are not allowed.');
        }
      }
      // For iOS, assume secure for now
    } catch (e) {
      throw AuthException('Failed to check device security: $e');
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
      await isDeviceSecure();
      String deviceId = await getDeviceId();
      String email = '${enrollmentNumber.toLowerCase()}@${AppConfig.emailDomain}';
      
      if (await enrollmentNumberExists(enrollmentNumber)) {
        throw EnrollmentNumberAlreadyExistsException();
      }

      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

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
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw WeakPasswordException();
      } else if (e.code == 'email-already-in-use') {
        throw EmailAlreadyInUseException();
      } else if (e.code == 'invalid-email') {
        throw InvalidEmailException();
      } else {
        throw NetworkException();
      }
    } catch (e) {
      throw UnknownException();
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
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

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
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw WeakPasswordException();
      } else if (e.code == 'email-already-in-use') {
        throw EmailAlreadyInUseException();
      } else if (e.code == 'invalid-email') {
        throw InvalidEmailException();
      } else {
        throw NetworkException();
      }
    } catch (e) {
      throw UnknownException();
    }
  }

  // Login with device binding check
  Future<UserCredential?> login(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        await _auth.signOut();
        throw UserNotFoundException();
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      
      if (userData['isActive'] != true) {
        await _auth.signOut();
        throw UserDisabledException();
      }

      if (userData['role'] == UserRole.student.name) {
        String currentDeviceId = await getDeviceId();
        String? registeredDeviceId = userData['deviceId'];

        if (registeredDeviceId != null && registeredDeviceId != currentDeviceId) {
          await _auth.signOut();
          throw DeviceBindingException();
        }

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
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        throw InvalidCredentialsException();
      } else if (e.code == 'user-disabled') {
        throw UserDisabledException();
      } else if (e.code == 'too-many-requests') {
        throw TooManyRequestsException();
      } else {
        throw NetworkException();
      }
    } catch (e) {
      throw UnknownException();
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
      
      final role = UserRole.values.byName(userData['role'] ?? UserRole.student.name);

      switch (role) {
        case UserRole.student:
          return StudentModel.fromMap(userData);
        case UserRole.faculty:
          return FacultyModel.fromMap(userData);
        case UserRole.admin:
          return UserModel.fromMap(userData);
      }
    } catch (e) {
      throw FirestoreException('Failed to get user data.');
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw AuthException('Logout failed: $e');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw UserNotFoundException();
      } else {
        throw NetworkException();
      }
    } catch (e) {
      throw UnknownException();
    }
  }

  // Update user profile
  Future<void> updateUserProfile(Map<String, dynamic> updates) async {
    try {
      if (currentUser == null) throw AuthException('No user logged in');
      
      updates['updatedAt'] = DateTime.now();
      
      await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .update(updates);
    } on FirebaseException catch (e) {
      throw FirestoreException(e.message ?? 'Profile update failed.');
    } catch (e) {
      throw UnknownException();
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
      throw FirestoreException('Failed to check enrollment number.');
    }
  }

  // Validate course name
  List<String> get validCourses => AppConfig.validCourses;

  bool isValidCourse(String course) {
    return validCourses.contains(course.toUpperCase());
  }
}