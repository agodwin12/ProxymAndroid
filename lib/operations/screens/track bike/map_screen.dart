import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;

class MapScreen extends StatefulWidget {
  final double longitude;
  final double latitude;
  final double speed;

  const MapScreen({
    Key? key,
    required this.longitude,
    required this.latitude,
    required this.speed,
  }) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController _mapController;
  BitmapDescriptor? _bikeIcon;

  @override
  void initState() {
    super.initState();
    _loadCustomBikeIcon();
  }

  /// Load bike icon from assets and convert to BitmapDescriptor
  Future<void> _loadCustomBikeIcon() async {
    final Uint8List markerIcon = await _getBytesFromAsset('assets/bike_icon.png', 100);
    setState(() {
      _bikeIcon = BitmapDescriptor.fromBytes(markerIcon);
    });
  }

  /// Convert asset image to Uint8List for custom markers
  Future<Uint8List> _getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    ByteData? byteData = await fi.image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  /// Move camera to bike location
  void _moveCamera() {
    _mapController.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(widget.latitude, widget.longitude),
        16.0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bike Location"),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(widget.latitude, widget.longitude),
              zoom: 16.0,
            ),
            markers: {
              if (_bikeIcon != null) // Only display marker if icon is loaded
                Marker(
                  markerId: const MarkerId("bike"),
                  position: LatLng(widget.latitude, widget.longitude),
                  infoWindow: InfoWindow(
                    title: "Bike Location",
                    snippet: "Speed: ${widget.speed} km/h",
                  ),
                  icon: _bikeIcon!,
                ),
            },
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              _moveCamera();
            },
          ),

          // Floating button to re-center the camera
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: _moveCamera,
              backgroundColor: Color(0xFFE0DC34),
              child: const Icon(Icons.my_location, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}
