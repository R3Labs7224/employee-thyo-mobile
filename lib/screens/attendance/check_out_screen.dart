// lib/screens/attendance/check_out_screen.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/location_service.dart';
import '../../services/camera_service.dart';
import '../../config/theme.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/loading_widget.dart';

class CheckOutScreen extends StatefulWidget {
  const CheckOutScreen({super.key});

  @override
  State<CheckOutScreen> createState() => _CheckOutScreenState();
}

class _CheckOutScreenState extends State<CheckOutScreen> {
  final LocationService _locationService = LocationService();
  final CameraService _cameraService = CameraService();
  
  Position? _currentPosition;
  File? _selfieImage;
  String? _selfieBase64;
  bool _isLoading = false;
  String? _error;
  
  // Today's attendance info
  int? _todaySiteId;
  String? _todaySiteName;
  String? _checkInTime;

  @override
  void initState() {
    super.initState();
    _initializeCheckOut();
  }

  Future<void> _initializeCheckOut() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get today's attendance info
      final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
      final todayAttendance = attendanceProvider.todayAttendance;
      
      if (todayAttendance == null || todayAttendance.checkInTime == null) {
        setState(() {
          _error = 'No check-in found for today. Please check in first.';
          _isLoading = false;
        });
        return;
      }

      if (todayAttendance.checkOutTime != null) {
        setState(() {
          _error = 'You have already checked out today.';
          _isLoading = false;
        });
        return;
      }

      // Set today's attendance info
      _todaySiteId = todayAttendance.siteId;
      _todaySiteName = todayAttendance.siteName;
      _checkInTime = todayAttendance.checkInTime;

      // Check location permission
      final hasPermission = await _locationService.checkPermission();
      if (!hasPermission) {
        final granted = await _locationService.requestPermission();
        if (!granted) {
          setState(() {
            _error = 'Location permission is required for check-out';
            _isLoading = false;
          });
          return;
        }
      }

      // Get current location
      final position = await _locationService.getCurrentPosition();
      if (position != null) {
        _currentPosition = position;
      }
    } catch (e) {
      _error = 'Failed to initialize check-out: ${e.toString()}';
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _takeSelfie() async {
    try {
      final XFile? image = await _cameraService.takePicture();
      if (image != null) {
        final imageFile = File(image.path);
        final bytes = await imageFile.readAsBytes();
        final base64String = base64Encode(bytes);

        setState(() {
          _selfieImage = imageFile;
          _selfieBase64 = 'data:image/jpeg;base64,$base64String';
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to take selfie: ${e.toString()}');
    }
  }

  Future<void> _checkOut() async {
    if (_todaySiteId == null) {
      _showErrorSnackBar('No check-in site found');
      return;
    }

    if (_currentPosition == null) {
      _showErrorSnackBar('Location not available');
      return;
    }

    if (_selfieBase64 == null) {
      _showErrorSnackBar('Please take a selfie');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
      
      final success = await attendanceProvider.checkOut(
        siteId: _todaySiteId!,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        selfieBase64: _selfieBase64,
      );

      if (success) {
        if (mounted) {
          _showSuccessSnackBar('Check-out successful!');
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          _showErrorSnackBar(attendanceProvider.error ?? 'Check-out failed');
        }
      }
    } catch (e) {
      _showErrorSnackBar('Check-out failed: ${e.toString()}');
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Check Out',
        showBackButton: true,
      ),
      body: _isLoading
          ? const LoadingWidget()
          : _error != null
              ? _buildErrorWidget()
              : _buildCheckOutForm(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Check-Out Error',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.red[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _initializeCheckOut,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckOutForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCheckInSummary(),
          const SizedBox(height: 24),
          _buildLocationSection(),
          const SizedBox(height: 24),
          _buildSelfieSection(),
          const SizedBox(height: 32),
          _buildCheckOutButton(),
        ],
      ),
    );
  }

  Widget _buildCheckInSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Today\'s Check-In Info',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Site', _todaySiteName ?? 'Unknown'),
            const SizedBox(height: 8),
            _buildInfoRow('Check-In Time', _checkInTime ?? 'Unknown'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Current Location',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_currentPosition != null) ...[
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Lat: ${_currentPosition!.latitude.toStringAsFixed(6)}, '
                      'Lng: ${_currentPosition!.longitude.toStringAsFixed(6)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Accuracy: ${_currentPosition!.accuracy.toStringAsFixed(1)}m',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ] else ...[
              Row(
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  const Text('Location not available'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSelfieSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.camera_alt, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Take Selfie',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_selfieImage != null) ...[
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: FileImage(_selfieImage!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  const Text('Selfie captured'),
                  const Spacer(),
                  TextButton(
                    onPressed: _takeSelfie,
                    child: const Text('Retake'),
                  ),
                ],
              ),
            ] else ...[
              InkWell(
                onTap: _takeSelfie,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey[300]!,
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[50],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to take selfie',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCheckOutButton() {
    final canCheckOut = _todaySiteId != null &&
        _currentPosition != null &&
        _selfieBase64 != null &&
        !_isLoading;

    return SizedBox(
      width: double.infinity,
      child: CustomButton(
        text: 'Check Out',
        onPressed: canCheckOut ? _checkOut : null,
        isLoading: _isLoading,
        backgroundColor: Colors.orange,
      ),
    );
  }

  Duration _calculateWorkingTime() {
    if (_checkInTime == null) return Duration.zero;
    
    try {
      final checkInDateTime = DateTime.parse('${DateTime.now().toIso8601String().split('T')[0]} $_checkInTime');
      final now = DateTime.now();
      return now.difference(checkInDateTime);
    } catch (e) {
      return Duration.zero;
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    return '$hours:$minutes';
  }
}