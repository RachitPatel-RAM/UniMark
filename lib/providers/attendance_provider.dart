import 'dart:async';
import 'package:flutter/material.dart';
import '../models/attendance_model.dart';
import '../models/user_model.dart';
import '../services/attendance_service.dart';
import '../services/location_service.dart';
import '../services/exceptions.dart';
import 'auth_provider.dart';

class AttendanceProvider extends ChangeNotifier {
  final AttendanceService _attendanceService = AttendanceService();
  
  // Current session state
  AttendanceSession? _currentSession;
  bool _isLoading = false;
  String? _errorMessage;
  
  // Session management
  bool _isCreatingSession = false;
  bool _isJoiningSession = false;
  
  // Attendance history
  List<AttendanceSession> _attendanceHistory = [];
  List<StudentAttendanceRecordView> _studentAttendanceHistory = [];
  AttendanceStats? _attendanceStats;
  
  // Filters for reports
  String? _selectedCourse;
  int? _selectedClass;
  String? _selectedBatch;
  String? _selectedStudent;
  DateTime? _startDate;
  DateTime? _endDate;

  // Getters
  AttendanceSession? get currentSession => _currentSession;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isCreatingSession => _isCreatingSession;
  bool get isJoiningSession => _isJoiningSession;
  bool get hasActiveSession => _currentSession != null && _currentSession!.isActive;
  
  List<AttendanceSession> get attendanceHistory => _attendanceHistory;
  List<StudentAttendanceRecordView> get studentAttendanceHistory => _studentAttendanceHistory;
  AttendanceStats? get attendanceStats => _attendanceStats;
  
  // Filter getters
  String? get selectedCourse => _selectedCourse;
  int? get selectedClass => _selectedClass;
  String? get selectedBatch => _selectedBatch;
  String? get selectedStudent => _selectedStudent;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;

  // Create attendance session (Faculty only)
  Future<bool> createSession({
    required String course,
    required int classNumber,
    String? batch,
    required AuthProvider authProvider,
  }) async {
    _setCreatingSession(true);
    _clearError();

    try {
      final user = authProvider.currentUser;
      if (user is! FacultyModel) {
        throw AuthException('Only faculty can create sessions.');
      }

      // TODO: The service should get the location, not the provider.
      // This requires refactoring LocationService to not depend on a provider.
      final locationService = LocationService();
      final location = await locationService.getCurrentLocation();
      if (location == null) {
        throw AuthException('Unable to get current location. Please enable GPS.');
      }

      _currentSession = await _attendanceService.createSession(
        course: course.toUpperCase(),
        classNumber: classNumber,
        batch: batch,
        facultyId: user.id,
        facultyName: user.name,
        latitude: location.latitude,
        longitude: location.longitude,
      );
      
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('An unknown error occurred during session creation.');
      return false;
    } finally {
      _setCreatingSession(false);
    }
  }

  // Join attendance session (Student only)
  Future<bool> joinSession({
    required String sessionCode,
    required AuthProvider authProvider,
  }) async {
    _setJoiningSession(true);
    _clearError();

    try {
      final user = authProvider.currentUser;
      if (user is! StudentModel) {
        throw AuthException('Only students can join sessions.');
      }

      // TODO: The service should get the location.
      final locationService = LocationService();
      final location = await locationService.getCurrentLocation();
      if (location == null) {
        throw AuthException('Unable to get current location. Please enable GPS.');
      }

      final result = await _attendanceService.joinSession(
        sessionCode: sessionCode.toUpperCase(),
        student: user,
        latitude: location.latitude,
        longitude: location.longitude,
      );

      _currentSession = result;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('An unknown error occurred while joining the session.');
      return false;
    } finally {
      _setJoiningSession(false);
    }
  }

  // End current session (Faculty only)
  Future<bool> endSession({
    required String sessionId,
    required AuthProvider authProvider,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      if (authProvider.currentUser is! FacultyModel) {
        throw AuthException('Only faculty can end sessions.');
      }

      await _attendanceService.endSession(sessionId);

      if (_currentSession?.id == sessionId) {
        _currentSession = null;
      }
      // Also remove from history list to update UI immediately
      _attendanceHistory.removeWhere((s) => s.id == sessionId);

      notifyListeners();
      return true;
    } on AuthException catch(e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('An unknown error occurred while ending the session.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get stream of attendance records for a session
  Stream<List<AttendanceRecord>> getSessionAttendanceStream(String sessionId) {
    return _attendanceService.getSessionAttendanceStream(sessionId);
  }

  // Load attendance history for a faculty member
  Future<void> loadFacultySessions({required AuthProvider authProvider}) async {
    _setLoading(true);
    _clearError();

    try {
      if (authProvider.currentUser is! FacultyModel) {
        throw AuthException('User is not a faculty member.');
      }
      _attendanceHistory = await _attendanceService.getFacultySessions(authProvider.currentUser!.id);
    } on AuthException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError('Failed to load session history.');
    } finally {
      _setLoading(false);
    }
  }

  // Load attendance history (for reports)
  Future<void> loadAttendanceHistory({
    required AuthProvider authProvider,
    String? course,
    int? classNumber,
    String? batch,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final user = authProvider.currentUser;
      if (user is! FacultyModel) {
        throw AuthException('Only faculty members can view reports.');
      }

      _attendanceHistory = await _attendanceService.getAttendanceHistory(
        facultyId: user.id,
        course: course,
        classNumber: classNumber,
        batch: batch,
        startDate: startDate,
        endDate: endDate,
      );
    } on AuthException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError('Failed to load attendance reports.');
    } finally {
      _setLoading(false);
    }
  }

  // Load student attendance history
  Future<void> loadStudentAttendanceHistory({
    required AuthProvider authProvider,
    String? studentId,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final user = authProvider.currentUser;
      if (user == null) throw AuthException('User not authenticated.');

      final targetStudentId = (user is StudentModel) ? user.id : studentId;
      if (targetStudentId == null) {
        throw AuthException('Student ID is required.');
      }

      // TODO: This service method needs to be created/refactored
      // It should return a list of combined session and record data.
      // For now, we assume it returns what we need to build the view model.
      _studentAttendanceHistory = await _attendanceService.getStudentAttendanceHistory(
        studentId: targetStudentId,
      );
    } on AuthException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError('Failed to load student attendance history.');
    } finally {
      _setLoading(false);
    }
  }

  // Load attendance statistics
  Future<void> loadAttendanceStats({
    required AuthProvider authProvider,
    String? studentId,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      final user = authProvider.currentUser;
      if (user == null) throw AuthException('User not authenticated.');

      final targetStudentId = (user is StudentModel) ? user.id : studentId;
      if (targetStudentId == null) {
        throw AuthException('Student ID is required for stats.');
      }

      _attendanceStats = await _attendanceService.getStudentAttendanceStats(targetStudentId);
    } on AuthException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError('Failed to load attendance statistics.');
    } finally {
      _setLoading(false);
    }
  }

  // Edit attendance (Faculty/Admin only)
  Future<bool> editAttendance({
    required String sessionId,
    required String studentId,
    required bool isPresent,
    required AuthProvider authProvider,
    String? reason,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      final user = authProvider.currentUser;
      if (user is! FacultyModel) {
        throw AuthException('Only faculty can edit attendance.');
      }

      await _attendanceService.editAttendance(
        sessionId: sessionId,
        studentId: studentId,
        isPresent: isPresent,
        editorId: user.id,
        reason: reason,
      );

      return true;
    } on AuthException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('Failed to update attendance.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Set filters for reports
  void setFilters({
    String? course,
    int? classNumber,
    String? batch,
    String? student,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    _selectedCourse = course;
    _selectedClass = classNumber;
    _selectedBatch = batch;
    _selectedStudent = student;
    _startDate = startDate;
    _endDate = endDate;
    notifyListeners();
  }

  // Clear filters
  void clearFilters() {
    _selectedCourse = null;
    _selectedClass = null;
    _selectedBatch = null;
    _selectedStudent = null;
    _startDate = null;
    _endDate = null;
    notifyListeners();
  }

  // Get session by code
  Future<AttendanceSession?> getSessionByCode(String code) async {
    try {
      return await _attendanceService.getSessionByCode(code.toUpperCase());
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      return null;
    }
  }

  // Check if student can join session
  Future<Map<String, dynamic>> canJoinSession({
    required String sessionCode,
    required AuthProvider authProvider,
  }) async {
    try {
      final user = authProvider.currentUser;
      if (user == null || user.role != UserRole.student) {
        return {
          'canJoin': false,
          'message': 'Unauthorized: Only students can join sessions'
        };
      }

      final student = user as StudentModel;
      final location = await _locationService.getCurrentLocation();
      
      if (location == null) {
        return {
          'canJoin': false,
          'message': 'Unable to get current location'
        };
      }

      final session = await _attendanceService.getSessionByCode(sessionCode.toUpperCase());
      if (session == null) {
        return {
          'canJoin': false,
          'message': 'Invalid session code'
        };
      }

      if (!session.isActive || session.endTime != null) {
        return {
          'canJoin': false,
          'message': 'Session has ended'
        };
      }

      if (session.isExpired) {
        return {
          'canJoin': false,
          'message': 'Session code has expired'
        };
      }

      // Check if student matches session criteria
      if (session.course != student.course || session.classNumber != student.classNumber) {
        return {
          'canJoin': false,
          'message': 'You are not enrolled in this session\'s course/class'
        };
      }

      if (session.batch != null && session.batch != student.batch) {
        return {
          'canJoin': false,
          'message': 'You are not in the correct batch for this session'
        };
      }

      // Check location
      final distance = _locationService.calculateDistance(
        location.latitude,
        location.longitude,
        session.latitude,
        session.longitude,
      );

      if (distance > session.radiusMeters) {
        return {
          'canJoin': false,
          'message': 'You are too far from the session location (${distance.toInt()}m away)'
        };
      }

      return {
        'canJoin': true,
        'message': 'You can join this session',
        'session': session,
        'distance': distance
      };
    } catch (e) {
      return {
        'canJoin': false,
        'message': e.toString().replaceFirst('Exception: ', '')
      };
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setCreatingSession(bool creating) {
    _isCreatingSession = creating;
    notifyListeners();
  }

  void _setJoiningSession(bool joining) {
    _isJoiningSession = joining;
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

  // Clear all data
  void clear() {
    _currentSession = null;
    _currentSessionAttendance.clear();
    _attendanceHistory.clear();
    _studentAttendanceHistory.clear();
    _attendanceStats = null;
    clearFilters();
    _clearError();
    notifyListeners();
  }

  @override
  void dispose() {
    clear();
    super.dispose();
  }
}