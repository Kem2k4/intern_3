import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:math';
import '../../services/poi_service.dart';

// Performance constants
class _MapPerformanceConfig {
  static const Duration mapEventDebounce = Duration(milliseconds: 300);
  static const double poiReloadDistanceKm = 2.0;
  static const double maxPoiRadiusKm = 3.0;
}

/// Map page using Map Tiler API
class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  // Map Tiler API key
  static const String _apiKey = 'xPpUKj06TvHW1tVCIT13';

  // Initial map center (Hanoi, Vietnam)
  static final LatLng _initialCenter = LatLng(21.0285, 105.8542);

  // Current user location
  LatLng? _currentLocation;

  // Map controller for programmatic control
  late final MapController _mapController;

  // POI service
  late final PoiService _poiService;

  // List of nearby POIs
  List<Poi> _pois = [];

  // Loading state for POIs
  bool _isLoadingPois = false;

  // Current zoom level for marker scaling
  double _currentZoom = 10.0;

  // Last location where POIs were loaded
  LatLng? _lastPoiLoadLocation;

  // Debounce timer for map events
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _poiService = PoiService();
    _mapController.mapEventStream.listen(_onMapEvent);
    _initializeLocation();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  /// Handle map events to update zoom level (with debouncing)
  void _onMapEvent(MapEvent mapEvent) {
    if (mapEvent is MapEventMoveEnd) {
      // Cancel previous timer
      _debounceTimer?.cancel();
      
      // Debounce setState to reduce rebuilds
      _debounceTimer = Timer(_MapPerformanceConfig.mapEventDebounce, () {
        if (mounted && _currentZoom != mapEvent.camera.zoom) {
          setState(() {
            _currentZoom = mapEvent.camera.zoom;
          });
        }
      });
    }
  }

  /// Initialize location services
  Future<void> _initializeLocation() async {
    // Small delay to ensure plugins are initialized
    await Future.delayed(const Duration(milliseconds: 100));
    _getCurrentLocation();
  }

  /// Get marker size based on current zoom level
  double _getMarkerSize() {
    const double baseSize = 24.0; // Base size at zoom level 15
    const double baseZoom = 15.0;
    return baseSize * (_currentZoom / baseZoom);
  }

  /// Calculate distance between two points in kilometers
  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371; // Earth's radius in km
    final lat1Rad = point1.latitude * (pi / 180);
    final lat2Rad = point2.latitude * (pi / 180);
    final deltaLatRad = (point2.latitude - point1.latitude) * (pi / 180);
    final deltaLonRad = (point2.longitude - point1.longitude) * (pi / 180);

    final a = pow(sin(deltaLatRad / 2), 2) +
        cos(lat1Rad) * cos(lat2Rad) * pow(sin(deltaLonRad / 2), 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  /// Check if POIs should be reloaded based on location change
  bool _shouldReloadPois(LatLng newLocation) {
    if (_lastPoiLoadLocation == null) return true;

    final distance = _calculateDistance(_lastPoiLoadLocation!, newLocation);
    return distance > _MapPerformanceConfig.poiReloadDistanceKm;
  }

  /// Get filtered POIs within 3km radius from current location
  /// Limits POIs based on zoom levels: 4, 8, 12, 16
  List<Poi> _getFilteredPois() {
    if (_currentLocation == null) return [];

    // Get POIs within 3km radius
    final nearbyPois = _pois.where((poi) {
      final distance = _calculateDistance(_currentLocation!, poi.position);
      return distance <= 3.0; // Only show POIs within 3km
    }).toList();

    // Determine max POIs based on zoom level
    int maxPois;
    if (_currentZoom < 4.0) {
      maxPois = 5; // Very zoomed out: show only 5 closest POIs
    } else if (_currentZoom < 8.0) {
      maxPois = 10; // Zoom level 4-7: show 10 closest POIs
    } else if (_currentZoom < 12.0) {
      maxPois = 15; // Zoom level 8-11: show 15 closest POIs
    } else if (_currentZoom < 16.0) {
      maxPois = 20; // Zoom level 12-15: show 20 closest POIs
    } else {
      return nearbyPois; // Zoom level 16+: show all POIs
    }

    // Limit and sort by distance if needed
    if (nearbyPois.length > maxPois) {
      nearbyPois.sort((a, b) {
        final distA = _calculateDistance(_currentLocation!, a.position);
        final distB = _calculateDistance(_currentLocation!, b.position);
        return distA.compareTo(distB);
      });
      return nearbyPois.take(maxPois).toList();
    }

    return nearbyPois;
  }

  /// Load nearby POIs (with state batching)
  Future<void> _loadNearbyPois(LatLng location) async {
    if (_isLoadingPois) return;

    // Batch setState calls
    if (mounted) {
      setState(() {
        _isLoadingPois = true;
      });
    }

    try {
      final pois = await _poiService.fetchNearbyPois(
        location, 
        _MapPerformanceConfig.maxPoiRadiusKm,
      );
      if (mounted) {
        setState(() {
          _pois = pois;
          _lastPoiLoadLocation = location;
          _isLoadingPois = false;
        });
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        setState(() {
          _isLoadingPois = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi tải điểm quan tâm: $e')),
        );
      }
    }
  }

  /// Get current user location
  Future<void> _getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Location services are not enabled, show message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Vui lòng bật dịch vụ định vị GPS'),
              action: SnackBarAction(
                label: 'Cài đặt',
                onPressed: () async {
                  await Geolocator.openLocationSettings();
                },
              ),
            ),
          );
        }
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        // Show explanation dialog before requesting permission
        if (mounted) {
          await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Yêu cầu quyền truy cập vị trí'),
                content: const Text(
                  'Ứng dụng cần quyền truy cập vị trí để hiển thị vị trí của bạn trên bản đồ. '
                  'Bạn có muốn cấp quyền này không?'
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Không'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Có'),
                  ),
                ],
              );
            },
          );
        }

        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // Permissions are denied
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Quyền truy cập vị trí bị từ chối'),
                action: SnackBarAction(
                  label: 'Cài đặt',
                  onPressed: () async {
                    await Geolocator.openAppSettings();
                  },
                ),
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // Permissions are denied forever
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Quyền truy cập vị trí bị từ chối vĩnh viễn. Vui lòng cấp quyền trong cài đặt.'),
              action: SnackBarAction(
                label: 'Cài đặt',
                onPressed: () async {
                  await Geolocator.openAppSettings();
                },
              ),
            ),
          );
        }
        return;
      }

      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đang lấy vị trí...')));
      }

      // Get current position with timeout
      Position position =
          await Geolocator.getCurrentPosition(
            // ignore: deprecated_member_use
            desiredAccuracy: LocationAccuracy.high,
            // ignore: deprecated_member_use
            timeLimit: const Duration(seconds: 10), // Add timeout
          ).timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw TimeoutException('Timeout khi lấy vị trí');
            },
          );

      final newLocation = LatLng(position.latitude, position.longitude);
      final shouldReload = _shouldReloadPois(newLocation);

      // Batch all state updates together
      if (mounted) {
        setState(() {
          _currentLocation = newLocation;
        });

        // Move map to current location
        _mapController.move(_currentLocation!, 15.0);

        // Load nearby POIs if location changed significantly
        if (shouldReload) {
          _loadNearbyPois(_currentLocation!);
        }

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật vị trí hiện tại'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      String errorMessage = 'Lỗi khi lấy vị trí';

      if (e is TimeoutException) {
        errorMessage = 'Quá thời gian chờ lấy vị trí. Vui lòng thử lại.';
      } else if (e.toString().contains('Location service disabled')) {
        errorMessage = 'Dịch vụ định vị bị tắt. Vui lòng bật GPS.';
      } else if (e.toString().contains('Permission denied')) {
        errorMessage = 'Quyền truy cập vị trí bị từ chối.';
      } else {
        errorMessage = 'Lỗi không xác định: ${e.toString()}';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            action: SnackBarAction(label: 'Thử lại', onPressed: _getCurrentLocation),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Pre-calculate filtered POIs to avoid rebuilding in the tree
    final filteredPois = _getFilteredPois();
    
    return Scaffold(
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _initialCenter,
          initialZoom: _currentZoom,
          minZoom: 1.0,
          maxZoom: 18.0,
          // Enable rotation and other interactions
          interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
        ),
        children: [
          // Map Tiler tile layer
          TileLayer(
            urlTemplate: 'https://api.maptiler.com/maps/streets/{z}/{x}/{y}.png?key=$_apiKey',
            additionalOptions: const {'apiKey': _apiKey},
          ),

          // Current location marker
          if (_currentLocation != null)
            MarkerLayer(
              markers: [
                Marker(
                  point: _currentLocation!,
                  child: const Icon(Icons.my_location, color: Colors.blue, size: 30),
                ),
              ],
            ),

          // POI markers (use pre-calculated list)
          if (filteredPois.isNotEmpty)
            MarkerLayer(
              markers: filteredPois.map((poi) {
                return _buildPoiMarker(poi);
              }).toList(),
            ),

          // Attribution widget (const)
          const RichAttributionWidget(
            attributions: [
              TextSourceAttribution('OpenStreetMap contributors'),
              TextSourceAttribution('Map Tiler'),
            ],
          ),
        ],
      ),

      // Floating action button to center map
      floatingActionButton: _buildLocationFab(),
    );
  }

  /// Build POI marker widget (extracted for optimization)
  Marker _buildPoiMarker(Poi poi) {
    IconData icon;
    Color color;

    switch (poi.type) {
      case 'restaurant':
        icon = Icons.restaurant;
        color = Colors.red;
        break;
      case 'cafe':
        icon = Icons.local_cafe;
        color = Colors.brown;
        break;
      case 'bar':
        icon = Icons.local_bar;
        color = Colors.purple;
        break;
      case 'fast_food':
        icon = Icons.fastfood;
        color = Colors.orange;
        break;
      default:
        icon = Icons.place;
        color = Colors.grey;
    }

    final markerSize = _getMarkerSize();

    return Marker(
      point: poi.position,
      child: GestureDetector(
        onTap: () => _showPoiDetails(poi),
        child: Icon(icon, color: color, size: markerSize),
      ),
    );
  }

  /// Show POI details dialog (extracted for clarity)
  void _showPoiDetails(Poi poi) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(poi.name),
        content: Text('Loại: ${poi.type}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  /// Build FAB widget (extracted)
  Widget _buildLocationFab() {
    return FloatingActionButton(
      onPressed: () {
        if (_currentLocation != null) {
          _mapController.move(_currentLocation!, 15.0);
        } else {
          _getCurrentLocation();
        }
      },
      tooltip: _currentLocation != null ? 'Vị trí của tôi' : 'Lấy vị trí',
      child: Icon(_currentLocation != null ? Icons.my_location : Icons.location_searching),
    );
  }
}