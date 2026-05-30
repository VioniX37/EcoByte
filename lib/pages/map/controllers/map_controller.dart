import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../data/recycling_center_repository.dart';
import '../models/map_view_state.dart';
import '../models/recycling_center.dart';
import '../services/map_location_service.dart';

class EWasteMapController extends ChangeNotifier {
  EWasteMapController({
    required RecyclingCenterRepository repository,
    required MapLocationService locationService,
    this.onCameraFocusRequested,
  })  : _repository = repository,
        _locationService = locationService;

  final RecyclingCenterRepository _repository;
  final MapLocationService _locationService;
  final void Function(LatLng target, double zoom)? onCameraFocusRequested;

  EWasteMapViewState _state = const EWasteMapViewState();
  EWasteMapViewState get state => _state;

  StreamSubscription<Position>? _positionSubscription;
  Timer? _refreshDebounce;

  Future<void> initialize() async {
    _emit(
      _state.copyWith(
        accessState: MapAccessState.loading,
        isLoadingLocation: true,
        isLoadingCenters: true,
        clearErrorMessage: true,
      ),
    );

    try {
      final currentPosition = await _locationService.getCurrentPosition();
      final currentTarget = LatLng(currentPosition.latitude, currentPosition.longitude);

      _emit(
        _state.copyWith(
          accessState: MapAccessState.ready,
          isLoadingLocation: false,
          currentPosition: currentPosition,
          mapCenter: currentTarget,
          followUser: true,
          clearErrorMessage: true,
        ),
      );

      onCameraFocusRequested?.call(currentTarget, 5);
      await refreshNearby(forceCenter: currentTarget);

      _positionSubscription = _locationService.watchPosition().listen(
        (position) {
          final nextTarget = LatLng(position.latitude, position.longitude);
          final previousPosition = _state.currentPosition;

          _emit(
            _state.copyWith(
              currentPosition: position,
              mapCenter: _state.followUser ? nextTarget : _state.mapCenter,
              clearErrorMessage: true,
            ),
          );

          if (_state.followUser) {
            onCameraFocusRequested?.call(nextTarget, 15);
          }

          final shouldRefresh = previousPosition == null ||
              Geolocator.distanceBetween(
                    previousPosition.latitude,
                    previousPosition.longitude,
                    position.latitude,
                    position.longitude,
                  ) >
                  300;

          if (shouldRefresh) {
            _scheduleRefresh(nextTarget);
          }
        },
        onError: (Object error) {
          _emit(
            _state.copyWith(
              isLoadingLocation: false,
              errorMessage: 'Location updates stopped: $error',
            ),
          );
        },
      );
    } on MapLocationServiceDisabledException catch (error) {
      _emit(
        _state.copyWith(
          accessState: MapAccessState.serviceDisabled,
          isLoadingLocation: false,
          isLoadingCenters: false,
          errorMessage: error.message,
        ),
      );
    } on MapLocationPermissionPermanentlyDeniedException catch (error) {
      _emit(
        _state.copyWith(
          accessState: MapAccessState.deniedForever,
          isLoadingLocation: false,
          isLoadingCenters: false,
          errorMessage: error.message,
        ),
      );
    } on MapLocationPermissionDeniedException catch (error) {
      _emit(
        _state.copyWith(
          accessState: MapAccessState.denied,
          isLoadingLocation: false,
          isLoadingCenters: false,
          errorMessage: error.message,
        ),
      );
    } catch (error) {
      _emit(
        _state.copyWith(
          accessState: MapAccessState.error,
          isLoadingLocation: false,
          isLoadingCenters: false,
          errorMessage: 'Unable to initialize map: $error',
        ),
      );
    }
  }

  void updateSearchQuery(String query) {
    _emit(_state.copyWith(searchQuery: query));
  }

  void selectCenter(RecyclingCenter? center) {
    _emit(
      _state.copyWith(
        selectedCenter: center,
        clearSelectedCenter: center == null,
      ),
    );
  }

  void setFollowUser(bool value) {
    _emit(_state.copyWith(followUser: value));
  }

  void updateMapCenter(LatLng center, {bool userGesture = false}) {
    _emit(
      _state.copyWith(
        mapCenter: center,
        followUser: userGesture ? false : _state.followUser,
      ),
    );
  }

  Future<void> recenter() async {
    final position = _state.currentPosition;
    if (position == null) {
      return;
    }

    final target = LatLng(position.latitude, position.longitude);
    _emit(_state.copyWith(followUser: true, mapCenter: target, clearErrorMessage: true));
    onCameraFocusRequested?.call(target, 5);
    await refreshNearby(forceCenter: target);
  }

  Future<void> refreshNearby({LatLng? forceCenter}) async {
    final center = forceCenter ?? _state.mapCenter ?? _currentUserLatLng;
    if (center == null) {
      return;
    }

    _emit(
      _state.copyWith(
        isLoadingCenters: true,
        mapCenter: center,
        clearErrorMessage: true,
      ),
    );

    try {
      final centers = await _repository.fetchNearbyCenters(
        center: center,
        radiusKm: 21000,
        limit: 5000,
      );

      _emit(
        _state.copyWith(
          centers: centers,
          isLoadingCenters: false,
          lastRefreshedAt: DateTime.now(),
          clearErrorMessage: true,
        ),
      );
    } catch (error) {
      _emit(
        _state.copyWith(
          centers: const [],
          isLoadingCenters: false,
          errorMessage: 'Could not load recyclers yet: $error',
        ),
      );
    }
  }

  void _scheduleRefresh(LatLng center) {
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(const Duration(milliseconds: 450), () {
      if (_state.followUser) {
        refreshNearby(forceCenter: center);
      }
    });
  }

  LatLng? get _currentUserLatLng {
    final position = _state.currentPosition;
    if (position == null) {
      return null;
    }

    return LatLng(position.latitude, position.longitude);
  }

  void _emit(EWasteMapViewState nextState) {
    _state = nextState;
    notifyListeners();
  }

  @override
  void dispose() {
    _refreshDebounce?.cancel();
    _positionSubscription?.cancel();
    super.dispose();
  }
}