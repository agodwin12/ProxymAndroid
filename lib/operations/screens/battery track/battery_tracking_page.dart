import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:ui' as ui;
import 'dart:async';
import 'dart:typed_data';


class BatteryTrackingPage extends StatefulWidget {
  final double latitude;
  final double longitude;

  const BatteryTrackingPage({
    Key? key,
    required this.latitude,
    required this.longitude,
  }) : super(key: key);

  @override
  State<BatteryTrackingPage> createState() => _BatteryTrackingPageState();
}

class _BatteryTrackingPageState extends State<BatteryTrackingPage> {
  late GoogleMapController _mapController;
  late LatLng _batteryLocation;
  late LatLng _proximLocation;
  late Set<Marker> _markers = {};
  late Set<Polyline> _polylines = {};

  final Color polylineColor = const Color(0xFFDCDCB3);

  @override
  void initState() {
    super.initState();
    _batteryLocation = LatLng(widget.latitude, widget.longitude);
    _proximLocation = const LatLng(4.07691, 9.77118);
    _setupPolylines();
    _setupMarkers();
  }

  Future<void> _setupMarkers() async {
    BitmapDescriptor motorcycleIcon = await _createCustomMarker("🚀", "Battery");
    BitmapDescriptor buildingIcon = await _createCustomMarker("🏢", "PROXYM");

    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId("battery_location"),
          position: _batteryLocation,
          infoWindow: InfoWindow(
            title: "User Location",
            snippet: "Lat: ${widget.latitude}, Lng: ${widget.longitude}",
          ),
          icon: motorcycleIcon,
        ),
        Marker(
          markerId: const MarkerId("proxym_location"),
          position: _proximLocation,
          infoWindow: const InfoWindow(
            title: "PROXYM",
            snippet: "Company Building",
          ),
          icon: buildingIcon,
        ),
      };
    });
  }

  Future<BitmapDescriptor> _createCustomMarker(String emoji, String text) async {
    const double markerSize = 150;

    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..color = Colors.black;

    // Draw a circle
    canvas.drawCircle(
      const Offset(markerSize / 2, markerSize / 2),
      markerSize / 3,
      paint,
    );

    // Draw the emoji
    final TextPainter emojiPainter = TextPainter(
      text: TextSpan(
        text: emoji,
        style: const TextStyle(fontSize: 50),
      ),
      textDirection: TextDirection.ltr,
    );
    emojiPainter.layout();
    emojiPainter.paint(
      canvas,
      Offset((markerSize - emojiPainter.width) / 2, markerSize / 3 - 10),
    );

    // Draw the label
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(fontSize: 20, color: Colors.white),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset((markerSize - textPainter.width) / 2, markerSize / 1.5),
    );

    final ui.Picture picture = pictureRecorder.endRecording();
    final ui.Image image = await picture.toImage(markerSize.toInt(), markerSize.toInt());
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List bytes = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(bytes);
  }

  void _setupPolylines() {
    _polylines.add(
      Polyline(
        polylineId: const PolylineId("route"),
        points: [_batteryLocation, _proximLocation],
        color: polylineColor,
        width: 5,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Battery Location',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.black,
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _calculateCenterPoint(),
          zoom: _calculateZoomLevel(),
        ),
        markers: _markers,
        polylines: _polylines,
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
        },
      ),
    );
  }

  LatLng _calculateCenterPoint() {
    return LatLng(
      (_batteryLocation.latitude + _proximLocation.latitude) / 2,
      (_batteryLocation.longitude + _proximLocation.longitude) / 2,
    );
  }

  double _calculateZoomLevel() {
    double latDiff = (_batteryLocation.latitude - _proximLocation.latitude).abs();
    double lngDiff = (_batteryLocation.longitude - _proximLocation.longitude).abs();
    double maxDiff = latDiff > lngDiff ? latDiff : lngDiff;

    if (maxDiff > 1) return 9;
    if (maxDiff > 0.5) return 10;
    if (maxDiff > 0.1) return 11;
    if (maxDiff > 0.05) return 12;
    if (maxDiff > 0.01) return 13;
    return 14;
  }
}
