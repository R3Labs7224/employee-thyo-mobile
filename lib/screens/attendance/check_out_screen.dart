// lib/screens/attendance/check_out_screen.dart - UPDATED: Removed selfie functionality
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/attendance_provider.dart';
import '../../services/location_service.dart';
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
  
  Position? _currentPosition;
  bool _isLoading = false;
  String? _error;
  
  // Today's attendance info
  int? _todaySiteId;
  String? _todaySiteName;

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
      
      if (todayAttendance == null || !todayAttendance.isCheckedIn) {
        setState(() {
          _error = 'No check-in found for today. Please check in first.';
          _isLoading = false;
        });
        return;
      }

      // Set today's attendance info
      _todaySiteId = todayAttendance.siteId;
      _todaySiteName = todayAttendance.siteName;

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

  Future<void> _checkOut() async {
    if (_todaySiteId == null) {
      _showErrorSnackBar('No check-in site found');
      return;
    }

    if (_currentPosition == null) {
      _showErrorSnackBar('Location not available');
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
              ? _buildErrorState()
              : _buildCheckOutForm(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(height: 16),
          CustomButton(
            text: 'Retry',
            onPressed: _initializeCheckOut,
          ),
        ],
      ),
    );
  }

  Widget _buildCheckOutForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Check-in Info Card
          _buildCheckInInfoCard(),
          const SizedBox(height: 20),
          
          // Current Location Card
          _buildLocationStatusCard(),
          const SizedBox(height: 30),
          
          // Check-out Button
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: 'Check Out',
              onPressed: _canCheckOut() ? _checkOut : null,
              isLoading: _isLoading,
              backgroundColor: Colors.red,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Info Text
          const Text(
            'Check-out will record your current location coordinates.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckInInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.primaryColor),
                SizedBox(width: 8),
                Text(
                  'Today\'s Check-in Info',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_todaySiteName != null) ...[
              Row(
                children: [
                  const Icon(Icons.business, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Site: $_todaySiteName')),
                ],
              ),
              const SizedBox(height: 8),
              const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.grey),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Already checked in today'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLocationStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.location_on, color: AppTheme.primaryColor),
                SizedBox(width: 8),
                Text(
                  'Current Location',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_currentPosition != null) ...[
              Text('Latitude: ${_currentPosition!.latitude.toStringAsFixed(6)}'),
              Text('Longitude: ${_currentPosition!.longitude.toStringAsFixed(6)}'),
              Text('Accuracy: ±${_currentPosition!.accuracy.toStringAsFixed(1)}m'),
            ] else ...[
              const Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('Getting location...'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _canCheckOut() {
    return _todaySiteId != null && 
           _currentPosition != null && 
           !_isLoading;
  }
}