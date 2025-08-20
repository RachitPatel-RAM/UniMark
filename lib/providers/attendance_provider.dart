import 'package:flutter/material.dart';
import '../models/attendance_model.dart';
import '../models/user_model.dart';
import '../services/attendance_service.dart';
import '../services/location_service.dart';
import 'auth_provider.dart';

class AttendanceProvider extends ChangeNotifier {
  final AttendanceService _attendanceService = AttendanceService();
  final LocationService _locationService = LocationService();
  
  // Current session state
  AttendanceSession? _currentSession;
  List<AttendanceRecord> _currentSessionAttendance = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  // Session management
  bool _isCreatingSession = false;
  bool _isJoiningSession = false;
  
  // Attendance history
  List<AttendanceSession> _attendanceHistory = [];
  List<AttendanceRecord> _studentAttendanceHistory = [];
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
  List<AttendanceRecord> get currentSessionAttendance => _currentSessionAttendance;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isCreatingSession => _isCreatingSession;
  bool get isJoiningSession => _isJoiningSession;
  bool get hasActiveSession => _currentSession != null && !_currentSession!.isEnded;
  
  List<AttendanceSession> get attendanceHistory => _attendanceHistory;
  List<AttendanceRecord> get studentAttendanceHistory => _studentAttendanceHistory;
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
    try {
      _setCreatingSession(true);
      _clearError();

      final user = authProvider.currentUser;
      if (user == null || user.role == UserRole.student) {
        throw Exception('Unauthorized: Only faculty can create sessions');
      }

      // Get current location
      final location = await _locationService.getCurrentLocation();
      if (location == null) {
        throw Exception('Unable to get current location. Please enable GPS and try again.');
      }

      // Check location accuracy
      if (!await _locationService.isLocationAccurate()) {
        throw Exception('Location accuracy is too low. Please move to an open area and try again.');
      }

      // Create session
      _currentSession = await _attendanceService.createSession(
        course: course.toUpperCase(),
        classNumber: classNumber,
        batch: batch,
        facultyId: user.id,
        facultyName: user.name,
        latitude: location.latitude,
        longitude: location.longitude,
      );

      _currentSessionAttendance.clear();
      
      // Start listening to session updates
      _listenToSessionUpdates();
      
      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
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
    try {
      _setJoiningSession(true);
      _clearError();

      final user = authProvider.currentUser;
      if (user == null || user.role != UserRole.student) {
        throw Exception('Unauthorized: Only students can join sessions');
      }

      final student = user as StudentModel;

      // Get current location
      final location = await _locationService.getCurrentLocation();
      if (location == null) {
        throw Exception('Unable to get current location. Please enable GPS and try again.');
      }

      // Check location accuracy
      if (!await _locationService.isLocationAccurate()) {
        throw Exception('Location accuracy is too low. Please move to an open area and try again.');
      }

      // Join session
      final result = await _attendanceService.joinSession(
        sessionCode: sessionCode.toUpperCase(),
        studentId: student.id,
        studentName: student.name,
        enrollmentNumber: student.enrollmentNumber,
        course: student.course,
        classNumber: student.classNumber,
        batch: student.batch,
        latitude: location.latitude,
        longitude: location.longitude,
      );

      if (result['success'] == true) {
        _currentSession = result['session'];
        return true;
      } else {
        throw Exception(result['message'] ?? 'Failed to join session');
      }
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    } finally {
      _setJoiningSession(false);
    }
  }

  // End current session (Faculty only)
  Future<bool> endSession(AuthProvider authProvider) async {
    try {
      _setLoading(true);
      _clearError();

      final user = authProvider.currentUser;
      if (user == null || user.role == UserRole.student) {
        throw Exception('Unauthorized: Only faculty can end sessions');
      }

      if (_currentSession == null) {
        throw Exception('No active session to end');
      }

      await _attendanceService.endSession(_currentSession!.id);
      
      _currentSession = null;
      _currentSessionAttendance.clear();
      
      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Listen to session updates
  void _listenToSessionUpdates() {
    if (_currentSession == null) return;

    _attendanceService.getSessionAttendanceStream(_currentSession!.id).listen(
      (attendanceList) {
        _currentSessionAttendance = attendanceList;
        notifyListeners();
      },
      onError: (error) {
        _setError('Failed to load session updates: $error');
      },
    );
  }

  // Load attendance history (Faculty/Admin)
  Future<void> loadAttendanceHistory({
    required AuthProvider authProvider,
    String? course,
    int? classNumber,
    String? batch,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final user = authProvider.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      if (user.role == UserRole.student) {
        throw Exception('Unauthorized: Students cannot access attendance history');
      }

      _attendanceHistory = await _attendanceService.getAttendanceHistory(
        course: course,
        classNumber: classNumber,
        batch: batch,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      _setLoading(false);
    }
  }

  // Load student attendance history
  Future<void> loadStudentAttendanceHistory({
    required AuthProvider authProvider,
    String? studentId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final user = authProvider.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      String targetStudentId;
      if (user.role == UserRole.student) {
        // Students can only view their own history
        targetStudentId = user.id;
      } else {
        // Faculty/Admin can view any student's history
        if (studentId == null) {
          throw Exception('Student ID is required');
        }
        targetStudentId = studentId;
      }

      _studentAttendanceHistory = await _attendanceService.getStudentAttendanceHistory(
        studentId: targetStudentId,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      _setLoading(false);
    }
  }

  // Load attendance statistics
  Future<void> loadAttendanceStats({
    required AuthProvider authProvider,
    String? studentId,
    String? course,
    int? classNumber,
    String? batch,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final user = authProvider.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      String targetStudentId;
      if (user.role == UserRole.student) {
        // Students can only view their own stats
        targetStudentId = user.id;
        final student = user as StudentModel;
        course = student.course;
        classNumber = student.classNumber;
        batch = student.batch;
      } else {
        // Faculty/Admin can view any student's stats
        if (studentId == null) {
          throw Exception('Student ID is required');
        }
        targetStudentId = studentId;
      }

      _attendanceStats = await _attendanceService.getStudentAttendanceStats(targetStudentId);
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
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
    try {
      _setLoading(true);
      _clearError();

      final user = authProvider.currentUser;
      if (user == null || user.role == UserRole.student) {
        throw Exception('Unauthorized: Only faculty and admin can edit attendance');
      }

      await _attendanceService.editAttendance(
        sessionId,
        studentId,
        isPresent,
        reason,
      );

      // Refresh current session attendance if editing current session
      if (_currentSession?.id == sessionId) {
        _listenToSessionUpdates();
      }

      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
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