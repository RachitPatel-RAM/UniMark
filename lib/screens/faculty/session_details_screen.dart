import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/attendance_model.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glassmorphic_widgets.dart';

class SessionDetailsScreen extends StatefulWidget {
  final AttendanceSession session;
  
  const SessionDetailsScreen({
    super.key,
    required this.session,
  });

  @override
  State<SessionDetailsScreen> createState() => _SessionDetailsScreenState();
}

class _SessionDetailsScreenState extends State<SessionDetailsScreen> {
  bool _isLoading = false;
  List<AttendanceRecord> _attendanceRecords = [];
  String _filterStatus = 'All';
  
  @override
  void initState() {
    super.initState();
    _loadAttendanceRecords();
  }

  Future<void> _loadAttendanceRecords() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
      await attendanceProvider.getSessionAttendance(widget.session.id);
      
      if (mounted) {
        setState(() {
          _attendanceRecords = attendanceProvider.sessionAttendance;
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Error', 'Failed to load attendance records: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _endSession() async {
    final confirmed = await _showConfirmDialog(
      'End Session',
      'Are you sure you want to end this session? This action cannot be undone.',
    );
    
    if (!confirmed) return;
    
    try {
      final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
      await attendanceProvider.endSession(widget.session.id);
      
      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate session was ended
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Session ended successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Error', 'Failed to end session: $e');
      }
    }
  }

  Future<void> _editAttendance(AttendanceRecord record) async {
    final newStatus = await _showEditAttendanceDialog(record);
    if (newStatus == null || newStatus == record.status) return;
    
    try {
      final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
      await attendanceProvider.editAttendance(
        widget.session.id,
        record.studentId,
        newStatus,
      );
      
      if (mounted) {
        await _loadAttendanceRecords(); // Refresh the list
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Attendance updated for ${record.studentName}'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Error', 'Failed to update attendance: $e');
      }
    }
  }

  Future<String?> _showEditAttendanceDialog(AttendanceRecord record) async {
    String selectedStatus = record.status;
    
    return await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppTheme.surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text('Edit Attendance'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Student: ${record.studentName}',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Attendance Status:',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...['Present', 'Absent'].map((status) {
                return RadioListTile<String>(
                  title: Text(
                    status,
                    style: TextStyle(color: AppTheme.textPrimary),
                  ),
                  value: status,
                  groupValue: selectedStatus,
                  onChanged: (value) {
                    setState(() {
                      selectedStatus = value!;
                    });
                  },
                  activeColor: AppTheme.primaryColor,
                );
              }).toList(),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(selectedStatus),
              child: Text(
                'Update',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _showConfirmDialog(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(title),
        content: Text(
          message,
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Confirm',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.error,
                color: Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(title),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<AttendanceRecord> get _filteredRecords {
    if (_filterStatus == 'All') {
      return _attendanceRecords;
    }
    return _attendanceRecords.where((record) => record.status == _filterStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader().animate().fadeIn(duration: 600.ms).slideY(
                begin: -0.3,
                end: 0,
                curve: Curves.easeOutBack,
              ),
              
              // Content
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Session Info Card
                            _buildSessionInfoCard().animate().fadeIn(
                              delay: 200.ms,
                              duration: 600.ms,
                            ).slideX(
                              begin: -0.3,
                              end: 0,
                              curve: Curves.easeOutBack,
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Statistics Card
                            _buildStatisticsCard().animate().fadeIn(
                              delay: 400.ms,
                              duration: 600.ms,
                            ).slideX(
                              begin: 0.3,
                              end: 0,
                              curve: Curves.easeOutBack,
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Filter and Attendance List
                            _buildAttendanceSection().animate().fadeIn(
                              delay: 600.ms,
                              duration: 600.ms,
                            ).slideY(
                              begin: 0.3,
                              end: 0,
                              curve: Curves.easeOutBack,
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppTheme.glassmorphicFill,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.glassmorphicBorder,
              ),
            ),
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(
                Icons.arrow_back_ios_new,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Session Details',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${widget.session.course} - Class ${widget.session.className}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          
          if (widget.session.isActive)
            Container(
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.red.withOpacity(0.5),
                ),
              ),
              child: IconButton(
                onPressed: _endSession,
                icon: const Icon(
                  Icons.stop,
                  color: Colors.red,
                ),
                tooltip: 'End Session',
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading session details...',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionInfoCard() {
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.school,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Session Information',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.session.isActive ? 'Active Session' : 'Completed Session',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: widget.session.isActive ? Colors.green : AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: widget.session.isActive 
                        ? Colors.green.withOpacity(0.2)
                        : AppTheme.textSecondary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.session.isActive 
                          ? Colors.green.withOpacity(0.5)
                          : AppTheme.textSecondary.withOpacity(0.5),
                    ),
                  ),
                  child: Text(
                    widget.session.isActive ? 'ACTIVE' : 'ENDED',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: widget.session.isActive ? Colors.green : AppTheme.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Session Details
            _buildInfoRow('Course', widget.session.course),
            _buildInfoRow('Class', widget.session.className),
            if (widget.session.batch != null)
              _buildInfoRow('Batch', widget.session.batch!),
            _buildInfoRow('Session Code', widget.session.sessionCode),
            _buildInfoRow(
              'Created At', 
              DateFormat('MMM dd, yyyy - hh:mm a').format(widget.session.createdAt),
            ),
            if (widget.session.endTime != null)
              _buildInfoRow(
                'Ended At', 
                DateFormat('MMM dd, yyyy - hh:mm a').format(widget.session.endTime!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard() {
    final presentCount = _attendanceRecords.where((r) => r.status == 'Present').length;
    final absentCount = _attendanceRecords.where((r) => r.status == 'Absent').length;
    final totalCount = _attendanceRecords.length;
    final percentage = totalCount > 0 ? (presentCount / totalCount * 100) : 0.0;
    
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attendance Statistics',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Students',
                    totalCount.toString(),
                    Icons.people,
                    AppTheme.primaryColor,
                  ),
                ),
                
                const SizedBox(width: 12),
                
                Expanded(
                  child: _buildStatCard(
                    'Present',
                    presentCount.toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                
                const SizedBox(width: 12),
                
                Expanded(
                  child: _buildStatCard(
                    'Absent',
                    absentCount.toString(),
                    Icons.cancel,
                    Colors.red,
                  ),
                ),
                
                const SizedBox(width: 12),
                
                Expanded(
                  child: _buildStatCard(
                    'Percentage',
                    '${percentage.toStringAsFixed(1)}%',
                    Icons.percent,
                    AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Attendance Records',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const Spacer(),
            
            // Filter Dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppTheme.glassmorphicFill,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.glassmorphicBorder,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _filterStatus,
                  items: ['All', 'Present', 'Absent'].map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(
                        status,
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _filterStatus = value!;
                    });
                  },
                  dropdownColor: AppTheme.surfaceColor,
                  icon: Icon(
                    Icons.filter_list,
                    color: AppTheme.textSecondary,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        if (_filteredRecords.isEmpty) ..[
          GlassmorphicCard(
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: AppTheme.textSecondary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No attendance records found',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _filterStatus == 'All' 
                        ? 'No students have joined this session yet'
                        : 'No students with $_filterStatus status',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ] else ..[
          ..._filteredRecords.asMap().entries.map((entry) {
            final index = entry.key;
            final record = entry.value;
            
            return _buildAttendanceCard(record).animate(
              delay: Duration(milliseconds: 100 * index),
            ).fadeIn(
              duration: 400.ms,
            ).slideX(
              begin: 0.3,
              end: 0,
              curve: Curves.easeOutBack,
            );
          }).toList(),
        ],
      ],
    );
  }

  Widget _buildAttendanceCard(AttendanceRecord record) {
    final canEdit = widget.session.isActive || 
        (widget.session.endTime != null && 
         DateTime.now().difference(widget.session.endTime!).inHours < 48);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassmorphicCard(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Student Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryColor.withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    record.studentName.isNotEmpty 
                        ? record.studentName[0].toUpperCase() 
                        : 'S',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Student Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.studentName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Marked at: ${DateFormat('hh:mm a').format(record.markedAt)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: record.status == 'Present' 
                      ? Colors.green.withOpacity(0.2)
                      : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: record.status == 'Present' 
                        ? Colors.green.withOpacity(0.5)
                        : Colors.red.withOpacity(0.5),
                  ),
                ),
                child: Text(
                  record.status.toUpperCase(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: record.status == 'Present' ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              // Edit Button
              if (canEdit) ..[
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.glassmorphicFill,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.glassmorphicBorder,
                    ),
                  ),
                  child: IconButton(
                    onPressed: () => _editAttendance(record),
                    icon: Icon(
                      Icons.edit,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}