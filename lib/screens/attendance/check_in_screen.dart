import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/location_service.dart';
import '../../services/camera_service.dart';
import '../../config/theme.dart';
import '../../config/app_config.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/loading_widget.dart';

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({Key? key}) : super(key: key);

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen>
    with TickerProviderStateMixin {
  final LocationService _locationService = LocationService();
  final CameraService _cameraService = CameraService();

  Position? _currentPosition;
  String? _selfieBase64;
  bool _isLoading = false;
  bool _locationPermissionGranted = false;
  bool _isWithinRange = false;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();
    _checkLocationPermission();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkLocationPermission() async {
    setState(() {
      _isLoading = true;
    });

    final permission = await _locationService.checkLocationPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      final requestResult = await _locationService.requestLocationPermission();
      _locationPermissionGranted = requestResult != LocationPermission.denied &&
          requestResult != LocationPermission.deniedForever;
    } else {
      _locationPermissionGranted = true;
    }

    if (_locationPermissionGranted) {
      await _getCurrentLocation();
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _getCurrentLocation() async {
    final position = await _locationService.getCurrentPosition();
    if (position != null) {
      setState(() {
        _currentPosition = position;
      });
      _checkLocationRange();
    }
  }

  void _checkLocationRange() {
    if (_currentPosition == null) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final employee = authProvider.employee;

    if (employee != null) {
      final isWithin = _locationService.isWithinRadius(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        employee.siteLatitude,
        employee.siteLongitude,
        AppConfig.locationRadius,
      );

      setState(() {
        _isWithinRange = isWithin;
      });
    }
  }

  Future<void> _captureSelfie() async {
    final selfie = await _cameraService.captureSelfie();
    if (selfie != null) {
      setState(() {
        _selfieBase64 = selfie;
      });
    }
  }

  Future<void> _performCheckIn() async {
    if (_currentPosition == null || _selfieBase64 == null) {
      _showErrorDialog('Please ensure location is enabled and selfie is captured');
      return;
    }

    if (!_isWithinRange) {
      _showErrorDialog('You are not within the required range of your assigned site');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
    final employee = authProvider.employee;

    if (employee != null) {
      final success = await attendanceProvider.checkIn(
        siteId: 1, // This should be dynamic based on employee's site
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        selfieBase64: _selfieBase64!,
      );

      if (success) {
        _showSuccessDialog();
      } else {
        _showErrorDialog(attendanceProvider.error ?? 'Check-in failed');
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: const Text('You have successfully checked in!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Check In'),
      body: _isLoading
          ? const LoadingWidget()
          : ScaleTransition(
              scale: _scaleAnimation,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildLocationCard(),
                          const SizedBox(height: 24),
                          _buildSelfieCard(),
                          const SizedBox(height: 24),
                          _buildSiteInfo(),
                        ],
                      ),
                    ),
                    CustomButton(
                      text: 'Check In',
                      onPressed: _canCheckIn() ? _performCheckIn : null,
                      width: double.infinity,
                      backgroundColor: AppTheme.successColor,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLocationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  _locationPermissionGranted && _currentPosition != null
                      ? Icons.location_on
                      : Icons.location_off,
                  color: _locationPermissionGranted && _currentPosition != null
                      ? AppTheme.successColor
                      : Colors.red,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Location Status',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _getLocationStatusText(),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!_locationPermissionGranted)
                  ElevatedButton(
                    onPressed: _checkLocationPermission,
                    child: const Text('Enable'),
                  ),
              ],
            ),
            if (_currentPosition != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isWithinRange
                      ? AppTheme.successColor.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isWithinRange
                        ? AppTheme.successColor
                        : Colors.red,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isWithinRange ? Icons.check_circle : Icons.error,
                      color: _isWithinRange
                          ? AppTheme.successColor
                          : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _isWithinRange
                            ? 'You are within the site range'
                            : 'You are outside the site range',
                        style: TextStyle(
                          color: _isWithinRange
                              ? AppTheme.successColor
                              : Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSelfieCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  _selfieBase64 != null ? Icons.camera_alt : Icons.camera_alt_outlined,
                  color: _selfieBase64 != null ? AppTheme.successColor : Colors.grey,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Selfie Required',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _selfieBase64 != null ? 'Selfie captured' : 'Tap to capture selfie',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: _captureSelfie,
                  child: Text(_selfieBase64 != null ? 'Retake' : 'Capture'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSiteInfo() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final employee = authProvider.employee;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Site Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.business, color: AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    Text(employee?.siteName ?? 'Unknown Site'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(employee?.siteAddress ?? 'Unknown Address'),
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

  String _getLocationStatusText() {
    if (!_locationPermissionGranted) {
      return 'Location permission required';
    }
    if (_currentPosition == null) {
      return 'Getting location...';
    }
    return 'Location acquired';
  }

  bool _canCheckIn() {
    return _locationPermissionGranted &&
        _currentPosition != null &&
        _selfieBase64 != null &&
        _isWithinRange;
  }
}
