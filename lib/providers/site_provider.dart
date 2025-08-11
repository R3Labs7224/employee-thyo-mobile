// lib/providers/site_provider.dart
import 'package:flutter/material.dart';
import '../models/site.dart';
import '../services/site_service.dart';
import '../config/app_config.dart';

class SiteProvider with ChangeNotifier {
  final SiteService _siteService = SiteService();

  List<Site> _sites = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Site> get sites => _sites;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch all sites
  Future<void> fetchSites() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _siteService.getSites();

      if (response.success && response.data != null) {
        _sites = response.data!.sites;
        _error = null;
      } else {
        _error = response.message;
      }
    } catch (e) {
      _error = 'Failed to fetch sites: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Get site by ID
  Site? getSiteById(int siteId) {
    return _siteService.getSiteById(_sites, siteId);
  }

  // Get sites within radius of user location
  List<Site> getSitesWithinRadius(
    double userLatitude,
    double userLongitude,
    {double? customRadius}
  ) {
    final radius = customRadius ?? AppConfig.locationRadius;
    return _siteService.getSitesWithinRadius(
      _sites,
      userLatitude,
      userLongitude,
      radius,
    );
  }

  // Get nearest site to user location
  Site? getNearestSite(double userLatitude, double userLongitude) {
    return _siteService.getNearestSite(_sites, userLatitude, userLongitude);
  }

  // Check if user is within site radius
  bool isWithinSiteRadius(
    Site site,
    double userLatitude,
    double userLongitude,
    {double? customRadius}
  ) {
    final radius = customRadius ?? AppConfig.locationRadius;
    return _siteService.isWithinSiteRadius(
      site,
      userLatitude,
      userLongitude,
      radius,
    );
  }

  // Calculate distance to site
  double calculateDistanceToSite(
    Site site,
    double userLatitude,
    double userLongitude,
  ) {
    if (!site.hasCoordinates) return 0.0;
    
    return _siteService.calculateDistance(
      site.latitude!,
      site.longitude!,
      userLatitude,
      userLongitude,
    );
  }

  // Get sites with coordinates only
  List<Site> get sitesWithCoordinates {
    return _sites.where((site) => site.hasCoordinates).toList();
  }

  // Get sites without coordinates
  List<Site> get sitesWithoutCoordinates {
    return _sites.where((site) => !site.hasCoordinates).toList();
  }

  // Search sites by name
  List<Site> searchSites(String query) {
    if (query.isEmpty) return _sites;
    
    return _sites.where((site) =>
      site.name.toLowerCase().contains(query.toLowerCase()) ||
      (site.address?.toLowerCase().contains(query.toLowerCase()) ?? false)
    ).toList();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Reset data
  void reset() {
    _sites.clear();
    _error = null;
    notifyListeners();
  }
}