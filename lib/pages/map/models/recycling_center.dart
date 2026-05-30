import 'package:latlong2/latlong.dart';

class RecyclingCenter {
  const RecyclingCenter({
    required this.id,
    required this.name,
    required this.location,
    required this.address,
    required this.phone,
    required this.verified,
    required this.acceptedCategories,
    this.website,
    this.workingHours,
    this.city,
    this.state,
    this.distanceMeters,
    this.source,
  });

  final String id;
  final String name;
  final LatLng location;
  final String address;
  final String? phone;
  final String? website;
  final String? workingHours;
  final String? city;
  final String? state;
  final bool verified;
  final List<String> acceptedCategories;
  final double? distanceMeters;
  final String? source;

  factory RecyclingCenter.fromJson(Map<String, dynamic> json) {
    final latitude = _readDouble(json, ['latitude', 'lat', 'center_lat']);
    final longitude = _readDouble(json, ['longitude', 'lng', 'lon', 'center_lng']);
    final distance = _readDouble(json, ['distance_meters', 'distance', 'distance_m']);

    return RecyclingCenter(
      id: (json['id'] ?? json['uuid'] ?? json['recycler_id'] ?? '').toString(),
      name: (json['name'] ?? json['recycler_name'] ?? 'Recycler').toString(),
      location: LatLng(latitude, longitude),
      address: (json['address_text'] ?? json['address'] ?? json['formatted_address'] ?? '').toString(),
      phone: _readString(json, ['phone_e164', 'phone', 'contact_phone']),
      website: _readString(json, ['website', 'website_url', 'url']),
      workingHours: _readString(json, ['working_hours', 'hours_text', 'opening_hours']),
      city: _readString(json, ['city', 'town', 'district']),
      state: _readString(json, ['state', 'region']),
      verified: _readBool(json, ['verified', 'is_verified']) ||
          ((json['verification_status'] ?? '').toString().toLowerCase() == 'verified'),
      acceptedCategories: _readStringList(json, ['accepted_categories', 'categories', 'e_waste_categories']),
      distanceMeters: distance,
      source: _readString(json, ['source_type', 'source']),
    );
  }

  double get distanceKm => (distanceMeters ?? 0) / 1000.0;

  String get distanceLabel {
    if (distanceMeters == null) {
      return 'Distance unavailable';
    }

    if (distanceMeters! < 1000) {
      return '${distanceMeters!.round()} m away';
    }

    return '${distanceKm.toStringAsFixed(distanceKm >= 10 ? 0 : 1)} km away';
  }

  String get categoryLabel {
    if (acceptedCategories.isEmpty) {
      return 'Categories not listed';
    }

    return acceptedCategories.take(3).join(' · ');
  }

  static double _readDouble(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is num) {
        return value.toDouble();
      }

      final parsed = double.tryParse(value?.toString() ?? '');
      if (parsed != null) {
        return parsed;
      }
    }

    return 0;
  }

  static String? _readString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) {
        continue;
      }

      final text = value.toString().trim();
      if (text.isNotEmpty) {
        return text;
      }
    }

    return null;
  }

  static bool _readBool(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is bool) {
        return value;
      }

      final text = value?.toString().toLowerCase();
      if (text == 'true' || text == '1' || text == 'yes') {
        return true;
      }
    }

    return false;
  }

  static List<String> _readStringList(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is List) {
        return value.map((item) => item.toString().trim()).where((item) => item.isNotEmpty).toList();
      }

      if (value is String) {
        return value
            .split(',')
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList();
      }
    }

    return const [];
  }
}