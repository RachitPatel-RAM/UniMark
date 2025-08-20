import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math';
import '../models/attendance_model.dart';
import '../models/user_model.dart';
import 'location_service.dart';
import 'auth_service.dart';

class AttendanceService {
  static final AttendanceService _instance = AttendanceService._internal();
  factory AttendanceService() => _instance;
  AttendanceService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocationService _locationService = LocationService();
  final AuthService _authService = AuthService();

  // Generate random 3-digit session code
  String _generateSessionCode() {
    Random random = Random();
    return (100 + random.nextInt(900)).toString();
  }

  // Create attendance session (Faculty only)
  Future<AttendanceSession> createSession({
    required String course,
    required int classNumber,
    String? batch,
    int durationMinutes = 5,
    double radiusMeters = 180.0,
  }) async {
    try {
      // Get current user (must be faculty)
      UserModel? currentUser = await _authService.getCurrentUserData();
      if (currentUser == null || currentUser.role != UserRole.faculty) {
        throw Exception('Only faculty can create attendance sessions');
      }

      // Get current location
      Position position = await _locationService.getCurrentLocation();
      
      // Check if location is mocked
      if (await _locationService.isLocationMocked()) {
        throw Exception('Mock location detected. Please use real GPS location.');
      }

      // Generate unique session code
      String sessionCode;
      bool codeExists = true;
      int attempts = 0;
      
      do {
        sessionCode = _generateSessionCode();
        
        // Check if code already exists in active sessions
        QuerySnapshot existingSessions = await _firestore
            .collection('sessions')
            .where('sessionCode', isEqualTo: sessionCode)
            .where('isActive', isEqualTo: true)
            .get();
        
        codeExists = existingSessions.docs.isNotEmpty;
        attempts++;
        
        if (attempts > 10) {
          throw Exception('Failed to generate unique session code');
        }
      } while (codeExists);

      // Create session
      String sessionId = _firestore.collection('sessions').doc().id;
      DateTime now = DateTime.now();
      
      AttendanceSession session = AttendanceSession(
        id: sessionId,
        facultyId: currentUser.id,
        facultyName: currentUser.name,
        course: course.toUpperCase(),
        classNumber: classNumber,
        batch: batch,
        sessionCode: sessionCode,
        startTime: now,
        latitude: position.latitude,
        longitude: position.longitude,
        radiusMeters: radiusMeters,
        durationMinutes: durationMinutes,
        createdAt: now,
        updatedAt: now,
      );

      // Save to Firestore
      await _firestore
          .collection('sessions')
          .doc(sessionId)
          .set(session.toMap());

      return session;
    } catch (e) {
      throw Exception('Failed to create session: $e');
    }
  }

  // Join attendance session (Student only)
  Future<AttendanceRecord> joinSession(String sessionCode) async {
    try {
      // Get current user (must be student)
      UserModel? currentUser = await _authService.getCurrentUserData();
      if (currentUser == null || currentUser.role != UserRole.student) {
        throw Exception('Only students can join attendance sessions');
      }

      StudentModel student = currentUser as StudentModel;

      // Find active session with the code
      QuerySnapshot sessionQuery = await _firestore
          .collection('sessions')
          .where('sessionCode', isEqualTo: sessionCode)
          .where('isActive', isEqualTo: true)
          .get();

      if (sessionQuery.docs.isEmpty) {
        throw Exception('Invalid or expired session code');
      }

      DocumentSnapshot sessionDoc = sessionQuery.docs.first;
      AttendanceSession session = AttendanceSession.fromMap(
        sessionDoc.data() as Map<String, dynamic>,
      );

      // Check if session is expired
      if (session.isExpired) {
        throw Exception('Session has expired');
      }

      // Check if student already marked attendance
      if (session.attendanceRecords.containsKey(student.id)) {
        throw Exception('Attendance already marked for this session');
      }

      // Check if student belongs to the session's course and class
      if (session.course != student.course || session.classNumber != student.classNumber) {
        throw Exception('You are not enrolled in this course/class');
      }

      // Check batch if specified
      if (session.batch != null && session.batch != student.batch) {
        throw Exception('You are not in the correct batch for this session');
      }

      // Get current location
      Position position = await _locationService.getCurrentLocation();
      
      // Check if location is mocked
      if (await _locationService.isLocationMocked()) {
        throw Exception('Mock location detected. Please use real GPS location.');
      }

      // Check location accuracy
      if (!await _locationService.isLocationAccuracyAcceptable()) {
        throw Exception('GPS accuracy is too low. Please move to an area with better GPS signal.');
      }

      // Calculate distance from session location
      double distance = _locationService.calculateDistance(
        position.latitude,
        position.longitude,
        session.latitude,
        session.longitude,
      );

      // Check if within allowed radius
      if (distance > session.radiusMeters) {
        throw Exception(
          'You are ${_locationService.formatDistance(distance)} away from the session location. '
          'You must be within ${_locationService.formatDistance(session.radiusMeters)} to mark attendance.',
        );
      }

      // Get device ID
      String deviceId = await _authService.getDeviceId();

      // Create attendance record
      AttendanceRecord record = AttendanceRecord(
        studentId: student.id,
        studentName: student.name,
        enrollmentNumber: student.enrollmentNumber,
        markedAt: DateTime.now(),
        studentLatitude: position.latitude,
        studentLongitude: position.longitude,
        distanceFromSession: distance,
        deviceId: deviceId,
      );

      // Update session with attendance record
      await _firestore
          .collection('sessions')
          .doc(session.id)
          .update({
        'attendanceRecords.${student.id}': record.toMap(),
        'updatedAt': DateTime.now(),
      });

      // Update student's attendance stats
      await _updateAttendanceStats(student, session.course, session.classNumber, session.batch);

      return record;
    } catch (e) {
      throw Exception('Failed to join session: $e');
    }
  }

  // Update attendance stats for student
  Future<void> _updateAttendanceStats(
    StudentModel student,
    String course,
    int classNumber,
    String? batch,
  ) async {
    try {
      String statsId = '${student.id}_${course}_$classNumber${batch != null ? '_$batch' : ''}';
      
      DocumentReference statsRef = _firestore
          .collection('attendance_stats')
          .doc(statsId);

      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot statsDoc = await transaction.get(statsRef);
        
        if (statsDoc.exists) {
          Map<String, dynamic> data = statsDoc.data() as Map<String, dynamic>;
          int totalSessions = data['totalSessions'] ?? 0;
          int presentSessions = data['presentSessions'] ?? 0;
          
          transaction.update(statsRef, {
            'totalSessions': totalSessions + 1,
            'presentSessions': presentSessions + 1,
            'lastUpdated': DateTime.now(),
          });
        } else {
          AttendanceStats stats = AttendanceStats(
            studentId: student.id,
            course: course,
            classNumber: classNumber,
            batch: batch,
            totalSessions: 1,
            presentSessions: 1,
            lastUpdated: DateTime.now(),
          );
          
          transaction.set(statsRef, stats.toMap());
        }
      });
    } catch (e) {
      // Don't throw error for stats update failure
      print('Failed to update attendance stats: $e');
    }
  }

  // End session (Faculty only)
  Future<void> endSession(String sessionId) async {
    try {
      UserModel? currentUser = await _authService.getCurrentUserData();
      if (currentUser == null || currentUser.role != UserRole.faculty) {
        throw Exception('Only faculty can end sessions');
      }

      await _firestore
          .collection('sessions')
          .doc(sessionId)
          .update({
        'isActive': false,
        'endTime': DateTime.now(),
        'updatedAt': DateTime.now(),
      });
    } catch (e) {
      throw Exception('Failed to end session: $e');
    }
  }

  // Get active sessions for faculty
  Stream<List<AttendanceSession>> getFacultyActiveSessions(String facultyId) {
    return _firestore
        .collection('sessions')
        .where('facultyId', isEqualTo: facultyId)
        .where('isActive', isEqualTo: true)
        .orderBy('startTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AttendanceSession.fromMap(doc.data()))
            .toList());
  }

  // Get session by ID
  Future<AttendanceSession?> getSessionById(String sessionId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('sessions')
          .doc(sessionId)
          .get();
      
      if (!doc.exists) return null;
      
      return AttendanceSession.fromMap(doc.data() as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to get session: $e');
    }
  }

  // Get session by code
  Future<AttendanceSession?> getSessionByCode(String sessionCode) async {
    try {
      QuerySnapshot sessionQuery = await _firestore
          .collection('sessions')
          .where('sessionCode', isEqualTo: sessionCode)
          .where('isActive', isEqualTo: true)
          .get();

      if (sessionQuery.docs.isEmpty) {
        return null;
      }

      DocumentSnapshot sessionDoc = sessionQuery.docs.first;
      return AttendanceSession.fromMap(
        sessionDoc.data() as Map<String, dynamic>,
      );
    } catch (e) {
      throw Exception('Failed to get session by code: $e');
    }
  }

  // Get attendance history for student
  Stream<List<AttendanceSession>> getStudentAttendanceHistory(String studentId) {
    return _firestore
        .collection('sessions')
        .where('attendanceRecords.$studentId', isNotEqualTo: null)
        .orderBy('startTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AttendanceSession.fromMap(doc.data()))
            .toList());
  }

  // Get attendance stats for student
  Future<List<AttendanceStats>> getStudentAttendanceStats(String studentId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('attendance_stats')
          .where('studentId', isEqualTo: studentId)
          .get();
      
      return snapshot.docs
          .map((doc) => AttendanceStats.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get attendance stats: $e');
    }
  }

  // Edit attendance (Faculty/Admin only)
  Future<void> editAttendance(
    String sessionId,
    String studentId,
    bool isPresent,
    String reason,
  ) async {
    try {
      UserModel? currentUser = await _authService.getCurrentUserData();
      if (currentUser == null || 
          (currentUser.role != UserRole.faculty && currentUser.role != UserRole.admin)) {
        throw Exception('Only faculty and admin can edit attendance');
      }

      // Get session
      AttendanceSession? session = await getSessionById(sessionId);
      if (session == null) {
        throw Exception('Session not found');
      }

      // Check edit permissions
      if (currentUser.role == UserRole.faculty) {
        if (session.facultyId != currentUser.id) {
          throw Exception('You can only edit your own sessions');
        }
        if (!session.canEdit) {
          throw Exception('Session can only be edited within 48 hours');
        }
      }

      // Update attendance record
      Map<String, dynamic> updates = {};
      
      if (session.attendanceRecords.containsKey(studentId)) {
        // Update existing record
        AttendanceRecord existingRecord = session.attendanceRecords[studentId]!;
        AttendanceRecord updatedRecord = existingRecord.copyWith(
          isPresent: isPresent,
          editedBy: currentUser.id,
          editedAt: DateTime.now(),
          editReason: reason,
        );
        updates['attendanceRecords.$studentId'] = updatedRecord.toMap();
      } else if (isPresent) {
        // Create new record for absent student being marked present
        AttendanceRecord newRecord = AttendanceRecord(
          studentId: studentId,
          studentName: 'Manual Entry',
          enrollmentNumber: 'Manual',
          markedAt: DateTime.now(),
          studentLatitude: session.latitude,
          studentLongitude: session.longitude,
          distanceFromSession: 0.0,
          deviceId: 'manual',
          isPresent: true,
          editedBy: currentUser.id,
          editedAt: DateTime.now(),
          editReason: reason,
        );
        updates['attendanceRecords.$studentId'] = newRecord.toMap();
      }

      updates['updatedAt'] = DateTime.now();

      await _firestore
          .collection('sessions')
          .doc(sessionId)
          .update(updates);
    } catch (e) {
      throw Exception('Failed to edit attendance: $e');
    }
  }

  // Get sessions for course and class
  Future<List<AttendanceSession>> getSessionsForClass(
    String course,
    int classNumber,
    String? batch,
    {DateTime? startDate,
    DateTime? endDate}
  ) async {
    try {
      Query query = _firestore
          .collection('sessions')
          .where('course', isEqualTo: course.toUpperCase())
          .where('classNumber', isEqualTo: classNumber);
      
      if (batch != null) {
        query = query.where('batch', isEqualTo: batch);
      }
      
      if (startDate != null) {
        query = query.where('startTime', isGreaterThanOrEqualTo: startDate);
      }
      
      if (endDate != null) {
        query = query.where('startTime', isLessThanOrEqualTo: endDate);
      }
      
      QuerySnapshot snapshot = await query
          .orderBy('startTime', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => AttendanceSession.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get sessions: $e');
    }
  }
}