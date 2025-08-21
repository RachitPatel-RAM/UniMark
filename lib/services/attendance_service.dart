import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../models/attendance_model.dart';
import '../models/user_model.dart';
import 'location_service.dart';
import 'exceptions.dart';

class AttendanceService {
  static final AttendanceService _instance = AttendanceService._internal();
  factory AttendanceService() => _instance;
  AttendanceService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocationService _locationService = LocationService();

  String _generateSessionCode() {
    Random random = Random();
    return (100 + random.nextInt(900)).toString();
  }

  Future<AttendanceSession> createSession({
    required String facultyId,
    required String facultyName,
    required String course,
    required int classNumber,
    required double latitude,
    required double longitude,
    String? batch,
    int durationMinutes = 5,
    double radiusMeters = 180.0,
  }) async {
    try {
      String sessionCode;
      bool codeExists;
      int attempts = 0;
      do {
        sessionCode = _generateSessionCode();
        QuerySnapshot existingSessions = await _firestore
            .collection('sessions')
            .where('sessionCode', isEqualTo: sessionCode)
            .where('isActive', isEqualTo: true)
            .get();
        codeExists = existingSessions.docs.isNotEmpty;
        attempts++;
        if (attempts > 10) throw Exception('Failed to generate unique session code');
      } while (codeExists);

      String sessionId = _firestore.collection('sessions').doc().id;
      DateTime now = DateTime.now();
      
      AttendanceSession session = AttendanceSession(
        id: sessionId,
        facultyId: facultyId,
        facultyName: facultyName,
        course: course.toUpperCase(),
        classNumber: classNumber,
        batch: batch,
        sessionCode: sessionCode,
        startTime: now,
        latitude: latitude,
        longitude: longitude,
        radiusMeters: radiusMeters,
        durationMinutes: durationMinutes,
        createdAt: now,
        updatedAt: now,
      );

      await _firestore.collection('sessions').doc(sessionId).set(session.toMap());
      return session;
    } catch (e) {
      throw FirestoreException('Failed to create session: ${e.toString()}');
    }
  }

  Future<AttendanceSession> joinSession({
    required String sessionCode,
    required StudentModel student,
    required double latitude,
    required double longitude,
  }) async {
    try {
      QuerySnapshot sessionQuery = await _firestore
          .collection('sessions')
          .where('sessionCode', isEqualTo: sessionCode)
          .where('isActive', isEqualTo: true)
          .get();

      if (sessionQuery.docs.isEmpty) {
        throw AuthException('Invalid or expired session code');
      }

      DocumentSnapshot sessionDoc = sessionQuery.docs.first;
      AttendanceSession session = AttendanceSession.fromMap(sessionDoc.data() as Map<String, dynamic>);

      if (session.isExpired) throw AuthException('Session has expired');
      if (session.attendanceRecords.containsKey(student.id)) {
        throw AuthException('Attendance already marked for this session');
      }
      if (session.course != student.course || session.classNumber != student.classNumber) {
        throw AuthException('You are not enrolled in this course/class');
      }
      if (session.batch != null && session.batch != student.batch) {
        throw AuthException('You are not in the correct batch for this session');
      }

      double distance = _locationService.calculateDistance(latitude, longitude, session.latitude, session.longitude);

      if (distance > session.radiusMeters) {
        throw AuthException('You are too far from the session location.');
      }

      AttendanceRecord record = AttendanceRecord(
        studentId: student.id,
        studentName: student.name,
        enrollmentNumber: student.enrollmentNumber,
        markedAt: DateTime.now(),
        studentLatitude: latitude,
        studentLongitude: longitude,
        distanceFromSession: distance,
        deviceId: 'TBD', // Device ID should be handled by AuthService
      );

      await _firestore.collection('sessions').doc(session.id).update({
        'attendanceRecords.${student.id}': record.toMap(),
        'updatedAt': DateTime.now(),
      });

      // The stats are calculated on the fly, so no update is needed here.
      return session;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw FirestoreException('Failed to join session: ${e.toString()}');
    }
  }

  Future<void> endSession(String sessionId) async {
    try {
      await _firestore.collection('sessions').doc(sessionId).update({
        'isActive': false,
        'endTime': DateTime.now(),
        'updatedAt': DateTime.now(),
      });
    } catch (e) {
      throw FirestoreException('Failed to end session: ${e.toString()}');
    }
  }

  Stream<List<AttendanceRecord>> getSessionAttendanceStream(String sessionId) {
    return _firestore
        .collection('sessions')
        .doc(sessionId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return [];
      final session = AttendanceSession.fromMap(snapshot.data()!);
      return session.attendanceRecords.values.toList()
        ..sort((a, b) => a.markedAt.compareTo(b.markedAt));
    });
  }

  Future<List<AttendanceSession>> getFacultySessions(String facultyId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('sessions')
          .where('facultyId', isEqualTo: facultyId)
          .orderBy('startTime', descending: true)
          .get();
      
      return snapshot.docs.map((doc) => AttendanceSession.fromMap(doc.data() as Map<String, dynamic>)).toList();
    } catch (e) {
      throw FirestoreException('Failed to get faculty sessions: ${e.toString()}');
    }
  }

  Future<List<AttendanceSession>> getAttendanceHistory({
    required String facultyId,
    String? course,
    int? classNumber,
    String? batch,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore
          .collection('sessions')
          .where('facultyId', isEqualTo: facultyId);

      if (course != null) query = query.where('course', isEqualTo: course);
      if (classNumber != null) query = query.where('classNumber', isEqualTo: classNumber);
      if (batch != null) query = query.where('batch', isEqualTo: batch);
      if (startDate != null) query = query.where('startTime', isGreaterThanOrEqualTo: startDate);
      if (endDate != null) query = query.where('startTime', isLessThanOrEqualTo: endDate);

      QuerySnapshot snapshot = await query.orderBy('startTime', descending: true).get();

      return snapshot.docs.map((doc) => AttendanceSession.fromMap(doc.data() as Map<String, dynamic>)).toList();
    } catch (e) {
      throw FirestoreException('Failed to get attendance history: ${e.toString()}');
    }
  }

  Future<List<StudentAttendanceRecordView>> getStudentAttendanceHistory({
    required String studentId,
  }) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('sessions')
          .where('attendanceRecords.$studentId', isNotEqualTo: null)
          .orderBy('startTime', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final session = AttendanceSession.fromMap(doc.data() as Map<String, dynamic>);
        final record = session.attendanceRecords[studentId]!;
        return StudentAttendanceRecordView(
          sessionId: session.id,
          course: session.course,
          classNumber: session.classNumber,
          batch: session.batch,
          sessionDate: session.startTime,
          isPresent: record.isPresent,
          studentId: record.studentId,
          studentName: record.studentName,
          enrollmentNumber: record.enrollmentNumber,
          markedAt: record.markedAt,
        );
      }).toList();
    } catch (e) {
      throw FirestoreException('Failed to get student attendance history: ${e.toString()}');
    }
  }

  Future<AttendanceStats?> getStudentAttendanceStats(String studentId) async {
    try {
      // This is a simplified version. A real app might aggregate this on the backend.
      QuerySnapshot snapshot = await _firestore
          .collection('sessions')
          .where('attendanceRecords.$studentId', isNotEqualTo: null)
          .get();
      
      if (snapshot.docs.isEmpty) return null;

      int totalSessions = snapshot.docs.length;
      int presentSessions = 0;
      for (var doc in snapshot.docs) {
        final session = AttendanceSession.fromMap(doc.data() as Map<String, dynamic>);
        if (session.attendanceRecords[studentId]?.isPresent == true) {
          presentSessions++;
        }
      }

      final studentData = (await _firestore.collection('users').doc(studentId).get()).data();

      return AttendanceStats(
        studentId: studentId,
        course: studentData?['course'] ?? '',
        classNumber: studentData?['classNumber'] ?? 0,
        batch: studentData?['batch'],
        totalSessions: totalSessions,
        presentSessions: presentSessions,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      throw FirestoreException('Failed to get attendance stats: ${e.toString()}');
    }
  }

  Future<void> editAttendance({
    required String sessionId,
    required String studentId,
    required bool isPresent,
    required String editorId,
    String? reason,
  }) async {
    try {
      DocumentReference sessionRef = _firestore.collection('sessions').doc(sessionId);

      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot sessionDoc = await transaction.get(sessionRef);
        if (!sessionDoc.exists) throw FirestoreException('Session not found');

        AttendanceSession session = AttendanceSession.fromMap(sessionDoc.data() as Map<String, dynamic>);

        if (session.facultyId != editorId) {
           throw AuthException('You do not have permission to edit this session.');
        }

        if (!session.canEdit) {
          throw AuthException('Session can only be edited within 48 hours of its start time.');
        }

        AttendanceRecord? record = session.attendanceRecords[studentId];
        if (record == null) throw FirestoreException('Student attendance record not found.');

        AttendanceRecord updatedRecord = record.copyWith(
          isPresent: isPresent,
          editedBy: editorId,
          editedAt: DateTime.now(),
          editReason: reason,
        );

        transaction.update(sessionRef, {
          'attendanceRecords.$studentId': updatedRecord.toMap(),
          'updatedAt': DateTime.now(),
        });
      });
    } catch (e) {
      throw FirestoreException('Failed to edit attendance: ${e.toString()}');
    }
  }
}