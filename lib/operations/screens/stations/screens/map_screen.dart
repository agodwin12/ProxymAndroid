import 'dart:convert';
import 'dart:math';
import 'dart:async';  // Added for Completer

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';  // Added for more robust location handling
import 'package:url_launcher/url_launcher.dart';  // Added for launching phone app

class Station {
  final int id;
  final String name;
  final String address;
  final String phone;
  final double latitude;
  final double longitude;
  double distance;

  Station({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.latitude,
    required this.longitude,
    required this.distance,
  });

  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
      id: json['id'],
      name: json['nom_agence'],
      address: json['quartier'] ?? 'Unknown',
      phone: json['telephone'],
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
      distance: 0,
    );
  }

  String get formattedDistance {
    if (distance >= 1000) {
      return '${(distance / 1000).toStringAsFixed(1)} km';
    } else {
      return '${distance.toInt()} m';
    }
  }
}

class StationsMapPage extends StatefulWidget {
  final String userId;

  const StationsMapPage({super.key, required this.userId});

  @override
  State<StationsMapPage> createState() => _StationsMapPageState();
}

class _StationsMapPageState extends State<StationsMapPage> {
  final PanelController _panelController = PanelController();
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Completer<GoogleMapController> _controllerCompleter = Completer();

  final Color _themeColor = const Color(0xFFDCDB34);

  // Default location until we get user's real location
  LatLng _userLocation = const LatLng(6.5244, 3.3792); // Will be updated with real location

  bool _isLoading = true;
  bool _locationPermissionDenied = false;
  List<Station> _stations = [];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  // Get current location permission and position
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationPermissionDenied = true;
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationPermissionDenied = true;
          _isLoading = false;
        });
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });

      // Load stations after getting location
      loadStations();

      // Move camera to user location
      final GoogleMapController controller = await _controllerCompleter.future;
      controller.animateCamera(CameraUpdate.newLatLngZoom(_userLocation, 14));
    } catch (e) {
      print("Error getting location: $e");
      setState(() {
        _isLoading = false;
      });
      // Still load stations with default location if location fails
      loadStations();
    }
  }

  // Recenter map to user's current location
  Future<void> _centerOnUser() async {
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_userLocation, 15),
      );
    }
  }

  Future<List<Station>> fetchStations() async {
    const String apiUrl = 'http://10.0.2.2:5000/api/agences'; // replace with your IP

    print('📡 Sending GET request to $apiUrl');

    final response = await http.get(Uri.parse(apiUrl));
    print('🧾 Response status: ${response.statusCode}');
    print('📦 Response body: ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Station.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load stations');
    }
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double p = 0.017453292519943295;
    const double R = 6371000; // Earth radius in meters
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) *
            cos(lat2 * p) *
            (1 - cos((lon2 - lon1) * p)) /
            2;
    return R * 2 * asin(sqrt(a));
  }

  void loadStations() async {
    try {
      List<Station> fetched = await fetchStations();
      for (var station in fetched) {
        double dist = calculateDistance(
          _userLocation.latitude,
          _userLocation.longitude,
          station.latitude,
          station.longitude,
        );
        station.distance = dist;
      }

      fetched.sort((a, b) => a.distance.compareTo(b.distance));

      setState(() {
        _stations = fetched;
      });

      _setupMarkers();
    } catch (e) {
      print("Error loading stations: $e");
    }
  }

  void _setupMarkers() {
    _markers.clear();

    _markers.add(
      Marker(
        markerId: const MarkerId('user_location'),
        position: _userLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: 'Your Location'),
      ),
    );

    for (var station in _stations) {
      _markers.add(
        Marker(
          markerId: MarkerId('station_${station.id}'),
          position: LatLng(station.latitude, station.longitude),
          infoWindow: InfoWindow(
            title: station.name,
            snippet: '${station.address}, ${station.formattedDistance}',
          ),
          onTap: () {
            if (!_panelController.isPanelOpen) {
              _panelController.open();
            }
          },
        ),
      );
    }

    setState(() {});
  }

  // Function to launch phone dialer
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      // Show error message if unable to launch phone app
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch phone app')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Theme(
      data: ThemeData(
        primaryColor: _themeColor,
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
        colorScheme: ColorScheme.fromSeed(seedColor: _themeColor),
      ),
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              SlidingUpPanel(
                controller: _panelController,
                minHeight: screenHeight * 0.3,
                maxHeight: screenHeight * 0.85,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                parallaxEnabled: true,
                parallaxOffset: 0.5,
                body: Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _userLocation,
                        zoom: 14.0,
                      ),
                      markers: _markers,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false, // Disable default button as we'll add our own
                      zoomControlsEnabled: false, // Disable default zoom buttons as we'll add our own
                      onMapCreated: (GoogleMapController controller) {
                        _mapController = controller;
                        if (!_controllerCompleter.isCompleted) {
                          _controllerCompleter.complete(controller);
                        }
                      },
                    ),

                    // Loading indicator
                    if (_isLoading)
                      const Center(
                        child: CircularProgressIndicator(),
                      ),

                    // Location permission denied message
                    if (_locationPermissionDenied)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.location_off, size: 48, color: Colors.red),
                              const SizedBox(height: 16),
                              Text(
                                'Location Permission Denied',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Please enable location permissions in your device settings to find nearby stations.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(fontSize: 14),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () async {
                                  await Geolocator.openAppSettings();
                                },
                                child: Text(
                                  'Open Settings',
                                  style: GoogleFonts.poppins(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Back button at the top left
                    Positioned(
                      top: 16,
                      left: 16,
                      child: _buildFloatingButton(
                        icon: Icons.arrow_back,
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ),

                    // Map controls (right side)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Column(
                        children: [
                          _buildFloatingButton(
                            icon: Icons.add,
                            onPressed: () {
                              _mapController?.animateCamera(
                                CameraUpdate.zoomIn(),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          _buildFloatingButton(
                            icon: Icons.remove,
                            onPressed: () {
                              _mapController?.animateCamera(
                                CameraUpdate.zoomOut(),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          _buildFloatingButton(
                            icon: Icons.my_location,
                            onPressed: _centerOnUser,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                panel: _buildPanel(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build consistent floating buttons
  Widget _buildFloatingButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              color: _themeColor.darker(30),
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Drag handle
        Container(
          padding: const EdgeInsets.all(12),
          child: Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Nearby Stations',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF333333),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Slide up to see more stations',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _stations.isEmpty
              ? Center(
            child: _isLoading
                ? const CircularProgressIndicator()
                : Text(
              'No stations found',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _stations.length,
            itemBuilder: (context, index) {
              final station = _stations[index];
              return _buildStationCard(station, index == 0);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStationCard(Station station, bool isFirst) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isFirst ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isFirst
            ? BorderSide(color: _themeColor, width: 2)
            : BorderSide.none,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Distance and badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildBadge(Icons.near_me, station.formattedDistance),
                if (isFirst)
                  _buildBadge(Icons.check_circle, 'Closest', highlight: true),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              station.name,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    station.address,
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton(
                  icon: Icons.directions,
                  label: 'Directions',
                  onTap: () {
                    _mapController?.animateCamera(
                      CameraUpdate.newLatLngZoom(
                        LatLng(station.latitude, station.longitude),
                        16.0,
                      ),
                    );
                    if (_panelController.isPanelOpen) {
                      _panelController.close();
                    }
                  },
                ),
                _buildActionButton(
                  icon: Icons.call,
                  label: 'Call',
                  onTap: () {
                    _makePhoneCall(station.phone);
                  },
                ),
                _buildActionButton(
                  icon: Icons.share,
                  label: 'Share',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Sharing ${station.name}')),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(IconData icon, String label, {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: highlight ? _themeColor.withOpacity(0.2) : _themeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: _themeColor.darker(30)),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: _themeColor.darker(30),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Icon(icon, color: Colors.black, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension ColorExtension on Color {
  Color darker(int percent) {
    assert(1 <= percent && percent <= 100);
    final f = 1 - percent / 100;
    return Color.fromARGB(
      alpha,
      (red * f).round(),
      (green * f).round(),
      (blue * f).round(),
    );
  }
}