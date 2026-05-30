import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'recycling_center.dart';

enum MapAccessState {
  loading,
  ready,
  serviceDisabled,
  denied,
  deniedForever,
  error,
}

class EWasteMapViewState {
  const EWasteMapViewState({
    this.accessState = MapAccessState.loading,
    this.isLoadingLocation = true,
    this.isLoadingCenters = false,
    this.followUser = true,
    this.currentPosition,
    this.mapCenter,
    this.centers = const [],
    this.selectedCenter,
    this.searchQuery = '',
    this.errorMessage,
    this.lastRefreshedAt,
  });

  final MapAccessState accessState;
  final bool isLoadingLocation;
  final bool isLoadingCenters;
  final bool followUser;
  final Position? currentPosition;
  final LatLng? mapCenter;
  final List<RecyclingCenter> centers;
  final RecyclingCenter? selectedCenter;
  final String searchQuery;
  final String? errorMessage;
  final DateTime? lastRefreshedAt;

  bool get hasUserLocation => currentPosition != null;

  bool get canUseMap => accessState == MapAccessState.ready && currentPosition != null;

  bool get hasCenters => centers.isNotEmpty;

  EWasteMapViewState copyWith({
    MapAccessState? accessState,
    bool? isLoadingLocation,
    bool? isLoadingCenters,
    bool? followUser,
    Position? currentPosition,
    bool clearCurrentPosition = false,
    LatLng? mapCenter,
    bool clearMapCenter = false,
    List<RecyclingCenter>? centers,
    RecyclingCenter? selectedCenter,
    bool clearSelectedCenter = false,
    String? searchQuery,
    String? errorMessage,
    bool clearErrorMessage = false,
    DateTime? lastRefreshedAt,
  }) {
    return EWasteMapViewState(
      accessState: accessState ?? this.accessState,
      isLoadingLocation: isLoadingLocation ?? this.isLoadingLocation,
      isLoadingCenters: isLoadingCenters ?? this.isLoadingCenters,
      followUser: followUser ?? this.followUser,
      currentPosition: clearCurrentPosition ? null : currentPosition ?? this.currentPosition,
      mapCenter: clearMapCenter ? null : mapCenter ?? this.mapCenter,
      centers: centers ?? this.centers,
      selectedCenter: clearSelectedCenter ? null : selectedCenter ?? this.selectedCenter,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: clearErrorMessage ? null : errorMessage ?? this.errorMessage,
      lastRefreshedAt: lastRefreshedAt ?? this.lastRefreshedAt,
    );
  }
}