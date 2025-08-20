import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/location_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glassmorphic_widgets.dart';

class JoinSessionScreen extends StatefulWidget {
  const JoinSessionScreen({super.key});

  @override
  State<JoinSessionScreen> createState() => _JoinSessionScreenState();
}

class _JoinSessionScreenState extends State<JoinSessionScreen> {
  final _sessionCodeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
    _sessionCodeController.addListener(() {
      if (attendanceProvider.errorMessage != null) {
        attendanceProvider.clearError();
      }
    });
  }

  @override
  void dispose() {
    _sessionCodeController.dispose();
    super.dispose();
  }

  Future<void> _joinSession() async {
    if (_formKey.currentState?.validate() != true) return;

    final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Check location status first
    if (!locationProvider.isLocationReady) {
      await locationProvider.checkLocationStatus();
      if (!locationProvider.isLocationReady && mounted) {
        _showErrorDialog('Location services are required to join a session. Please enable location and try again.');
        return;
      }
    }

    // Get current location
    await locationProvider.getCurrentLocation();
    if (locationProvider.currentLocation == null && mounted) {
      _showErrorDialog('Unable to get your current location. Please try again.');
      return;
    }

    final success = await attendanceProvider.joinSession(
      sessionCode: _sessionCodeController.text.trim().toUpperCase(),
      authProvider: authProvider,
    );

    if (success && mounted) {
      _showSuccessDialog();
      _sessionCodeController.clear();
    } else if (mounted) {
      _showErrorDialog(attendanceProvider.errorMessage ?? 'Failed to join session. Please try again.');
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Attendance Marked!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your attendance has been successfully recorded for this session.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: AppTheme.errorColor,
            ),
            const SizedBox(width: 8),
            Text(
              'Error',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(
            color: AppTheme.textSecondary,
          ),
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
                
                const SizedBox(height: 32),
                
                // Session Code Input
                _buildSessionCodeInput().animate().fadeIn(
                  delay: 200.ms,
                  duration: 600.ms,
                ).slideX(
                  begin: -0.3,
                  end: 0,
                  curve: Curves.easeOutBack,
                ),
                
                const SizedBox(height: 24),
                
                // Join Button
                _buildJoinButton().animate().fadeIn(
                  delay: 400.ms,
                  duration: 600.ms,
                ).slideY(
                  begin: 0.3,
                  end: 0,
                  curve: Curves.easeOutBack,
                ),
                
                const SizedBox(height: 32),
                
                // Location Status
                _buildLocationStatus().animate().fadeIn(
                  delay: 600.ms,
                  duration: 600.ms,
                ),
                
                const SizedBox(height: 24),
                
                // Instructions
                _buildInstructions().animate().fadeIn(
                  delay: 800.ms,
                  duration: 600.ms,
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
          'Join Session',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter the session code provided by your faculty to mark your attendance.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSessionCodeInput() {
    return Form(
      key: _formKey,
      child: GlassmorphicCard(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.qr_code_scanner,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Session Code',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _sessionCodeController,
                decoration: InputDecoration(
                  hintText: 'Enter 3-digit session code',
                  prefixIcon: Icon(
                    Icons.pin_outlined,
                    color: AppTheme.primaryColor,
                  ),
                  filled: true,
                  fillColor: AppTheme.glassmorphicFill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppTheme.glassmorphicBorder,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppTheme.glassmorphicBorder,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppTheme.primaryColor,
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppTheme.errorColor,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppTheme.errorColor,
                      width: 2,
                    ),
                  ),
                ),
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
                textCapitalization: TextCapitalization.characters,
                maxLength: 3,
                buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                  UpperCaseTextFormatter(),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter session code';
                  }
                  if (value.length != 3) {
                    return 'Session code must be 3 characters';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _joinSession(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJoinButton() {
    return Consumer<AttendanceProvider>(
      builder: (context, attendanceProvider, child) {
        return SizedBox(
          width: double.infinity,
          child: GlassmorphicButton(
            onPressed: attendanceProvider.isJoiningSession ? null : _joinSession,
            child: attendanceProvider.isJoiningSession
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.login, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        'Join Session',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildLocationStatus() {
    return Consumer<LocationProvider>(
      builder: (context, locationProvider, child) {
        return GlassmorphicCard(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Location Status',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: locationProvider.isLocationReady 
                            ? Colors.green.withOpacity(0.2)
                            : Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        locationProvider.isLocationReady 
                            ? Icons.check_circle 
                            : Icons.warning,
                        color: locationProvider.isLocationReady 
                            ? Colors.green 
                            : Colors.orange,
                        size: 16,
                      ),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    Expanded(
                      child: Text(
                        locationProvider.getLocationStatusMessage(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    
                    if (!locationProvider.isLocationReady)
                      TextButton(
                        onPressed: () {
                          locationProvider.checkLocationStatus();
                        },
                        child: Text(
                          'Fix',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInstructions() {
    return GlassmorphicCard(
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
                  'Instructions',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            ..._buildInstructionItems(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildInstructionItems() {
    final instructions = [
      'Get the 3-digit session code from your faculty',
      'Make sure you are within 180m of the session location',
      'Ensure location services are enabled on your device',
      'Session codes expire after 5 minutes',
      'You can only mark attendance once per session',
    ];

    return instructions.asMap().entries.map((entry) {
      final index = entry.key;
      final instruction = entry.value;
      
      return Padding(
        padding: EdgeInsets.only(bottom: index < instructions.length - 1 ? 8 : 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 2),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                instruction,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}