// lib/models/site.dart
class Site {
  final int id;
  final String name;
  final String? address;
  final double? latitude;
  final double? longitude;

  Site({
    required this.id,
    required this.name,
    this.address,
    this.latitude,
    this.longitude,
  });

  factory Site.fromJson(Map<String, dynamic> json) {
    return Site(
      id: json['id'],
      name: json['name'] ?? '',
      address: json['address'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  // Get formatted coordinates
  String get formattedCoordinates {
    if (latitude != null && longitude != null) {
      return '${latitude!.toStringAsFixed(6)}, ${longitude!.toStringAsFixed(6)}';
    }
    return 'No coordinates';
  }

  // Check if coordinates are available
  bool get hasCoordinates => latitude != null && longitude != null;
}

class SitesResponse {
  final List<Site> sites;
  final int totalCount;

  SitesResponse({
    required this.sites,
    required this.totalCount,
  });

  factory SitesResponse.fromJson(Map<String, dynamic> json) {
    return SitesResponse(
      sites: (json['sites'] as List)
          .map((item) => Site.fromJson(item))
          .toList(),
      totalCount: json['total_count'] ?? 0,
    );
  }
}