// lib/screens/attendance/check_in_screen.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/site_provider.dart';
import '../../models/site.dart';
import '../../services/location_service.dart';
import '../../services/camera_service.dart';
import '../../config/app_config.dart';
import '../../config/theme.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/loading_widget.dart';

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  final LocationService _locationService = LocationService();
  final CameraService _cameraService = CameraService();
  
  Position? _currentPosition;
  Site? _selectedSite;
  List<Site> _nearbySites = [];
  File? _selfieImage;
  String? _selfieBase64;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeCheckIn();
  }

  Future<void> _initializeCheckIn() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Check location permission
      final hasPermission = await _locationService.checkPermission();
      if (!hasPermission) {
        final granted = await _locationService.requestPermission();
        if (!granted) {
          setState(() {
            _error = 'Location permission is required for check-in';
            _isLoading = false;
          });
          return;
        }
      }

      // Get current location
      final position = await _locationService.getCurrentPosition();
      if (position != null) {
        _currentPosition = position;

        // Fetch sites and find nearby ones
        if (!mounted) return;
        final siteProvider = Provider.of<SiteProvider>(context, listen: false);
        await siteProvider.fetchSites();

        _nearbySites = siteProvider.getSitesWithinRadius(
          position.latitude,
          position.longitude,
        );

        // Auto-select nearest site if available
        if (_nearbySites.isNotEmpty) {
          _selectedSite = siteProvider.getNearestSite(
            position.latitude,
            position.longitude,
          );
        }
      }
    } catch (e) {
      _error = 'Failed to get location: ${e.toString()}';
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

  Future<void> _checkIn() async {
    if (_selectedSite == null) {
      _showErrorSnackBar('Please select a site');
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
      
      final success = await attendanceProvider.checkIn(
        siteId: _selectedSite!.id,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        selfieBase64: _selfieBase64,
      );

      if (success) {
        if (mounted) {
          _showSuccessSnackBar('Check-in successful!');
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          _showErrorSnackBar(attendanceProvider.error ?? 'Check-in failed');
        }
      }
    } catch (e) {
      _showErrorSnackBar('Check-in failed: ${e.toString()}');
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Check In',
        showBackButton: true,
      ),
      body: _isLoading
          ? const LoadingWidget()
          : _error != null
              ? _buildErrorWidget()
              : _buildCheckInForm(),
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
              'Check-In Error',
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
              onPressed: _initializeCheckIn,
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

  Widget _buildCheckInForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLocationSection(),
          const SizedBox(height: 24),
          _buildSiteSelection(),
          const SizedBox(height: 24),
          _buildSelfieSection(),
          const SizedBox(height: 32),
          _buildCheckInButton(),
        ],
      ),
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
                  Icon(Icons.check_circle, color: Colors.green, size: 20),
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
                  Icon(Icons.error, color: Colors.red, size: 20),
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

  Widget _buildSiteSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.business, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Select Site',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_nearbySites.isEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No sites available within ${AppConfig.locationRadius}m radius',
                        style: TextStyle(color: Colors.orange[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              DropdownButtonFormField<Site>(
                value: _selectedSite,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Choose Site',
                ),
                items: _nearbySites.map((site) {
                  final distance = _currentPosition != null
                      ? Provider.of<SiteProvider>(context, listen: false)
                          .calculateDistanceToSite(
                            site,
                            _currentPosition!.latitude,
                            _currentPosition!.longitude,
                          )
                      : 0.0;

                  return DropdownMenuItem<Site>(
                    value: site,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(site.name),
                        Text(
                          '${distance.toStringAsFixed(0)}m away',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(                ),
                onChanged: (site) {
                  setState(() {
                    _selectedSite = site;
                  });
                },
              ),
              if (_selectedSite != null) ...[
                const SizedBox(height: 8),
                Text(
                  _selectedSite!.address ?? 'No address available',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
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
                    border: Border.all(color: Colors.grey[300]!, width: 2, style: BorderStyle.solid),
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

  Widget _buildCheckInButton() {
    final canCheckIn = _selectedSite != null &&
        _currentPosition != null &&
        _selfieBase64 != null &&
        !_isLoading;

    return SizedBox(
      width: double.infinity,
      child: CustomButton(
        text: 'Check In',
        onPressed: canCheckIn ? _checkIn : null,
        isLoading: _isLoading,
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }
}