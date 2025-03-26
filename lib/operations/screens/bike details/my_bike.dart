import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async'; // Add this import for Timer

import 'package:proxymapp/operations/screens/custom%20nav%20bar/custombottomnavbar.dart';
import 'package:proxymapp/operations/screens/track%20bike/map_screen.dart';

class MyBikesScreen extends StatefulWidget {
  final String userId;

  const MyBikesScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<MyBikesScreen> createState() => _MyBikesScreenState();
}

class _MyBikesScreenState extends State<MyBikesScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> bikes = [];
  String userName = "User"; // Default name
  bool isBikeOn = false;
  bool isButtonDisabled = false; // Add this state variable for cooldown
  int _cooldownSeconds = 0; // Track remaining cooldown time

  // API URL (Update with your backend IP or domain)
  final String apiUrl = "http://10.0.2.2:5000/api/bike";

  @override
  void initState() {
    super.initState();
    // Fix duplicate call and sequence properly
    fetchUserName();
    fetchBikes().then((_) {
      if (bikes.isNotEmpty) {
        _fetchBikeStatus(); // Fetch status after fetching bike info
      }
    });
  }

  Future<void> fetchUserName() async {
    try {
      final response = await http.get(
        Uri.parse("http://10.0.2.2:5000/api/user/${widget.userId}"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data.containsKey("user") && data["user"].containsKey("name")) {
          setState(() {
            userName = data["user"]["name"];
          });
        }
      }
    } catch (e) {
      print("🚨 Error fetching user: $e");
    }
  }

  Future<void> fetchBikes() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse("$apiUrl/${widget.userId}"));
      print("📱 Fetching bikes - Response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        print("📱 Bikes response: ${response.body}");
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data.containsKey("bike")) {
          print("📱 Found bike: ${data["bike"]}");
          setState(() {
            bikes = [
              {
                'vin': data["bike"]["vin"] ?? "N/A",
                'moto_unique_id': data["bike"]["moto_unique_id"] ?? "N/A",
                'model': data["bike"]["model"] ?? "Unknown Model",
                'status': data["bike"]["status"] ?? "active",
                'gps_imei': data["bike"]["gps_imei"] ?? "N/A",
                // Make sure this field exists
              },
            ];
          });
          print("📱 Bike data processed: $bikes");
        } else {
          print("🚨 No bikes found for this user.");
        }
      } else {
        print("🚨 API Error: ${response.statusCode}");
      }
    } catch (e) {
      print("🚨 Error fetching bikes: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Color getThemeColor() {
    return Color(0xFFE0DC34);
  }

  // Show confirmation dialog and handle bike toggling
  void _confirmToggleBike() async {
    // If button is disabled, don't proceed
    if (isButtonDisabled) {
      print("❌ Button is disabled, ignoring toggle request");
      return;
    }

    // Fetch the latest status before sending command
    await _fetchBikeStatus();
    print("🔄 Current bike state before toggle: ${isBikeOn ? 'ON' : 'OFF'}");

    final bool willTurnOn = !isBikeOn;
    final String action = willTurnOn ? "ON" : "OFF";
    print("🔄 Will toggle bike to: $action");

    // Show confirmation dialog
    bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: getThemeColor().withOpacity(0.3), width: 2),
          ),
          title: Text(
            'Confirm Command',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to turn ${action.toLowerCase()} your bike?',
            style: GoogleFonts.poppins(color: Colors.white70),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: getThemeColor(),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Confirm',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );

    // If confirmed, send the command
    if (confirmed == true) {
      print("✅ User confirmed toggle, sending command");
      _sendBikeCommand(action);
    } else {
      print("❌ User canceled toggle");
    }
  }

  // Send the actual command and handle cooldown timer
  void _sendBikeCommand(String action) async {
    if (bikes.isEmpty ||
        bikes[0]['gps_imei'] == null ||
        bikes[0]['gps_imei'] == 'N/A') {
      print("❌ Missing GPS IMEI, cannot send command");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error: GPS IMEI not found',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Store the previous state to revert if needed
    final bool previousState = isBikeOn;
    final bool newState = action == "ON";

    // ✅ Step 1: Immediately update UI to reflect new state
    setState(() {
      isBikeOn = newState;
      isButtonDisabled = true;
      _cooldownSeconds = 5;
    });
    print("🔄 UI updated to: ${isBikeOn ? 'ON' : 'OFF'}");

    // ✅ Step 2: Start cooldown timer
    Timer.periodic(Duration(seconds: 1), (timer) {
      if (_cooldownSeconds > 0) {
        setState(() {
          _cooldownSeconds--;
        });
      } else {
        setState(() {
          isButtonDisabled = false;
        });
        timer.cancel();
      }
    });

    final String apiUrl = "http://10.0.2.2:5000/api/gps-command";

    try {
      print("🔄 Sending command: $action for IMEI: ${bikes[0]['gps_imei']}");

      final Map<String, dynamic> requestBody = {
        "macid": bikes[0]['gps_imei'],
        "action": action,
      };
      print("📤 Request body: $requestBody");

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      print("📡 Command response status: ${response.statusCode}");
      print("📡 Command response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Command Sent Successfully: ${data["message"] ?? "Bike power toggled"}',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          print("✅ Command sent successfully");
        } else {
          // Reset to previous state and show error
          setState(() {
            isBikeOn = previousState;
          });
          print("❌ API returned error: ${data["error"] ?? "Unknown error"}");

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to Send Command: ${data["error"] ?? "Unknown error"}',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        // Reset to previous state and show error
        setState(() {
          isBikeOn = previousState;
        });
        print("❌ HTTP error: ${response.statusCode}");

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'HTTP Error: ${response.statusCode}',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // Reset to previous state and show error
      setState(() {
        isBikeOn = previousState;
      });
      print("❌ Exception: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleCommandError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Reset UI on error
    setState(() {
      isBikeOn = !isBikeOn; // Reset to previous state
    });
  }

  void _trackBike() async {
    print("🛠️ Track Bike Button Pressed!");

    if (bikes.isEmpty || bikes[0]['gps_imei'] == null) {
      print("❌ No GPS IMEI available, cannot track.");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: No GPS IMEI available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final String gpsImei = bikes[0]['gps_imei'];
    final String apiUrl = "http://10.0.2.2:5000/api/bike/location/$gpsImei";

    print("🔍 Fetching location for GPS IMEI: $gpsImei");

    try {
      final response = await http.get(Uri.parse(apiUrl));
      print("📡 Location response: ${response.statusCode}");
      print("📡 Location response body: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data['success'] == true) {
          if (data['data'] == null) {
            print("🚨 No location data found!");
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('No location data found for this bike.'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }

          // ✅ Directly extract values without conversion
          final double longitude = data['data']['longitude'];
          final double latitude = data['data']['latitude'];
          final double speed = data['data']['speed'];

          print("✅ Location Data Received: ($latitude, $longitude), Speed: $speed km/h");

          if (!context.mounted) return;

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MapScreen(
                longitude: longitude,
                latitude: latitude,
                speed: speed,
              ),
            ),
          );

          print("🚀 Navigating to MapScreen!");
        } else {
          print("🚨 Error: ${data['message']}");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${data['message']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        print("🚨 HTTP error: ${response.statusCode}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('HTTP Error: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("🚨 Error fetching bike location: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }




  Future<void> _fetchBikeStatus() async {
    if (bikes.isEmpty || bikes[0]['gps_imei'] == null) {
      print("🚨 No bikes available to fetch status or missing GPS IMEI.");
      return;
    }

    final String gpsImei = bikes[0]['gps_imei'];
    final String apiUrl = "http://10.0.2.2:5000/api/gps-status?macid=$gpsImei";

    print("🔍 Fetching bike status for IMEI: $gpsImei");

    try {
      final response = await http.get(Uri.parse(apiUrl));
      print("📡 Status response code: ${response.statusCode}");
      print("📡 Status response body: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        print("📡 Status data structure: ${data.keys}");

        if (data.containsKey("success") && data["success"] == true) {
          final String status = data["status"] ?? "";
          print("✅ Raw status string: '$status'");

          // Properly handle different API response formats
          bool bikeState = false;

          // Try multiple possible formats
          if (status.length >= 3) {
            // Format 1: Third character indicates power state
            bikeState = status[2] == '1';
            print(
              "✅ Using format 1: Third digit (${status[2]}) for power state",
            );
          } else if (data.containsKey("power")) {
            // Format 2: Direct power state field
            bikeState =
                data["power"] == true ||
                data["power"] == "1" ||
                data["power"] == "on" ||
                data["power"] == "ON";
            print("✅ Using format 2: Direct power field: ${data["power"]}");
          } else if (data.containsKey("isOn")) {
            // Format 3: isOn field
            bikeState =
                data["isOn"] == true ||
                data["isOn"] == "1" ||
                data["isOn"] == "on" ||
                data["isOn"] == "ON";
            print("✅ Using format 3: isOn field: ${data["isOn"]}");
          } else {
            // Format 4: Just assume it's OFF for now to make UI work
            bikeState = false;
            print(
              "⚠️ Using format 4: Defaulting to OFF since no format matched",
            );
          }

          print("⚡ Setting bike state to: ${bikeState ? 'ON' : 'OFF'}");

          setState(() {
            isBikeOn = bikeState;
          });
        } else {
          print(
            "🚨 Error fetching status: ${data["error"] ?? "Unknown error"}",
          );
        }
      } else {
        print(
          "🚨 API Error: ${response.statusCode}, Response: ${response.body}",
        );
      }
    } catch (e) {
      print("🚨 Error fetching bike status: $e");
    }
  }

  // Manually toggle bike state for testing
  void _manualToggleBikeState() {
    setState(() {
      isBikeOn = !isBikeOn;
    });
    print("🔄 Manually toggled bike state to: ${isBikeOn ? 'ON' : 'OFF'}");

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Debug: Bike state manually set to ${isBikeOn ? 'ON' : 'OFF'}',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.purple,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true,
      appBar: AppBar(
        title: Text(
          'My Bikes',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.black,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () {
              fetchBikes().then((_) {
                if (bikes.isNotEmpty) {
                  _fetchBikeStatus();
                }
              });
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body:
          isLoading
              ? Center(child: CircularProgressIndicator(color: getThemeColor()))
              : bikes.isEmpty
              ? _buildEmptyState()
              : _buildBikeContent(),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 1,
        userId: widget.userId,
        activeColor: getThemeColor(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.electric_bike_outlined,
            size: 80,
            color: getThemeColor().withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            "No bikes found",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "You don't have any bikes registered yet",
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildBikeContent() {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20.0,
          20.0,
          20.0,
          20.0 + bottomPadding + 80,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title with owner name
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bike belonging to',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  Text(
                    userName,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: getThemeColor(),
                    ),
                  ),
                ],
              ),
            ),

            // Bike Card
            ..._buildExpandedBikeCard(bikes[0]),

            const SizedBox(height: 30),

            // Track Bike Button
            Container(
              width: double.infinity,
              height: 55,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: getThemeColor().withOpacity(0.4),
                    blurRadius: 15,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () async {
                  print("🛠️ Track Bike Button Pressed!");

                  // ✅ Ensure bike exists and has GPS IMEI
                  if (bikes.isEmpty || bikes[0]['gps_imei'] == null) {
                    print("❌ No GPS IMEI available, cannot track.");
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: No GPS IMEI available'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  final String gpsImei = bikes[0]['gps_imei'];
                  final String apiUrl = "http://10.0.2.2:5000/api/bike/location/$gpsImei";

                  print("🔍 Fetching location for GPS IMEI: $gpsImei");

                  try {
                    final response = await http.get(Uri.parse(apiUrl));
                    print("📡 Location response: ${response.statusCode}");
                    print("📡 Location response body: ${response.body}");

                    if (response.statusCode == 200) {
                      final Map<String, dynamic> data = jsonDecode(response.body);

                      if (data['success'] == true) {
                        // ✅ Ensure 'data' key exists and contains required values
                        if (data['data'] == null ||
                            !data['data'].containsKey('longitude') ||
                            !data['data'].containsKey('latitude') ||
                            !data['data'].containsKey('speed')) {
                          print("🚨 Location data missing!");
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: Incomplete location data.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        // ✅ Convert values safely (handle both string & double cases)
                        final double longitude = (data['data']['longitude'] is String)
                            ? double.tryParse(data['data']['longitude']) ?? 0.0
                            : (data['data']['longitude'] ?? 0.0).toDouble();

                        final double latitude = (data['data']['latitude'] is String)
                            ? double.tryParse(data['data']['latitude']) ?? 0.0
                            : (data['data']['latitude'] ?? 0.0).toDouble();

                        final double speed = (data['data']['speed'] is String)
                            ? double.tryParse(data['data']['speed']) ?? 0.0
                            : (data['data']['speed'] ?? 0.0).toDouble();

                        print("✅ Location Data Received: ($latitude, $longitude), Speed: $speed km/h");

                        if (!context.mounted) return;

                        // ✅ Navigate to MapScreen with location data
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MapScreen(
                              longitude: longitude,
                              latitude: latitude,
                              speed: speed,
                            ),
                          ),
                        );

                        print("🚀 Navigating to MapScreen!");
                      } else {
                        print("🚨 API Error: ${data['message']}");
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: ${data['message']}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } else {
                      print("🚨 HTTP error: ${response.statusCode}");
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('HTTP Error: ${response.statusCode}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } catch (e) {
                    print("🚨 Error fetching bike location: $e");
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.location_searching, size: 24),
                label: Text(
                  'Track Bike',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: getThemeColor(),
                  foregroundColor: Colors.black,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),


            ),



            // Toggle Bike Button with Cooldown Timer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color:
                      isBikeOn
                          ? Colors.green.withOpacity(0.3)
                          : Colors.red.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isBikeOn ? Colors.green : Colors.red).withOpacity(
                      0.2,
                    ),
                    blurRadius: 10,
                    spreadRadius: 0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isBikeOn
                                ? Icons.power_settings_new_rounded
                                : Icons.power_off_rounded,
                            color: isBikeOn ? Colors.green : Colors.red,
                            size: 24,
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'Bike Power (${isBikeOn ? "ON" : "OFF"})',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Switch(
                        value: isBikeOn,
                        onChanged:
                            isButtonDisabled
                                ? null
                                : (value) => _confirmToggleBike(),
                        activeColor: Colors.green,
                        activeTrackColor: Colors.green.withOpacity(0.3),
                        inactiveThumbColor: Colors.red,
                        inactiveTrackColor: Colors.red.withOpacity(0.3),
                      ),
                    ],
                  ),

                  // Cooldown timer display (only visible during cooldown)
                  if (isButtonDisabled)
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.timer, color: Colors.amber, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Cooldown: $_cooldownSeconds seconds',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.amber,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Show the API response status
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),


                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildExpandedBikeCard(Map<String, dynamic> bike) {
    return [
      // Bike model card with image
      Container(
        width: double.infinity,
        height: 180,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: getThemeColor().withOpacity(0.2),
              blurRadius: 15,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Gradient overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                  ),
                ),
              ),
            ),
            // Electric bike icon centered
            Center(
              child: Icon(
                Icons.electric_bike_rounded,
                size: 80,
                color: getThemeColor().withOpacity(0.6),
              ),
            ),
            // Model name
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bike['model'],
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      bike['status']?.toUpperCase() ?? 'ACTIVE',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // Bike ID Card
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: getThemeColor().withOpacity(0.2), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: getThemeColor().withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.tag_rounded, color: getThemeColor(), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Unique ID',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  Text(
                    bike['moto_unique_id'],
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // VIN Card
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: getThemeColor().withOpacity(0.2), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: getThemeColor().withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.fiber_pin_rounded,
                color: getThemeColor(),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vehicle Identification Number (VIN)',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  Text(
                    bike['vin'],
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ];
  }
}
