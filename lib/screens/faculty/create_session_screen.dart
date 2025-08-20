import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/location_provider.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glassmorphic_widgets.dart';

class CreateSessionScreen extends StatefulWidget {
  const CreateSessionScreen({super.key});

  @override
  State<CreateSessionScreen> createState() => _CreateSessionScreenState();
}

class _CreateSessionScreenState extends State<CreateSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedCourse;
  String? _selectedClass;
  String? _selectedBatch;
  bool _isCreating = false;

  // Available options
  final List<String> _courses = [
    'BTECH',
    'CIVIL',
    'MECHANICAL',
    'ELECTRICAL',
    'COMPUTER SCIENCE',
    'ELECTRONICS',
    'CHEMICAL',
    'AEROSPACE',
  ];

  final List<String> _classes = [
    '1', '2', '3', '4', '5', '6', '7', '8', '9'
  ];

  final List<String> _batches = [
    'A', 'B', 'C', 'D', 'E'
  ];

  @override
  void initState() {
    super.initState();
    
    // Check location status when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
      locationProvider.checkLocationStatus();
    });
  }

  Future<void> _createSession() async {
    if (!_formKey.currentState!.validate()) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    
    final faculty = authProvider.currentUser as FacultyModel?;
    if (faculty == null) {
      _showErrorDialog('Authentication Error', 'Please log in again.');
      return;
    }
    
    // Check location readiness
    if (!locationProvider.isLocationReady) {
      _showErrorDialog(
        'Location Required', 
        'Please enable location services and ensure GPS is accurate before creating a session.',
      );
      return;
    }
    
    setState(() {
      _isCreating = true;
    });
    
    try {
      // Get current location
      await locationProvider.getCurrentLocation();
      
      if (locationProvider.currentLocation == null) {
        throw Exception('Unable to get current location');
      }
      
      // Create session
      final sessionCode = await attendanceProvider.createSession(
        facultyId: faculty.id,
        facultyName: faculty.name,
        course: _selectedCourse!,
        classNumber: _selectedClass!,
        batch: _selectedBatch,
        location: locationProvider.currentLocation!,
      );
      
      if (mounted) {
        _showSuccessDialog(sessionCode);
        _resetForm();
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Session Creation Failed', e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }
  
  void _resetForm() {
    setState(() {
      _selectedCourse = null;
      _selectedClass = null;
      _selectedBatch = null;
    });
    _formKey.currentState?.reset();
  }
  
  void _showSuccessDialog(String sessionCode) {
    showDialog(
      context: context,
      barrierDismissible: false,
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
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Session Created!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Your attendance session has been created successfully.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Session Code',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sessionCode,
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Share this code with your students to mark attendance.',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader().animate().fadeIn(duration: 600.ms).slideY(
                  begin: -0.3,
                  end: 0,
                  curve: Curves.easeOutBack,
                ),
                
                const SizedBox(height: 24),
                
                // Location Status
                _buildLocationStatus().animate().fadeIn(
                  delay: 200.ms,
                  duration: 600.ms,
                ).slideX(
                  begin: -0.3,
                  end: 0,
                  curve: Curves.easeOutBack,
                ),
                
                const SizedBox(height: 24),
                
                // Session Form
                _buildSessionForm().animate().fadeIn(
                  delay: 400.ms,
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
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Create Session',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Start a new attendance session for your class',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationStatus() {
    return Consumer<LocationProvider>(
      builder: (context, locationProvider, child) {
        return GlassmorphicCard(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: locationProvider.isLocationReady 
                        ? Colors.green.withOpacity(0.2)
                        : Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    locationProvider.isLocationReady 
                        ? Icons.location_on 
                        : Icons.location_off,
                    color: locationProvider.isLocationReady 
                        ? Colors.green 
                        : Colors.orange,
                    size: 20,
                  ),
                ),
                
                const SizedBox(width: 12),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Location Status',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        locationProvider.getLocationStatusMessage(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                
                if (!locationProvider.isLocationReady)
                  TextButton(
                    onPressed: () {
                      locationProvider.checkLocationStatus();
                    },
                    child: Text(
                      'Refresh',
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
      },
    );
  }

  Widget _buildSessionForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Session Details',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Course Selection
          _buildDropdownField(
            label: 'Course',
            value: _selectedCourse,
            items: _courses,
            onChanged: (value) {
              setState(() {
                _selectedCourse = value;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a course';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // Class Selection
          _buildDropdownField(
            label: 'Class',
            value: _selectedClass,
            items: _classes,
            onChanged: (value) {
              setState(() {
                _selectedClass = value;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a class';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // Batch Selection (Optional)
          _buildDropdownField(
            label: 'Batch (Optional)',
            value: _selectedBatch,
            items: _batches,
            onChanged: (value) {
              setState(() {
                _selectedBatch = value;
              });
            },
            isOptional: true,
          ),
          
          const SizedBox(height: 32),
          
          // Create Session Button
          SizedBox(
            width: double.infinity,
            child: Consumer<LocationProvider>(
              builder: (context, locationProvider, child) {
                final isEnabled = locationProvider.isLocationReady && !_isCreating;
                
                return GlassmorphicButton(
                  onPressed: isEnabled ? _createSession : null,
                  child: _isCreating
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Creating Session...',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_circle,
                              color: isEnabled 
                                  ? AppTheme.textPrimary 
                                  : AppTheme.textSecondary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Create Session',
                              style: TextStyle(
                                color: isEnabled 
                                    ? AppTheme.textPrimary 
                                    : AppTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Info Card
          GlassmorphicCard(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Session Information',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _buildInfoItem(
                    icon: Icons.timer_outlined,
                    text: 'Session code expires in 5 minutes',
                  ),
                  
                  _buildInfoItem(
                    icon: Icons.location_on_outlined,
                    text: 'Students must be within 180m radius',
                  ),
                  
                  _buildInfoItem(
                    icon: Icons.security_outlined,
                    text: 'Device integrity checks are enforced',
                  ),
                  
                  _buildInfoItem(
                    icon: Icons.people_outline,
                    text: 'Real-time attendance tracking',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
    bool isOptional = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        GlassmorphicCard(
          child: DropdownButtonFormField<String>(
            value: value,
            onChanged: onChanged,
            validator: validator,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              hintText: 'Select ${label.toLowerCase()}',
              hintStyle: TextStyle(
                color: AppTheme.textSecondary.withOpacity(0.7),
              ),
            ),
            dropdownColor: AppTheme.surfaceColor,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
            ),
            icon: Icon(
              Icons.arrow_drop_down,
              color: AppTheme.textSecondary,
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

  Widget _buildInfoItem({
    required IconData icon,
    required String text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppTheme.textSecondary,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}