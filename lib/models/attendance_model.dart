import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceSession {
  final String id;
  final String facultyId;
  final String facultyName;
  final String course;
  final int classNumber;
  final String? batch;
  final String sessionCode;
  final DateTime startTime;
  final DateTime? endTime;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final int durationMinutes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, AttendanceRecord> attendanceRecords;

  AttendanceSession({
    required this.id,
    required this.facultyId,
    required this.facultyName,
    required this.course,
    required this.classNumber,
    this.batch,
    required this.sessionCode,
    required this.startTime,
    this.endTime,
    required this.latitude,
    required this.longitude,
    this.radiusMeters = 180.0,
    this.durationMinutes = 5,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.attendanceRecords = const {},
  });

  bool get isExpired {
    return DateTime.now().difference(startTime).inMinutes > durationMinutes;
  }

  bool get canEdit {
    return DateTime.now().difference(startTime).inHours <= 48;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'facultyId': facultyId,
      'facultyName': facultyName,
      'course': course,
      'classNumber': classNumber,
      'batch': batch,
      'sessionCode': sessionCode,
      'startTime': startTime,
      'endTime': endTime,
      'latitude': latitude,
      'longitude': longitude,
      'radiusMeters': radiusMeters,
      'durationMinutes': durationMinutes,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'attendanceRecords': attendanceRecords.map(
        (key, value) => MapEntry(key, value.toMap()),
      ),
    };
  }

  factory AttendanceSession.fromMap(Map<String, dynamic> map) {
    return AttendanceSession(
      id: map['id'] ?? '',
      facultyId: map['facultyId'] ?? '',
      facultyName: map['facultyName'] ?? '',
      course: map['course'] ?? '',
      classNumber: map['classNumber'] ?? 1,
      batch: map['batch'],
      sessionCode: map['sessionCode'] ?? '',
      startTime: (map['startTime'] as Timestamp).toDate(),
      endTime: map['endTime'] != null ? (map['endTime'] as Timestamp).toDate() : null,
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
      radiusMeters: map['radiusMeters']?.toDouble() ?? 180.0,
      durationMinutes: map['durationMinutes'] ?? 5,
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      attendanceRecords: (map['attendanceRecords'] as Map<String, dynamic>? ?? {})
          .map((key, value) => MapEntry(key, AttendanceRecord.fromMap(value))),
    );
  }

  AttendanceSession copyWith({
    String? id,
    String? facultyId,
    String? facultyName,
    String? course,
    int? classNumber,
    String? batch,
    String? sessionCode,
    DateTime? startTime,
    DateTime? endTime,
    double? latitude,
    double? longitude,
    double? radiusMeters,
    int? durationMinutes,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, AttendanceRecord>? attendanceRecords,
  }) {
    return AttendanceSession(
      id: id ?? this.id,
      facultyId: facultyId ?? this.facultyId,
      facultyName: facultyName ?? this.facultyName,
      course: course ?? this.course,
      classNumber: classNumber ?? this.classNumber,
      batch: batch ?? this.batch,
      sessionCode: sessionCode ?? this.sessionCode,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      attendanceRecords: attendanceRecords ?? this.attendanceRecords,
    );
  }
}

// A view model for displaying student attendance history
class StudentAttendanceRecordView {
  final String sessionId;
  final String course;
  final int classNumber;
  final String? batch;
  final DateTime sessionDate;
  final bool isPresent;
  final String studentId;
  final String studentName;
  final String enrollmentNumber;
  final DateTime markedAt;

  StudentAttendanceRecordView({
    required this.sessionId,
    required this.course,
    required this.classNumber,
    this.batch,
    required this.sessionDate,
    required this.isPresent,
    required this.studentId,
    required this.studentName,
    required this.enrollmentNumber,
    required this.markedAt,
  });
}

class AttendanceRecord {
  final String studentId;
  final String studentName;
  final String enrollmentNumber;
  final DateTime markedAt;
  final double studentLatitude;
  final double studentLongitude;
  final double distanceFromSession;
  final String deviceId;
  final bool isPresent;
  final String? editedBy;
  final DateTime? editedAt;
  final String? editReason;

  AttendanceRecord({
    required this.studentId,
    required this.studentName,
    required this.enrollmentNumber,
    required this.markedAt,
    required this.studentLatitude,
    required this.studentLongitude,
    required this.distanceFromSession,
    required this.deviceId,
    this.isPresent = true,
    this.editedBy,
    this.editedAt,
    this.editReason,
  });

  String get status => isPresent ? 'Present' : 'Absent';

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'enrollmentNumber': enrollmentNumber,
      'markedAt': markedAt,
      'studentLatitude': studentLatitude,
      'studentLongitude': studentLongitude,
      'distanceFromSession': distanceFromSession,
      'deviceId': deviceId,
      'isPresent': isPresent,
      'editedBy': editedBy,
      'editedAt': editedAt,
      'editReason': editReason,
    };
  }

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      enrollmentNumber: map['enrollmentNumber'] ?? '',
      markedAt: (map['markedAt'] as Timestamp).toDate(),
      studentLatitude: map['studentLatitude']?.toDouble() ?? 0.0,
      studentLongitude: map['studentLongitude']?.toDouble() ?? 0.0,
      distanceFromSession: map['distanceFromSession']?.toDouble() ?? 0.0,
      deviceId: map['deviceId'] ?? '',
      isPresent: map['isPresent'] ?? true,
      editedBy: map['editedBy'],
      editedAt: map['editedAt'] != null ? (map['editedAt'] as Timestamp).toDate() : null,
      editReason: map['editReason'],
    );
  }

  AttendanceRecord copyWith({
    String? studentId,
    String? studentName,
    String? enrollmentNumber,
    DateTime? markedAt,
    double? studentLatitude,
    double? studentLongitude,
    double? distanceFromSession,
    String? deviceId,
    bool? isPresent,
    String? editedBy,
    DateTime? editedAt,
    String? editReason,
  }) {
    return AttendanceRecord(
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      enrollmentNumber: enrollmentNumber ?? this.enrollmentNumber,
      markedAt: markedAt ?? this.markedAt,
      studentLatitude: studentLatitude ?? this.studentLatitude,
      studentLongitude: studentLongitude ?? this.studentLongitude,
      distanceFromSession: distanceFromSession ?? this.distanceFromSession,
      deviceId: deviceId ?? this.deviceId,
      isPresent: isPresent ?? this.isPresent,
      editedBy: editedBy ?? this.editedBy,
      editedAt: editedAt ?? this.editedAt,
      editReason: editReason ?? this.editReason,
    );
  }
}

class AttendanceStats {
  final String studentId;
  final String course;
  final int classNumber;
  final String? batch;
  final int totalSessions;
  final int presentSessions;
  final double attendancePercentage;
  final DateTime lastUpdated;

  AttendanceStats({
    required this.studentId,
    required this.course,
    required this.classNumber,
    this.batch,
    required this.totalSessions,
    required this.presentSessions,
    required this.lastUpdated,
  }) : attendancePercentage = totalSessions > 0 ? (presentSessions / totalSessions) * 100 : 0.0;

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'course': course,
      'classNumber': classNumber,
      'batch': batch,
      'totalSessions': totalSessions,
      'presentSessions': presentSessions,
      'attendancePercentage': attendancePercentage,
      'lastUpdated': lastUpdated,
    };
  }

  factory AttendanceStats.fromMap(Map<String, dynamic> map) {
    return AttendanceStats(
      studentId: map['studentId'] ?? '',
      course: map['course'] ?? '',
      classNumber: map['classNumber'] ?? 1,
      batch: map['batch'],
      totalSessions: map['totalSessions'] ?? 0,
      presentSessions: map['presentSessions'] ?? 0,
      lastUpdated: (map['lastUpdated'] as Timestamp).toDate(),
    );
  }
}