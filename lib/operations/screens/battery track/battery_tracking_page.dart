import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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

  @override
  void initState() {
    super.initState();
    _batteryLocation = LatLng(widget.latitude, widget.longitude);
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
          target: _batteryLocation,
          zoom: 15, // Zoom level
        ),
        markers: {
          Marker(
            markerId: MarkerId("battery_location"),
            position: _batteryLocation,
            infoWindow: InfoWindow(
              title: "Battery Location",
              snippet: "Lat: ${widget.latitude}, Lng: ${widget.longitude}",
            ),
          ),
        },
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
        },
      ),
    );
  }
}
