// lib/services/site_service.dart
import 'dart:math' as math;
import '../models/api_response.dart';
import '../models/site.dart';
import '../config/app_config.dart';
import 'api_service.dart';

class SiteService {
  final ApiService _apiService = ApiService();

  // Get all available sites
  Future<ApiResponse<SitesResponse>> getSites() async {
    try {
      final response = await _apiService.get<SitesResponse>(
        AppConfig.sitesEndpoint,
        fromJson: (data) => SitesResponse.fromJson(data),
        requiresAuth: false, // Sites endpoint doesn't require authentication
      );

      return response;
    } catch (e) {
      return ApiResponse.error('Failed to fetch sites: ${e.toString()}');
    }
  }

  // Get site by ID
  Site? getSiteById(List<Site> sites, int siteId) {
    try {
      return sites.firstWhere((site) => site.id == siteId);
    } catch (e) {
      return null;
    }
  }

  // Calculate distance between two coordinates (in meters)
  double calculateDistance(
    double lat1, double lon1, double lat2, double lon2
  ) {
    const double earthRadius = 6371000; // Earth's radius in meters
    
    final double lat1Rad = lat1 * (math.pi / 180);
    final double lon1Rad = lon1 * (math.pi / 180);
    final double lat2Rad = lat2 * (math.pi / 180);
    final double lon2Rad = lon2 * (math.pi / 180);
    
    final double deltaLat = lat2Rad - lat1Rad;
    final double deltaLon = lon2Rad - lon1Rad;
    
    final double a = math.pow(math.sin(deltaLat / 2), 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) *
        math.pow(math.sin(deltaLon / 2), 2);
        
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }

  // Check if user is within site radius
  bool isWithinSiteRadius(
    Site site,
    double userLatitude,
    double userLongitude,
    double allowedRadius,
  ) {
    if (!site.hasCoordinates) {
      // If site doesn't have coordinates, allow access
      return true;
    }
    
    final distance = calculateDistance(
      site.latitude!,
      site.longitude!,
      userLatitude,
      userLongitude,
    );
    
    return distance <= allowedRadius;
  }

  // Get sites within radius of user location
  List<Site> getSitesWithinRadius(
    List<Site> sites,
    double userLatitude,
    double userLongitude,
    double radius,
  ) {
    return sites.where((site) {
      return isWithinSiteRadius(site, userLatitude, userLongitude, radius);
    }).toList();
  }

  // Get nearest site to user location
  Site? getNearestSite(
    List<Site> sites,
    double userLatitude,
    double userLongitude,
  ) {
    if (sites.isEmpty) return null;
    
    Site? nearestSite;
    double nearestDistance = double.infinity;
    
    for (final site in sites) {
      if (site.hasCoordinates) {
        final distance = calculateDistance(
          site.latitude!,
          site.longitude!,
          userLatitude,
          userLongitude,
        );
        
        if (distance < nearestDistance) {
          nearestDistance = distance;
          nearestSite = site;
        }
      }
    }
    
    return nearestSite;
  }
}