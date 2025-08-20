import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glassmorphic_widgets.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _enrollmentController;
  late TextEditingController _courseController;
  late TextEditingController _classController;
  late TextEditingController _batchController;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser as StudentModel?;
    
    _nameController = TextEditingController(text: user?.name ?? '');
    _enrollmentController = TextEditingController(text: user?.enrollmentNumber ?? '');
    _courseController = TextEditingController(text: user?.course ?? '');
    _classController = TextEditingController(text: user?.classNumber.toString() ?? '');
    _batchController = TextEditingController(text: user?.batch ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _enrollmentController.dispose();
    _courseController.dispose();
    _classController.dispose();
    _batchController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState?.validate() != true) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser as StudentModel;

    final updates = {
      'name': _nameController.text.trim(),
      'course': _courseController.text.trim().toUpperCase(),
      'classNumber': int.tryParse(_classController.text.trim()) ?? currentUser.classNumber,
      'batch': _batchController.text.trim().isEmpty ? null : _batchController.text.trim(),
    };

    final success = await authProvider.updateProfile(updates);

    if (success) {
      if (mounted) {
        setState(() {
          _isEditing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } else {
      if (mounted) {
        _showErrorDialog(authProvider.errorMessage ?? 'Failed to update profile');
      }
    }
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
    });
    _initializeControllers();
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

  void _showLogoutDialog() {
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
              Icons.logout,
              color: AppTheme.errorColor,
            ),
            const SizedBox(width: 8),
            Text(
              'Logout',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: TextStyle(
            color: AppTheme.textSecondary,
          ),
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
            onPressed: () async {
              Navigator.of(context).pop();
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.logout();
              
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: Text(
              'Logout',
              style: TextStyle(
                color: AppTheme.errorColor,
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
                
                // Profile Card
                _buildProfileCard().animate().fadeIn(
                  delay: 200.ms,
                  duration: 600.ms,
                ).slideX(
                  begin: -0.3,
                  end: 0,
                  curve: Curves.easeOutBack,
                ),
                
                const SizedBox(height: 24),
                
                // Profile Information
                _buildProfileInfo().animate().fadeIn(
                  delay: 400.ms,
                  duration: 600.ms,
                ).slideX(
                  begin: 0.3,
                  end: 0,
                  curve: Curves.easeOutBack,
                ),
                
                const SizedBox(height: 24),
                
                // Settings
                _buildSettings().animate().fadeIn(
                  delay: 600.ms,
                  duration: 600.ms,
                ).slideY(
                  begin: 0.3,
                  end: 0,
                  curve: Curves.easeOutBack,
                ),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profile',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Manage your account information',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        
        if (!_isEditing)
          Container(
            decoration: BoxDecoration(
              color: AppTheme.glassmorphicFill,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.glassmorphicBorder,
              ),
            ),
            child: IconButton(
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
              icon: Icon(
                Icons.edit_outlined,
                color: AppTheme.primaryColor,
              ),
              tooltip: 'Edit Profile',
            ),
          ),
      ],
    );
  }

  Widget _buildProfileCard() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser as StudentModel?;
        
        return GlassmorphicCard(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.secondaryColor,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      user?.name.isNotEmpty == true 
                          ? user!.name[0].toUpperCase()
                          : 'S',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'Student',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.enrollmentNumber ?? '',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${user?.course ?? ''} • Class ${user?.classNumber ?? ''}${user?.batch != null ? ' • ${user!.batch}' : ''}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileInfo() {
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Personal Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            if (_isEditing) ..[
              _buildEditForm(),
            ] else ..[
              _buildInfoDisplay(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Name Field
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Full Name',
              prefixIcon: Icon(
                Icons.person_outline,
                color: AppTheme.primaryColor,
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your name';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // Enrollment Number (Read-only)
          TextFormField(
            controller: _enrollmentController,
            decoration: InputDecoration(
              labelText: 'Enrollment Number',
              prefixIcon: Icon(
                Icons.badge_outlined,
                color: AppTheme.textSecondary,
              ),
              suffixIcon: Icon(
                Icons.lock_outline,
                color: AppTheme.textSecondary,
                size: 20,
              ),
            ),
            enabled: false,
          ),
          
          const SizedBox(height: 16),
          
          // Course Field
          TextFormField(
            controller: _courseController,
            decoration: InputDecoration(
              labelText: 'Course',
              prefixIcon: Icon(
                Icons.school_outlined,
                color: AppTheme.primaryColor,
              ),
            ),
            textCapitalization: TextCapitalization.characters,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your course';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              // Class Field
              Expanded(
                child: TextFormField(
                  controller: _classController,
                  decoration: InputDecoration(
                    labelText: 'Class',
                    prefixIcon: Icon(
                      Icons.class_outlined,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter class';
                    }
                    final classNum = int.tryParse(value.trim());
                    if (classNum == null || classNum < 1 || classNum > 9) {
                      return 'Class must be 1-9';
                    }
                    return null;
                  },
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Batch Field
              Expanded(
                child: TextFormField(
                  controller: _batchController,
                  decoration: InputDecoration(
                    labelText: 'Batch (Optional)',
                    prefixIcon: Icon(
                      Icons.group_outlined,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _cancelEdit,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textSecondary,
                    side: BorderSide(color: AppTheme.glassmorphicBorder),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoDisplay() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser as StudentModel?;
        
        return Column(
          children: [
            _InfoRow(
              icon: Icons.person_outline,
              label: 'Full Name',
              value: user?.name ?? 'N/A',
            ),
            
            const SizedBox(height: 16),
            
            _InfoRow(
              icon: Icons.badge_outlined,
              label: 'Enrollment Number',
              value: user?.enrollmentNumber ?? 'N/A',
            ),
            
            const SizedBox(height: 16),
            
            _InfoRow(
              icon: Icons.school_outlined,
              label: 'Course',
              value: user?.course ?? 'N/A',
            ),
            
            const SizedBox(height: 16),
            
            _InfoRow(
              icon: Icons.class_outlined,
              label: 'Class',
              value: user?.classNumber.toString() ?? 'N/A',
            ),
            
            if (user?.batch != null) ..[
              const SizedBox(height: 16),
              _InfoRow(
                icon: Icons.group_outlined,
                label: 'Batch',
                value: user!.batch!,
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildSettings() {
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.settings_outlined,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Settings',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Logout Button
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.logout,
                  color: AppTheme.errorColor,
                  size: 20,
                ),
              ),
              title: Text(
                'Logout',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Sign out of your account',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                color: AppTheme.textSecondary,
                size: 16,
              ),
              onTap: _showLogoutDialog,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppTheme.textSecondary,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}