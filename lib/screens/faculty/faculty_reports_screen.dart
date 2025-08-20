import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glassmorphic_widgets.dart';

class FacultyReportsScreen extends StatefulWidget {
  const FacultyReportsScreen({super.key});

  @override
  State<FacultyReportsScreen> createState() => _FacultyReportsScreenState();
}

class _FacultyReportsScreenState extends State<FacultyReportsScreen> {
  String? _selectedCourse;
  int? _selectedClass;
  String? _selectedBatch;
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    
    // Set default date range to last 30 days
    _selectedDateRange = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 30)),
      end: DateTime.now(),
    );
    
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReports();
    });
  }

  Future<void> _loadReports() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
    
    try {
      await attendanceProvider.loadAttendanceHistory(
        authProvider: authProvider,
        course: _selectedCourse,
        classNumber: _selectedClass,
        batch: _selectedBatch,
        startDate: _selectedDateRange?.start,
        endDate: _selectedDateRange?.end,
      );
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Error Loading Reports', e.toString());
      }
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppTheme.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _selectedDateRange) {
      setState(() {
        _selectedDateRange = picked;
      });
      _loadReports();
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedCourse = null;
      _selectedClass = null;
      _selectedBatch = null;
      _selectedDateRange = DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 30)),
        end: DateTime.now(),
      );
    });
    _loadReports();
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
              
              // Filters
              _buildFilters().animate().fadeIn(
                delay: 200.ms,
                duration: 600.ms,
              ).slideX(
                begin: -0.3,
                end: 0,
                curve: Curves.easeOutBack,
              ),
              
              // Reports Content
              Expanded(
                child: _buildReportsContent().animate().fadeIn(
                  delay: 400.ms,
                  duration: 600.ms,
                ).slideY(
                  begin: 0.3,
                  end: 0,
                  curve: Curves.easeOutBack,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reports & Analytics',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'View attendance statistics and insights',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          
          // Refresh Button
          Consumer<AttendanceProvider>(
            builder: (context, provider, child) {
              return Container(
                decoration: BoxDecoration(
                  color: AppTheme.glassmorphicFill,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.glassmorphicBorder,
                  ),
                ),
                child: IconButton(
                  onPressed: provider.isLoading ? null : _loadReports,
                  icon: provider.isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.primaryColor,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.refresh,
                          color: AppTheme.textSecondary,
                        ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final authProvider = Provider.of<AuthProvider>(context);
    final faculty = authProvider.currentUser as FacultyModel?;
    final assignedCourses = faculty?.assignedCourses ?? [];
    final assignedClasses = faculty?.assignedClasses.map((c) => c.toString()).toList() ?? [];
    final batches = ['A', 'B', 'C', 'D', 'E']; // Can be hardcoded or moved to config

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassmorphicCard(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.filter_list,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Filters',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _clearFilters,
                    child: Text(
                      'Clear All',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Filter Row 1
              Row(
                children: [
                  Expanded(
                    child: _buildFilterDropdown(
                      label: 'Course',
                      value: _selectedCourse,
                      items: assignedCourses,
                      onChanged: (value) {
                        setState(() {
                          _selectedCourse = value;
                          _selectedClass = null; // Reset dependent filters
                          _selectedBatch = null;
                        });
                        _loadReports();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildFilterDropdown(
                      label: 'Class',
                      value: _selectedClass?.toString(),
                      items: assignedClasses,
                      onChanged: (value) {
                        setState(() {
                          _selectedClass = value != null ? int.tryParse(value) : null;
                          _selectedBatch = null; // Reset dependent filters
                        });
                        _loadReports();
                      },
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Filter Row 2
              Row(
                children: [
                  Expanded(
                    child: _buildFilterDropdown(
                      label: 'Batch',
                      value: _selectedBatch,
                      items: batches,
                      onChanged: (value) {
                        setState(() {
                          _selectedBatch = value;
                        });
                        _loadReports();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDateRangeSelector(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.glassmorphicFill,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.glassmorphicBorder,
            ),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            onChanged: onChanged,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              hintText: 'All ${label.toLowerCase()}',
              hintStyle: TextStyle(
                color: AppTheme.textSecondary.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            dropdownColor: AppTheme.surfaceColor,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
            ),
            icon: Icon(
              Icons.arrow_drop_down,
              color: AppTheme.textSecondary,
              size: 20,
            ),
            items: items.map((item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDateRangeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date Range',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: _selectDateRange,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: AppTheme.glassmorphicFill,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.glassmorphicBorder,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedDateRange != null
                        ? '${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month} - ${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}'
                        : 'Select range',
                    style: TextStyle(
                      color: _selectedDateRange != null
                          ? AppTheme.textPrimary
                          : AppTheme.textSecondary.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ),
                Icon(
                  Icons.calendar_today_outlined,
                  color: AppTheme.textSecondary,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReportsContent() {
    return Consumer<AttendanceProvider>(
      builder: (context, attendanceProvider, child) {
        if (attendanceProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        
        return RefreshIndicator(
          onRefresh: _loadReports,
          color: AppTheme.primaryColor,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Overview Stats
                _buildOverviewStats(attendanceProvider),
                
                const SizedBox(height: 24),
                
                // Session Summary
                _buildSessionSummary(attendanceProvider),
                
                const SizedBox(height: 24),
                
                // Recent Sessions
                _buildRecentSessions(attendanceProvider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOverviewStats(AttendanceProvider attendanceProvider) {
    final sessions = attendanceProvider.attendanceHistory;
    final totalSessions = sessions.length;
    final activeSessions = sessions.where((s) => s.isActive).length;
    final totalAttendance = sessions.fold<int>(0, (sum, session) {
      final presentCount = session.attendanceRecords.values.where((r) => r.isPresent).length;
      return sum + presentCount;
    });
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
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
                icon: Icons.event_note,
                title: 'Total Sessions',
                value: totalSessions.toString(),
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.play_circle,
                title: 'Active Sessions',
                value: activeSessions.toString(),
                color: Colors.green,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.people,
                title: 'Total Attendance',
                value: totalAttendance.toString(),
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.trending_up,
                title: 'Avg. Attendance',
                value: totalSessions > 0 ? '${(totalAttendance / totalSessions).toStringAsFixed(1)}' : '0',
                color: AppTheme.secondaryColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionSummary(AttendanceProvider attendanceProvider) {
    final sessions = attendanceProvider.attendanceHistory;
    
    // Group sessions by course
    final Map<String, List<dynamic>> sessionsByCourse = {};
    for (final session in sessions) {
      if (!sessionsByCourse.containsKey(session.course)) {
        sessionsByCourse[session.course] = [];
      }
      sessionsByCourse[session.course]!.add(session);
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Session Summary by Course',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 16),
        
        if (sessionsByCourse.isEmpty)
          GlassmorphicCard(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.analytics_outlined,
                      size: 48,
                      color: AppTheme.textSecondary.withOpacity(0.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No session data available',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ...sessionsByCourse.entries.map((entry) {
            final course = entry.key;
            final courseSessions = entry.value;
            final totalSessions = courseSessions.length;
            final totalAttendance = courseSessions.fold<int>(0, (sum, session) {
              final presentCount = session.attendanceRecords.values.where((r) => r.isPresent).length;
              return sum + presentCount;
            });
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: GlassmorphicCard(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.school,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              course,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '$totalSessions sessions • $totalAttendance total attendance',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      Text(
                        totalSessions > 0 ? '${(totalAttendance / totalSessions).toStringAsFixed(1)}' : '0',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      const SizedBox(width: 4),
                      
                      Text(
                        'avg',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
      ],
    );
  }

  Widget _buildRecentSessions(AttendanceProvider attendanceProvider) {
    final recentSessions = attendanceProvider.attendanceHistory
        .take(5)
        .toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Sessions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                // TODO: Navigate to all sessions
              },
              child: Text(
                'View All',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        if (recentSessions.isEmpty)
          GlassmorphicCard(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.history_outlined,
                      size: 48,
                      color: AppTheme.textSecondary.withOpacity(0.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No recent sessions',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ...recentSessions.map((session) {
            final presentCount = session.attendanceRecords.values.where((r) => r.isPresent).length;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: GlassmorphicCard(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: session.isActive 
                              ? Colors.green.withOpacity(0.2)
                              : AppTheme.textSecondary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          session.isActive ? Icons.circle : Icons.event_note,
                          color: session.isActive ? Colors.green : AppTheme.textSecondary,
                          size: 12,
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${session.course} - Class ${session.classNumber}',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${session.startTime.day}/${session.startTime.month}/${session.startTime.year} • $presentCount present',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      if (session.isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'LIVE',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
      ],
    );
  }
}