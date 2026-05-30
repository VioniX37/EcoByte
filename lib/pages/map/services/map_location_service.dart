import 'package:geolocator/geolocator.dart';

class MapLocationServiceException implements Exception {
  MapLocationServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class MapLocationServiceDisabledException extends MapLocationServiceException {
  MapLocationServiceDisabledException()
      : super('Location services are disabled on this device.');
}

class MapLocationPermissionDeniedException extends MapLocationServiceException {
  MapLocationPermissionDeniedException() : super('Location permission was denied.');
}

class MapLocationPermissionPermanentlyDeniedException extends MapLocationServiceException {
  MapLocationPermissionPermanentlyDeniedException()
      : super('Location permission is permanently denied.');
}

class MapLocationService {
  Future<Position> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw MapLocationServiceDisabledException();
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw MapLocationPermissionDeniedException();
    }

    if (permission == LocationPermission.deniedForever) {
      throw MapLocationPermissionPermanentlyDeniedException();
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  Stream<Position> watchPosition() {
    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 20,
    );

    return Geolocator.getPositionStream(locationSettings: settings);
  }
}