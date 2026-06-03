import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../services/hotel_service.dart';
import '../../../../../../../core/constants/app_colors.dart';

class HotelPendingApprovalScreen extends StatefulWidget {
  const HotelPendingApprovalScreen({super.key});

  @override
  State<HotelPendingApprovalScreen> createState() =>
      _HotelPendingApprovalScreenState();
}

class _HotelPendingApprovalScreenState
    extends State<HotelPendingApprovalScreen> {
  bool _isCheckingStatus = false;
  String _hotelStatus = 'PENDING';
  String _hotelName = '';
  int _checkCount = 0;
  bool _isValidating = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _validateAndCheckStatus();
  }

  /// Validate user authentication and hotel status before showing the pending screen
  Future<void> _validateAndCheckStatus() async {
    setState(() {
      _isValidating = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Check if user is authenticated
      if (authProvider.token == null || authProvider.token!.isEmpty) {
        if (mounted) {
          _redirectToLogin();
        }
        return;
      }

      // Check if user exists
      if (authProvider.user == null) {
        if (mounted) {
          _redirectToLogin();
        }
        return;
      }

      // Set token for hotel service
      HotelService.setToken(authProvider.token ?? '');
      final hotelService = HotelService();

      // Get hotel status from backend
      final response = await hotelService.getHotelStatus();

      if (!mounted) return;

      // Check if response is valid and has hotel data
      if (response['success'] == true &&
          response['data'] != null &&
          response['data'] is Map &&
          (response['data'] as Map).isNotEmpty &&
          (response['data'] as Map).containsKey('status')) {
        final status = response['data']['status'] as String?;

        // If status is empty or invalid, redirect to registration
        if (status == null || status.isEmpty) {
          _redirectToRegistration();
          return;
        }

        // If hotel is not in PENDING status, redirect to appropriate screen
        if (status == 'APPROVED' || status == 'ACTIVE') {
          // Hotel is already approved, go to dashboard
          _redirectToDashboard();
          return;
        } else if (status == 'REJECTED') {
          // Hotel was rejected, go to registration
          _redirectToRegistration();
          return;
        }

        // Hotel is PENDING - show the pending screen
        setState(() {
          _hotelStatus = status;
          _hotelName = response['data']['name'] != null
              ? response['data']['name'].toString()
              : 'Your Hotel';
          _isValidating = false;
        });

        // Start periodic status checking
        _startStatusChecking();
      } else {
        // No hotel found or error - redirect to registration
        debugPrint(
            'No hotel found in pending screen validation, redirecting to registration');
        _redirectToRegistration();
      }
    } catch (e) {
      debugPrint('Error validating hotel status: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to validate hotel status. Please try again.';
          _isValidating = false;
        });
      }
    }
  }

  void _redirectToLogin() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to continue'),
          backgroundColor: AppColors.warning,
        ),
      );
      context.go('/login');
    }
  }

  void _redirectToDashboard() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your hotel is already approved!'),
          backgroundColor: AppColors.success,
        ),
      );
      context.go('/dashboard');
    }
  }

  void _redirectToRegistration() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No pending hotel registration found'),
          backgroundColor: AppColors.warning,
        ),
      );
      context.go('/hotel-registration');
    }
  }

  void _startStatusChecking() {
    // Check status every 10 seconds
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        _checkHotelStatus();
      }
    });
  }

  Future<void> _checkHotelStatus() async {
    if (_isCheckingStatus) return;

    setState(() {
      _isCheckingStatus = true;
      _checkCount++;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      HotelService.setToken(authProvider.token ?? '');
      final hotelService = HotelService();

      // Get hotel status
      final response = await hotelService.getHotelStatus();

      if (mounted && response['success'] == true) {
        final status = response['data']['status'] ?? 'PENDING';
        final name = response['data']['name'] ?? 'Your Hotel';

        setState(() {
          _hotelStatus = status;
          _hotelName = name;
        });

        // If approved, navigate to dashboard
        if (status == 'APPROVED' || status == 'ACTIVE') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:
                    Text('🎉 Congratulations! Your hotel has been approved!'),
                backgroundColor: AppColors.success,
                duration: Duration(seconds: 3),
              ),
            );

            // Update user hasHotel status
            await authProvider.updateHotelStatus(true);

            // Navigate to dashboard
            context.go('/dashboard');
            return;
          }
        } else if (status == 'REJECTED') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Your hotel registration was rejected. Please contact support.'),
                backgroundColor: AppColors.error,
                duration: Duration(seconds: 5),
              ),
            );

            // Navigate back to registration
            context.go('/hotel-registration/step-1');
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking hotel status: $e');
    } finally {
      setState(() {
        _isCheckingStatus = false;
      });
    }

    // Continue checking if still pending
    if (_hotelStatus == 'PENDING' && mounted) {
      _startStatusChecking();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while validating
    if (_isValidating) {
      return Scaffold(
        backgroundColor: AppColors.error.shade50,
        appBar: AppBar(
          title: const Text('Hotel Registration'),
          backgroundColor: AppColors.error.shade600,
          foregroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: AppColors.error,
              ),
              SizedBox(height: 16),
              Text(
                'Validating your session...',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.gray,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show error message if validation failed
    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: AppColors.error.shade50,
        appBar: AppBar(
          title: const Text('Hotel Registration'),
          backgroundColor: AppColors.error.shade600,
          foregroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppColors.error.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.gray,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _validateAndCheckStatus,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error.shade600,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.error.shade50,
      appBar: AppBar(
        title: const Text('Hotel Registration'),
        backgroundColor: AppColors.error.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom -
                  kToolbarHeight -
                  48,
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  // Success Icon
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.error.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle_outline,
                      size: 60,
                      color: AppColors.error.shade600,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Success Message
                  const Text(
                    'Registration Submitted!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkGray,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'Your hotel "$_hotelName" has been successfully submitted for review.',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.gray.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Status Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.hourglass_empty,
                              color: AppColors.warning.shade600,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Status: $_hotelStatus',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: _getStatusColor(),
                                    ),
                                  ),
                                  Text(
                                    'Waiting for admin approval',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.gray.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),

                        // What happens next
                        const Text(
                          'What happens next?',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkGray,
                          ),
                        ),
                        const SizedBox(height: 12),

                        _buildNextStepItem(
                          icon: Icons.admin_panel_settings,
                          title: 'Admin Review',
                          description:
                              'Our team will review your hotel details',
                          isCompleted: true,
                        ),
                        const SizedBox(height: 8),
                        _buildNextStepItem(
                          icon: Icons.verified,
                          title: 'Approval Process',
                          description: 'Typically takes 1-2 business days',
                          isCompleted: false,
                        ),
                        const SizedBox(height: 8),
                        _buildNextStepItem(
                          icon: Icons.dashboard,
                          title: 'Dashboard Access',
                          description: 'You\'ll get full access once approved',
                          isCompleted: false,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Auto-refresh indicator
                  if (_isCheckingStatus)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.info.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.info.shade600,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Checking status...',
                            style: TextStyle(
                              color: AppColors.info.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Column(
      children: [
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isCheckingStatus ? null : _checkHotelStatus,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.info.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.refresh),
                const SizedBox(width: 8),
                Text(
                  _isCheckingStatus ? 'Checking...' : 'Check Status Now',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () {
              _showContactDialog();
            },
            child: Text(
              'Need Help? Contact Support',
              style: TextStyle(
                color: AppColors.error.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor() {
    switch (_hotelStatus) {
      case 'PENDING':
        return AppColors.warning.shade600;
      case 'APPROVED':
        return AppColors.success.shade600;
      case 'REJECTED':
        return AppColors.error.shade600;
      default:
        return AppColors.gray.shade600;
    }
  }

  Widget _buildNextStepItem({
    required IconData icon,
    required String title,
    required String description,
    required bool isCompleted,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isCompleted ? AppColors.success.shade100 : AppColors.gray.shade200,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 16,
            color: isCompleted ? AppColors.success.shade600 : AppColors.gray.shade600,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isCompleted
                      ? AppColors.success.shade700
                      : AppColors.gray.shade700,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.gray.shade600,
                ),
              ),
            ],
          ),
        ),
        if (isCompleted)
          Icon(
            Icons.check_circle,
            color: AppColors.success.shade600,
            size: 20,
          ),
      ],
    );
  }

  void _showContactDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Support'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'If you have any questions about your hotel registration, please contact us:'),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.email, color: AppColors.info),
                SizedBox(width: 8),
                Text('support@hotelsewa.com'),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.phone, color: AppColors.info),
                SizedBox(width: 8),
                Text('+977-1-xxxxxxx'),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.schedule, color: AppColors.info),
                SizedBox(width: 8),
                Text('Mon-Fri, 9AM-6PM'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
