import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/trip_model.dart';
import '../../services/eta_service.dart';
import '../../services/geocoding_service.dart';
import '../../services/routing_service.dart';
import '../../services/service_locator.dart';
import '../../widgets/app_text_field.dart';

class TripSetupScreen extends StatefulWidget {
  const TripSetupScreen({super.key});

  @override
  State<TripSetupScreen> createState() => _TripSetupScreenState();
}

class _TripSetupScreenState extends State<TripSetupScreen> {
  static const LatLng _fallbackCenter = LatLng(13.0827, 80.2707);

  final _formKey = GlobalKey<FormState>();
  final _destinationCtrl = TextEditingController();
  final _geocoding = GeocodingService();
  final _routing = RoutingService();

  MapLibreMapController? _mapController;
  Circle? _destinationCircle;
  Line? _routeLine;
  Position? _currentPosition;
  List<PlaceSuggestion> _suggestions = const [];
  List<RouteOption> _routes = const [];
  int _selectedRouteIndex = 0;
  double? _destinationLatitude;
  double? _destinationLongitude;
  bool _isSearching = false;
  bool _isRouting = false;
  bool _isStarting = false;

  bool get _hasDestination =>
      _destinationLatitude != null && _destinationLongitude != null;

  RouteOption? get _selectedRoute =>
      _routes.isEmpty ? null : _routes[_selectedRouteIndex];

  @override
  void initState() {
    super.initState();
    _loadCurrentPosition();
  }

  @override
  void dispose() {
    _destinationCtrl.dispose();
    _geocoding.dispose();
    _routing.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentPosition() async {
    final granted = await ServiceLocator.location.requestPermission();
    if (!granted) return;
    final position = await ServiceLocator.location.getCurrentPosition();
    if (!mounted || position == null) return;
    setState(() => _currentPosition = position);
    await _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(position.latitude, position.longitude),
        13,
      ),
    );
  }

  void _onMapCreated(MapLibreMapController controller) {
    _mapController = controller;
  }

  Future<void> _onMapTap(Point<double> _, LatLng coordinates) async {
    FocusScope.of(context).unfocus();
    await _setDestination(
      latitude: coordinates.latitude,
      longitude: coordinates.longitude,
      label: _destinationCtrl.text.trim().isEmpty ? 'Pinned destination' : null,
      moveCamera: false,
    );
  }

  void _onDestinationChanged(String value) {
    _clearRouteSelection();
    setState(() => _suggestions = const []);
  }

  Future<void> _searchDestination() async {
    final query = _destinationCtrl.text.trim();
    if (query.length < 3) return;
    setState(() => _isSearching = true);
    final results = await _geocoding.search(query);
    if (!mounted || _destinationCtrl.text.trim() != query) return;
    setState(() {
      _suggestions = results;
      _isSearching = false;
    });
  }

  Future<void> _selectSuggestion(PlaceSuggestion suggestion) async {
    FocusScope.of(context).unfocus();
    _destinationCtrl.text = suggestion.name;
    setState(() => _suggestions = const []);
    await _setDestination(
      latitude: suggestion.latitude,
      longitude: suggestion.longitude,
      label: suggestion.name,
      moveCamera: true,
    );
  }

  Future<void> _setDestination({
    required double latitude,
    required double longitude,
    String? label,
    bool moveCamera = true,
  }) async {
    if (label != null) _destinationCtrl.text = label;
    setState(() {
      _destinationLatitude = latitude;
      _destinationLongitude = longitude;
      _routes = const [];
      _selectedRouteIndex = 0;
    });

    await _upsertDestinationCircle(latitude, longitude);
    if (moveCamera) {
      await _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(latitude, longitude), 14),
      );
    }
    await _loadRoutes();
  }

  Future<void> _upsertDestinationCircle(
      double latitude, double longitude) async {
    final controller = _mapController;
    if (controller == null) return;
    final geometry = LatLng(latitude, longitude);
    if (_destinationCircle == null) {
      _destinationCircle = await controller.addCircle(
        CircleOptions(
          geometry: geometry,
          circleColor: '#C62828',
          circleRadius: 9,
          circleStrokeColor: '#FFFFFF',
          circleStrokeWidth: 3,
        ),
      );
    } else {
      await controller.updateCircle(
        _destinationCircle!,
        CircleOptions(geometry: geometry),
      );
    }
  }

  Future<void> _loadRoutes() async {
    if (!_hasDestination) return;

    setState(() => _isRouting = true);
    var routes = <RouteOption>[];
    final position = _currentPosition;
    if (position != null) {
      routes = await _routing.routes(
        startLatitude: position.latitude,
        startLongitude: position.longitude,
        destinationLatitude: _destinationLatitude!,
        destinationLongitude: _destinationLongitude!,
      );
    }

    if (routes.isEmpty && position != null) {
      final distanceKm = Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            _destinationLatitude!,
            _destinationLongitude!,
          ) /
          1000;
      routes = [
        RouteOption(
          distanceKm: distanceKm,
          durationMinutes: EtaService.durationMinutesForDistance(distanceKm),
          path: [
            TripCoordinate(
              latitude: position.latitude,
              longitude: position.longitude,
            ),
            TripCoordinate(
              latitude: _destinationLatitude!,
              longitude: _destinationLongitude!,
            ),
          ],
        ),
      ];
    }

    if (!mounted) return;
    setState(() {
      _routes = routes;
      _selectedRouteIndex = 0;
      _isRouting = false;
    });
    await _drawSelectedRoute();
  }

  Future<void> _drawSelectedRoute() async {
    final controller = _mapController;
    final route = _selectedRoute;
    if (controller == null || route == null || route.path.isEmpty) return;

    final geometry = route.path
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList(growable: false);

    if (_routeLine == null) {
      _routeLine = await controller.addLine(
        LineOptions(
          geometry: geometry,
          lineColor: '#1B3A6B',
          lineWidth: 4,
          lineOpacity: 0.9,
        ),
      );
    } else {
      await controller.updateLine(
        _routeLine!,
        LineOptions(geometry: geometry),
      );
    }
  }

  void _clearRouteSelection() {
    if (!_hasDestination && _routes.isEmpty) return;
    setState(() {
      _destinationLatitude = null;
      _destinationLongitude = null;
      _routes = const [];
      _selectedRouteIndex = 0;
    });
    final controller = _mapController;
    final circle = _destinationCircle;
    final line = _routeLine;
    if (controller != null && circle != null) {
      _destinationCircle = null;
      unawaited(controller.removeCircle(circle));
    }
    if (controller != null && line != null) {
      _routeLine = null;
      unawaited(controller.removeLine(line));
    }
  }

  Future<void> _startTrip() async {
    if (!_formKey.currentState!.validate()) return;

    final route = _selectedRoute;
    final distanceKm = route?.distanceKm;
    final durationMinutes = route?.durationMinutes ??
        (distanceKm != null
            ? EtaService.durationMinutesForDistance(distanceKm)
            : 15);

    setState(() => _isStarting = true);

    await ServiceLocator.trip.startTrip(
      destination: _destinationCtrl.text.trim(),
      destinationLatitude: _destinationLatitude,
      destinationLongitude: _destinationLongitude,
      routeDistanceKm: distanceKm,
      routePath: route?.path ?? const [],
      durationMinutes: durationMinutes,
    );

    if (!mounted) return;
    Navigator.of(context).pop();
    Navigator.of(context).pushNamed(AppConstants.routeActiveTrip);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final route = _selectedRoute;

    return Scaffold(
      appBar: AppBar(title: const Text('New Trip')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 48),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Where are you going?',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.charcoal,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Search for a place or tap the map to move your destination pin.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppTheme.mutedGray),
                ),
                const SizedBox(height: 24),
                _DestinationSelector(
                  controller: _destinationCtrl,
                  suggestions: _suggestions,
                  isSearching: _isSearching,
                  hasDestination: _hasDestination,
                  onChanged: _onDestinationChanged,
                  onSearch: _searchDestination,
                  onSuggestionSelected: _selectSuggestion,
                ),
                const SizedBox(height: 16),
                _OsmMap(
                  currentPosition: _currentPosition,
                  onMapCreated: _onMapCreated,
                  onMapTap: _onMapTap,
                ),
                const SizedBox(height: 20),
                _RouteSummary(
                  isRouting: _isRouting,
                  routes: _routes,
                  selectedIndex: _selectedRouteIndex,
                  onSelected: (index) async {
                    setState(() => _selectedRouteIndex = index);
                    await _drawSelectedRoute();
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _isStarting ? null : _startTrip,
                  icon: _isStarting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.surfaceWhite,
                          ),
                        )
                      : const Icon(Icons.navigation_outlined, size: 18),
                  label: Text(
                    _isStarting
                        ? 'Starting...'
                        : route == null
                            ? 'Start Trip'
                            : 'Start Trip (${route.durationMinutes} min)',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DestinationSelector extends StatelessWidget {
  final TextEditingController controller;
  final List<PlaceSuggestion> suggestions;
  final bool isSearching;
  final bool hasDestination;
  final ValueChanged<String> onChanged;
  final VoidCallback onSearch;
  final ValueChanged<PlaceSuggestion> onSuggestionSelected;

  const _DestinationSelector({
    required this.controller,
    required this.suggestions,
    required this.isSearching,
    required this.hasDestination,
    required this.onChanged,
    required this.onSearch,
    required this.onSuggestionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          controller: controller,
          label: 'Destination',
          hint: 'Search destination',
          prefixIcon: Icons.search,
          suffixIcon: isSearching
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  tooltip: 'Search destination',
                  onPressed: onSearch,
                ),
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          onChanged: onChanged,
          validator: (v) => (v == null || v.trim().isEmpty)
              ? 'Please select or enter a destination'
              : null,
        ),
        if (hasDestination) ...[
          const SizedBox(height: 8),
          const Row(
            children: [
              Icon(Icons.location_on, size: 16, color: AppTheme.safeIcon),
              SizedBox(width: 6),
              Text(
                'Destination pin selected',
                style: TextStyle(
                  color: AppTheme.safeColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppTheme.surfaceWhite,
              border: Border.all(color: AppTheme.borderLight),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: suggestions.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final suggestion = suggestions[index];
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.place_outlined),
                  title: Text(
                    suggestion.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    suggestion.displayAddress,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => onSuggestionSelected(suggestion),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _OsmMap extends StatelessWidget {
  final Position? currentPosition;
  final ValueChanged<MapLibreMapController> onMapCreated;
  final void Function(Point<double>, LatLng) onMapTap;

  const _OsmMap({
    required this.currentPosition,
    required this.onMapCreated,
    required this.onMapTap,
  });

  @override
  Widget build(BuildContext context) {
    final center = currentPosition == null
        ? _TripSetupScreenState._fallbackCenter
        : LatLng(currentPosition!.latitude, currentPosition!.longitude);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 280,
        width: double.infinity,
        child: MapLibreMap(
          styleString: _osmRasterStyle,
          initialCameraPosition: CameraPosition(target: center, zoom: 12),
          myLocationEnabled: currentPosition != null,
          myLocationTrackingMode: MyLocationTrackingMode.none,
          onMapCreated: onMapCreated,
          onMapClick: onMapTap,
        ),
      ),
    );
  }
}

class _RouteSummary extends StatelessWidget {
  final bool isRouting;
  final List<RouteOption> routes;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _RouteSummary({
    required this.isRouting,
    required this.routes,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (isRouting) {
      return const Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 10),
          Text(
            'Calculating route and ETA...',
            style: TextStyle(color: AppTheme.mutedGray),
          ),
        ],
      );
    }

    if (routes.isEmpty) {
      return const Text(
        'ETA will be calculated after your destination and current location are available.',
        style: TextStyle(color: AppTheme.mutedGray, fontSize: 12),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ROUTE OPTIONS',
          style: TextStyle(
            color: AppTheme.primaryNavy,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < routes.length; i++)
              ChoiceChip(
                selected: i == selectedIndex,
                onSelected: (_) => onSelected(i),
                label: Text(
                  '${routes[i].distanceKm.toStringAsFixed(1)} km · '
                  '${routes[i].durationMinutes} min',
                ),
                selectedColor: AppTheme.primaryNavy,
                labelStyle: TextStyle(
                  color: i == selectedIndex
                      ? AppTheme.surfaceWhite
                      : AppTheme.charcoal,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                backgroundColor: AppTheme.surfaceWhite,
                side: BorderSide(
                  color: i == selectedIndex
                      ? AppTheme.primaryNavy
                      : AppTheme.borderLight,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

final String _osmRasterStyle = jsonEncode({
  'version': 8,
  'sources': {
    'osm': {
      'type': 'raster',
      'tiles': ['https://tile.openstreetmap.org/{z}/{x}/{y}.png'],
      'tileSize': 256,
      'attribution': '© OpenStreetMap contributors',
    },
  },
  'layers': [
    {
      'id': 'osm',
      'type': 'raster',
      'source': 'osm',
    },
  ],
});
