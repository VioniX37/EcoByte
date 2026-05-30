import 'package:e_waste/app/data/supabase_repository.dart';
import 'package:e_waste/app/widgets/premium_ui.dart';
import 'package:e_waste/app/widgets/theme_toggle_icon_button.dart';
import 'package:e_waste/pages/auth/login_screen.dart';
import 'package:e_waste/pages/about/about_page.dart';
import 'package:e_waste/pages/buy_sell/buy_screen.dart';
import 'package:e_waste/pages/buy_sell/my_products.dart';
import 'package:e_waste/pages/map/controllers/map_controller.dart';
import 'package:e_waste/pages/map/data/recycling_center_repository.dart';
import 'package:e_waste/pages/map/models/map_view_state.dart';
import 'package:e_waste/pages/map/models/recycling_center.dart';
import 'package:e_waste/pages/map/services/map_location_service.dart';
import 'package:e_waste/pages/profile/profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class EWasteMapPage extends StatefulWidget {
  const EWasteMapPage({super.key});

  @override
  State<EWasteMapPage> createState() => _EWasteMapPageState();
}

class _EWasteMapPageState extends State<EWasteMapPage> {
  final MapController mapController = MapController();
  late final EWasteMapController controller;
  bool _showMorePanel = false;
  bool _showInfoPanel = false;

  static const LatLng _defaultCenter = LatLng(23.5937, 78.9629);

  @override
  void initState() {
    super.initState();
    controller = EWasteMapController(
      repository: RecyclingCenterRepository(),
      locationService: MapLocationService(),
      onCameraFocusRequested: (target, zoom) {
        if (!mounted) {
          return;
        }

        mapController.move(target, zoom);
      },
    );
    controller.addListener(_handleControllerChanged);
    controller.initialize();
  }

  @override
  void dispose() {
    controller.removeListener(_handleControllerChanged);
    controller.dispose();
    mapController.dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final state = controller.state;
    final visibleCenters = _filteredCenters(state.centers, state.searchQuery);
    final userLocation = state.currentPosition == null
        ? null
        : LatLng(state.currentPosition!.latitude, state.currentPosition!.longitude);

    return PremiumShell(
      appBar: AppBar(
        title: const Text('Recycling centers'),
        actions: [
          const ThemeToggleIconButton(),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (ctx) => const ProfileScreen()),
                  );
                  break;
                case 'marketplace':
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (ctx) => const BuyScreen()),
                  );
                  break;
                case 'my_products':
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (ctx) => const MyProducts()),
                  );
                  break;
                case 'about':
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (ctx) => const AboutPage()),
                  );
                  break;
                case 'logout':
                  SupabaseRepository.client.auth.signOut();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (ctx) => const LoginScreen()),
                    (route) => false,
                  );
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'profile', child: Text('Profile')),
              PopupMenuItem(value: 'marketplace', child: Text('Marketplace')),
              PopupMenuItem(value: 'my_products', child: Text('My products')),
              PopupMenuItem(value: 'about', child: Text('About')),
              PopupMenuItem(value: 'logout', child: Text('Logout')),
            ],
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned.fill(
              child: FlutterMap(
                mapController: mapController,
                options: MapOptions(
                  initialCenter: _defaultCenter,
                  initialZoom: 5.2,
                  interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
                  onPositionChanged: (camera, hasGesture) {
                    controller.updateMapCenter(camera.center, userGesture: hasGesture);
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.ecobyte.app',
                  ),
                  if (visibleCenters.isNotEmpty)
                    MarkerLayer(
                      markers: visibleCenters
                          .map(
                            (center) => Marker(
                              point: center.location,
                              width: 52,
                              height: 52,
                              child: GestureDetector(
                                onTap: () => _showCenterDetails(center),
                                child: _RecyclerMarker(center: center),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  if (userLocation != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: userLocation,
                          width: 48,
                          height: 48,
                          child: const _CurrentLocationMarker(),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: Column(
                children: [
                  PremiumSurface(
                    borderRadius: 20,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                onChanged: controller.updateSearchQuery,
                                style: Theme.of(context).textTheme.bodyMedium,
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                                  border: InputBorder.none,
                                  hintText: 'Search recyclers, city, or category',
                                  isDense: true,
                                  prefixIcon: Icon(Icons.search),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _MapIconButton(
                              icon: Icons.my_location,
                              tooltip: 'Recenter',
                              onPressed: controller.recenter,
                            ),
                            const SizedBox(width: 8),
                            _MapIconButton(
                              icon: _showMorePanel ? Icons.expand_less : Icons.more_horiz,
                              tooltip: _showMorePanel ? 'Hide map options' : 'Show map options',
                              onPressed: () {
                                setState(() {
                                  _showMorePanel = !_showMorePanel;
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            _MapIconButton(
                              icon: _showInfoPanel ? Icons.close : Icons.info_outline,
                              tooltip: _showInfoPanel ? 'Hide help' : 'Show help',
                              onPressed: () {
                                setState(() {
                                  _showInfoPanel = !_showInfoPanel;
                                });
                              },
                            ),
                          ],
                        ),
                        if (_showInfoPanel) ...[
                          const SizedBox(height: 10),
                          PremiumSurface(
                            borderRadius: 16,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.info_outline, size: 18, color: scheme.primary),
                                    const SizedBox(width: 8),
                                    Text(
                                      'How to use this map',
                                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: scheme.onSurface,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Use the search box to find recyclers by city, name, or category. Tap a marker to open recycler details, phone number, and directions. Use More for extra map controls.',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                        height: 1.45,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (_showMorePanel) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _StatusChip(
                                label: '${visibleCenters.length} recyclers visible',
                                icon: Icons.recycling_outlined,
                                accent: scheme.secondary,
                              ),
                              _StatusChip(
                                label: state.accessState == MapAccessState.ready
                                    ? 'Location ready'
                                    : 'Location setup needed',
                                icon: state.accessState == MapAccessState.ready
                                    ? Icons.gps_fixed
                                    : Icons.location_off,
                                accent: state.accessState == MapAccessState.ready
                                    ? scheme.primary
                                    : scheme.error,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: controller.refreshNearby,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Refresh'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => controller.setFollowUser(!state.followUser),
                                  icon: Icon(state.followUser ? Icons.gps_fixed : Icons.gps_not_fixed),
                                  label: Text(state.followUser ? 'Follow on' : 'Follow off'),
                                ),
                              ),
                            ],
                          ),
                          if (state.isLoadingLocation || state.isLoadingCenters || state.errorMessage != null) ...[
                            const SizedBox(height: 10),
                            PremiumSurface(
                              borderRadius: 16,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              child: Row(
                                children: [
                                  if (state.isLoadingLocation || state.isLoadingCenters)
                                    const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  else
                                    Icon(Icons.info_outline, color: scheme.error),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      state.errorMessage ?? 'Loading your location and nearby recyclers...',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ),
                                  if (state.errorMessage != null)
                                    TextButton(
                                      onPressed: () async {
                                        await Geolocator.openAppSettings();
                                      },
                                      child: const Text('Settings'),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: state.selectedCenter == null
                    ? const SizedBox.shrink()
                    : PremiumSurface(
                        key: ValueKey(state.selectedCenter!.id),
                        borderRadius: 22,
                        child: _SelectedCenterCard(
                          center: state.selectedCenter!,
                          userLocation: userLocation,
                          onDismiss: _dismissSelectedCenter,
                          onDirections: () => _launchMaps(state.selectedCenter!),
                          onCall: state.selectedCenter!.phone == null
                              ? null
                              : () => _launchPhone(state.selectedCenter!.phone!),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<RecyclingCenter> _filteredCenters(List<RecyclingCenter> centers, String searchQuery) {
    final query = searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return centers;
    }

    return centers.where((center) {
      return center.name.toLowerCase().contains(query) ||
          center.address.toLowerCase().contains(query) ||
          (center.city?.toLowerCase().contains(query) ?? false) ||
          (center.state?.toLowerCase().contains(query) ?? false) ||
          center.acceptedCategories.any((category) => category.toLowerCase().contains(query));
    }).toList();
  }

  void _showCenterDetails(RecyclingCenter center) {
    controller.selectCenter(center);
  }

  void _dismissSelectedCenter() {
    controller.selectCenter(null);
  }

  void _launchPhone(String phoneNumber) async {
    final Uri uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch phone app')),
      );
    }
  }

  void _launchMaps(RecyclingCenter center) async {
    final origin = controller.state.currentPosition == null
        ? null
        : '${controller.state.currentPosition!.latitude},${controller.state.currentPosition!.longitude}';

    final googleUrl =
        'https://www.google.com/maps/dir/?api=1&destination=${center.location.latitude},${center.location.longitude}${origin == null ? '' : '&origin=$origin'}&travelmode=driving';
    final Uri googleUri = Uri.parse(googleUrl);

    final osmUrl =
        'https://www.openstreetmap.org/?mlat=${center.location.latitude}&mlon=${center.location.longitude}#map=15/${center.location.latitude}/${center.location.longitude}';
    final Uri osmUri = Uri.parse(osmUrl);

    if (await canLaunchUrl(googleUri)) {
      await launchUrl(googleUri, mode: LaunchMode.externalApplication);
    } else if (await canLaunchUrl(osmUri)) {
      await launchUrl(osmUri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch any map application')),
      );
    }
  }
}

class _MapIconButton extends StatelessWidget {
  const _MapIconButton({required this.icon, required this.tooltip, required this.onPressed});

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: scheme.surface,
        shape: const CircleBorder(),
        elevation: 6,
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.icon, required this.accent});

  final String label;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16, color: accent),
      label: Text(label),
      side: BorderSide(color: accent.withValues(alpha: 0.18)),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
    );
  }
}

class _RecyclerMarker extends StatelessWidget {
  const _RecyclerMarker({required this.center});

  final RecyclingCenter center;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: center.verified ? scheme.primary : scheme.secondary,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.recycling, color: Colors.white, size: 20),
        ),
        Positioned(
          bottom: 0,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: center.verified ? scheme.primary : scheme.secondary,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

class _CurrentLocationMarker extends StatelessWidget {
  const _CurrentLocationMarker();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: scheme.primary.withValues(alpha: 0.18),
          ),
        ),
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: scheme.primary,
            border: Border.all(color: Colors.white, width: 3),
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: scheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SelectedCenterCard extends StatelessWidget {
  const _SelectedCenterCard({
    required this.center,
    required this.userLocation,
    required this.onDismiss,
    required this.onDirections,
    this.onCall,
  });

  final RecyclingCenter center;
  final LatLng? userLocation;
  final VoidCallback onDismiss;
  final VoidCallback onDirections;
  final VoidCallback? onCall;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final distanceText = userLocation == null
        ? center.distanceLabel
        : '${(Geolocator.distanceBetween(
                  userLocation!.latitude,
                  userLocation!.longitude,
                  center.location.latitude,
                  center.location.longitude,
                ) / 1000)
                .toStringAsFixed(1)} km away';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                center.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
            ),
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _StatusChip(
              label: distanceText,
              icon: Icons.straighten,
              accent: scheme.secondary,
            ),
            _StatusChip(
              label: center.verified ? 'Verified recycler' : 'Not yet verified',
              icon: center.verified ? Icons.verified : Icons.info_outline,
              accent: center.verified ? scheme.primary : scheme.tertiary,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          center.address,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        if (center.workingHours != null && center.workingHours!.isNotEmpty) ...[
          _DetailRow(icon: Icons.schedule, label: 'Working hours', value: center.workingHours!),
          const SizedBox(height: 10),
        ],
        if (center.acceptedCategories.isNotEmpty) ...[
          _DetailRow(
            icon: Icons.category_outlined,
            label: 'Accepted categories',
            value: center.acceptedCategories.join(', '),
          ),
          const SizedBox(height: 10),
        ],
        if (center.phone != null) ...[
          InkWell(
            onTap: onCall,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.phone_outlined, size: 18, color: scheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    center.phone!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.primary,
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onDirections,
            icon: const Icon(Icons.directions_outlined),
            label: const Text('Get directions'),
          ),
        ),
      ],
    );
  }
}

