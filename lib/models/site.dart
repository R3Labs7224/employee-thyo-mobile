// lib/models/site.dart
// Helper functions for safe type conversion
int _safeInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is String) {
    final parsed = int.tryParse(value);
    return parsed ?? 0;
  }
  if (value is double) return value.toInt();
  return 0;
}

double? _safeDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) {
    final parsed = double.tryParse(value);
    return parsed;
  }
  return null;
}

String _safeString(dynamic value) {
  if (value == null) return '';
  return value.toString();
}

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
      id: _safeInt(json['id']), // Fixed: Use safe integer conversion
      name: _safeString(json['name']),
      address: json['address']?.toString(), // Safe string conversion
      latitude: _safeDouble(json['latitude']), // Safe double conversion
      longitude: _safeDouble(json['longitude']), // Safe double conversion
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
  
  @override
  String toString() {
    return 'Site(id: $id, name: $name, address: $address, lat: $latitude, lng: $longitude)';
  }
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Site &&
          runtimeType == other.runtimeType &&
          id == other.id;
  
  @override
  int get hashCode => id.hashCode;
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
      totalCount: _safeInt(json['total_count']), // Fixed: Use safe integer conversion
    );
  }
  
  @override
  String toString() {
    return 'SitesResponse(sites: ${sites.length}, totalCount: $totalCount)';
  }
}