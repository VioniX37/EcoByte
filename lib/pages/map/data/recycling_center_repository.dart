import 'package:e_waste/app/data/supabase_repository.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/recycling_center.dart';

class RecyclingCenterRepository {
  RecyclingCenterRepository({SupabaseClient? client}) : _client = client ?? SupabaseRepository.client;

  final SupabaseClient _client;

  Future<List<RecyclingCenter>> fetchNearbyCenters({
    required LatLng center,
    double radiusKm = 25,
    int limit = 80,
  }) async {
    final response = await _client.rpc(
      'get_nearby_recyclers',
      params: {
        'lat': center.latitude,
        'lng': center.longitude,
        'radius_km': radiusKm,
        'limit_count': limit,
      },
    );

    if (response is! List) {
      return const [];
    }

    return response
        .whereType<Map>()
        .map((row) => RecyclingCenter.fromJson(Map<String, dynamic>.from(row.cast<String, dynamic>())))
        .toList();
  }
}