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
  List<Site> _allSites = []; // Changed: Now storing all sites instead of just nearby
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
      }

      // Fetch all available sites
      if (mounted) {
        final siteProvider = Provider.of<SiteProvider>(context, listen: false);
        await siteProvider.fetchSites();
        
        // Changed: Get all sites instead of filtering by radius
        _allSites = siteProvider.sites;

        // Auto-select nearest site if available and location is available
        if (_allSites.isNotEmpty && _currentPosition != null) {
          _selectedSite = siteProvider.getNearestSite(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
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
        final File imageFile = File(image.path);
        final List<int> imageBytes = await imageFile.readAsBytes();
        final String base64Image = base64Encode(imageBytes);

        setState(() {
          _selfieImage = imageFile;
          _selfieBase64 = base64Image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to capture image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitCheckIn() async {
    if (_selectedSite == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a site'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selfieBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please take a selfie'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location not available'),
          backgroundColor: Colors.red,
        ),
      );
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

      if (success && mounted) {
        Navigator.of(context).pop(true); // Return success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Check-in successful!'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(attendanceProvider.error ?? 'Check-in failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Check In'),
      body: _isLoading
          ? const LoadingWidget()
          : _error != null
              ? _buildErrorView()
              : _buildMainContent(),
    );
  }

  Widget _buildErrorView() {
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
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Retry',
              onPressed: _initializeCheckIn,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildSiteSelection(),
          const SizedBox(height: 16),
          _buildLocationInfo(),
          const SizedBox(height: 16),
          _buildSelfieSection(),
          const SizedBox(height: 24),
          _buildCheckInButton(),
        ],
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
            // Changed: Show all sites or informative message
            if (_allSites.isEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No sites available. Please contact administrator.',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Changed: Show dropdown with all sites
              DropdownButtonFormField<Site>(
                value: _selectedSite,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Choose Site',
                ),
                items: _allSites.map((site) {
                  // Calculate distance if location is available
                  final distance = _currentPosition != null && site.hasCoordinates
                      ? Provider.of<SiteProvider>(context, listen: false)
                          .calculateDistanceToSite(
                            site,
                            _currentPosition!.latitude,
                            _currentPosition!.longitude,
                          )
                      : null;

                  return DropdownMenuItem<Site>(
                    value: site,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          site.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (Site? newSite) {
                  setState(() {
                    _selectedSite = newSite;
                  });
                },
                isExpanded: true,
                menuMaxHeight: 300, // Limit dropdown height for better UX
              ),
              
              // Show distance warning if user is far from selected site
              if (_selectedSite != null && 
                  _currentPosition != null && 
                  _selectedSite!.hasCoordinates) ...[
                const SizedBox(height: 8),
                Builder(
                  builder: (context) {
                    final distance = Provider.of<SiteProvider>(context, listen: false)
                        .calculateDistanceToSite(
                          _selectedSite!,
                          _currentPosition!.latitude,
                          _currentPosition!.longitude,
                        );
                    
                    if (distance > AppConfig.locationRadius) {
                      return Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning, color: Colors.orange, size: 16),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'You are ${(distance / 1000).toStringAsFixed(1)} km away from this site',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLocationInfo() {
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
                  'Location',
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
                      'Location detected: ${_currentPosition!.latitude.toStringAsFixed(6)}, ${_currentPosition!.longitude.toStringAsFixed(6)}',
                      style: const TextStyle(color: Colors.green),
                    ),
                  ),
                ],
              ),
            ] else ...[
              const Row(
                children: [
                  Icon(Icons.error, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Location not available',
                    style: TextStyle(color: Colors.orange),
                  ),
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
                  'Selfie',
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
                  const Text(
                    'Selfie captured',
                    style: TextStyle(color: Colors.green),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _takeSelfie,
                    child: const Text('Retake'),
                  ),
                ],
              ),
            ] else ...[
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: InkWell(
                  onTap: _takeSelfie,
                  borderRadius: BorderRadius.circular(8),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        'Tap to take selfie',
                        style: TextStyle(color: Colors.grey),
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
    final bool canCheckIn = _selectedSite != null && 
                           _selfieBase64 != null && 
                           _currentPosition != null;

    return SizedBox(
      width: double.infinity,
      child: CustomButton(
        text: 'Check In',
        onPressed: canCheckIn ? _submitCheckIn : null,
        isLoading: _isLoading,
      ),
    );
  }
}