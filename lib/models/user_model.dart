import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { student, faculty, admin }

class UserModel {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? deviceId;
  final bool isActive;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
    this.deviceId,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.name,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'deviceId': deviceId,
      'isActive': isActive,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      role: UserRole.values.byName(map['role'] ?? UserRole.student.name),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      deviceId: map['deviceId'],
      isActive: map['isActive'] ?? true,
    );
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? deviceId,
    bool? isActive,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deviceId: deviceId ?? this.deviceId,
      isActive: isActive ?? this.isActive,
    );
  }
}

class StudentModel extends UserModel {
  final String enrollmentNumber;
  final String course;
  final int classNumber;
  final String? batch;

  StudentModel({
    required super.id,
    required super.name,
    required super.email,
    required super.createdAt,
    required super.updatedAt,
    super.deviceId,
    super.isActive,
    required this.enrollmentNumber,
    required this.course,
    required this.classNumber,
    this.batch,
  }) : super(role: UserRole.student);

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map.addAll({
      'enrollmentNumber': enrollmentNumber,
      'course': course,
      'classNumber': classNumber,
      'batch': batch,
    });
    return map;
  }

  factory StudentModel.fromMap(Map<String, dynamic> map) {
    return StudentModel(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      deviceId: map['deviceId'],
      isActive: map['isActive'] ?? true,
      enrollmentNumber: map['enrollmentNumber'],
      course: map['course'],
      classNumber: map['classNumber'],
      batch: map['batch'],
    );
  }

  @override
  StudentModel copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? deviceId,
    bool? isActive,
    String? enrollmentNumber,
    String? course,
    int? classNumber,
    String? batch,
  }) {
    return StudentModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deviceId: deviceId ?? this.deviceId,
      isActive: isActive ?? this.isActive,
      enrollmentNumber: enrollmentNumber ?? this.enrollmentNumber,
      course: course ?? this.course,
      classNumber: classNumber ?? this.classNumber,
      batch: batch ?? this.batch,
    );
  }
}

class FacultyModel extends UserModel {
  final String department;
  final List<String> assignedCourses;
  final List<int> assignedClasses;

  FacultyModel({
    required super.id,
    required super.name,
    required super.email,
    required super.createdAt,
    required super.updatedAt,
    super.deviceId,
    super.isActive,
    required this.department,
    required this.assignedCourses,
    required this.assignedClasses,
  }) : super(role: UserRole.faculty);

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map.addAll({
      'department': department,
      'assignedCourses': assignedCourses,
      'assignedClasses': assignedClasses,
    });
    return map;
  }

  factory FacultyModel.fromMap(Map<String, dynamic> map) {
    return FacultyModel(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      deviceId: map['deviceId'],
      isActive: map['isActive'] ?? true,
      department: map['department'],
      assignedCourses: List<String>.from(map['assignedCourses'] ?? []),
      assignedClasses: List<int>.from(map['assignedClasses'] ?? []),
    );
  }
}