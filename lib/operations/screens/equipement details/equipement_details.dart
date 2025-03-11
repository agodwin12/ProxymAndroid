import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:proxymapp/operations/models/electric_bike.dart';

// Import the centralized model file
import '../battery track/battery_tracking_page.dart';
import '../custom nav bar/custombottomnavbar.dart';
import '../user profile/profilescreen.dart';

class EquipmentDetailsPage extends StatefulWidget {
  final ElectricBike? bike;  // Make it nullable with the ? operator // Using the shared ElectricBike model
  final String userId;

  const EquipmentDetailsPage({
    Key? key,
     this.bike,
    required this.userId,
  }) : super(key: key);

  @override
  State<EquipmentDetailsPage> createState() => _EquipmentDetailsPageState();
}

class _EquipmentDetailsPageState extends State<EquipmentDetailsPage> with SingleTickerProviderStateMixin {
  bool isBatteryOn = false;
  double batteryPercentage = 0.0;
  String macId = "Fetching...";
  double? latitude;
  double? longitude;
  late AnimationController _animationController;
  late Animation<double> _glowAnimation;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 1.0, end: 2.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _fetchBatteryDetails();
  }

  Future<void> _fetchBatteryDetails() async {
    try {
      final String apiUrl = "http://10.0.2.2:5000/api/user/battery-details/${widget.userId}";

      print("🚀 Fetching battery details for userId: ${widget.userId}");
      print("🔗 API URL: $apiUrl");

      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print("✅ API Response: $data");

        setState(() {
          macId = data['battery']['mac_id'].toString();

          // Get the raw SOC value from the API
          double socDbValue = double.tryParse(data['battery']['soc'].toString()) ?? 0.0;

          // Apply the formula to adjust the SOC display value
          // soc = ((socDbValue - 7) * 100 / (100 - 7)).clamp(0, 100).toInt();
          batteryPercentage = ((socDbValue - 7) * 100 / (100 - 7)).clamp(0, 100);

          isBatteryOn = data['battery']['dhon'] == 1;

          latitude = data['battery']['latitude'] != null ? double.tryParse(data['battery']['latitude'].toString()) : null;
          longitude = data['battery']['longitude'] != null ? double.tryParse(data['battery']['longitude'].toString()) : null;

          print("📍 Latitude: $latitude, Longitude: $longitude");
          print("🔋 Raw SOC: $socDbValue, Adjusted SOC: $batteryPercentage");
        });
      } else {
        print("❌ Failed to load battery details. Status Code: ${response.statusCode}");
        setState(() {
          macId = "Error fetching data";
        });
      }
    } catch (error) {
      print("🚨 Error fetching battery details: $error");
      setState(() {
        macId = "Network error";
      });
    }
  }

  Future<void> _sendDischargeCommand(bool enableDischarge) async {
    final String apiUrl = "http://10.0.2.2:5000/api/battery/command/$macId";

    final String command = enableDischarge ? "discharge_on" : "discharge_off";

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"param": command}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        print("✅ Command sent successfully: ${responseData['message']}");

        // Show success snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Discharge mode ${enableDischarge ? 'activated' : 'deactivated'} successfully"),
            backgroundColor: enableDischarge ? Colors.green : Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } else {
        print("❌ Failed to send command. Status: ${response.statusCode}");

        // Show error snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to change discharge mode"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (error) {
      print("🚨 Error sending discharge command: $error");

      // Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error sending command: $error"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void toggleBattery() {
    _showConfirmationDialog(!isBatteryOn);
  }

  // Show confirmation dialog before toggling discharge mode
  void _showConfirmationDialog(bool newState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Confirm Action",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        content: Text(
          "Are you sure you want to turn ${newState ? 'ON' : 'OFF'} the discharge mode?",
          style: GoogleFonts.poppins(
            color: Colors.white70,
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "Cancel",
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                  ),
                ),
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    isBatteryOn = newState;
                  });
                  _sendDischargeCommand(newState);
                  Navigator.pop(context);
                },
                child: Text(
                  "Confirm",
                  style: GoogleFonts.poppins(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: newState ? Colors.green : Colors.orange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Color getBatteryColor() {
    if (batteryPercentage < 30) {
      return Colors.red;
    } else if (batteryPercentage < 50) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    String currentDate = DateFormat('MMMM d, yyyy').format(DateTime.now());
    final screenSize = MediaQuery.of(context).size;
    // Adding bottom padding to account for floating navigation bar
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true, // Important for floating bottom bar
      appBar: AppBar(
        title: Text(
          'Battery Monitor',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.black,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 20.0 + bottomPadding + 80), // Adding extra padding at bottom for floating nav bar
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: screenSize.height - 150),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Date and MAC ID
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.grey[900]?.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      Text(
                        currentDate,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.bluetooth, color: Colors.blue, size: 18),
                          const SizedBox(width: 5),
                          Text(
                            'MAC ID: $macId',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Enhanced circular progress indicator
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer glow
                    AnimatedBuilder(
                      animation: _glowAnimation,
                      builder: (context, child) {
                        return Container(
                          height: 300,
                          width: 300,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black,
                            boxShadow: [
                              BoxShadow(
                                color: getBatteryColor().withOpacity(0.3 * _glowAnimation.value),
                                blurRadius: 25 * _glowAnimation.value,
                                spreadRadius: 7 * _glowAnimation.value,
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    // Modern circular progress indicator
                    SizedBox(
                      width: 240,
                      height: 240,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Background circle
                          Container(
                            width: 240,
                            height: 240,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey[900]?.withOpacity(0.3),
                            ),
                          ),

                          // Progress circle
                          SizedBox(
                            width: 240,
                            height: 240,
                            child: CircularProgressIndicator(
                              value: batteryPercentage / 100,
                              strokeWidth: 15,
                              backgroundColor: Colors.grey[800]?.withOpacity(0.5),
                              valueColor: AlwaysStoppedAnimation<Color>(getBatteryColor()),
                            ),
                          ),

                          // Inner circle with percentage
                          Container(
                            width: 190,
                            height: 190,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey[900],
                              border: Border.all(
                                color: getBatteryColor().withOpacity(0.5),
                                width: 2,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.battery_charging_full_rounded,
                                  size: 40,
                                  color: getBatteryColor(),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  '${batteryPercentage.toInt()}%',
                                  style: GoogleFonts.poppins(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Battery Level',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 50),

                // Double infinity Track Battery button
                Container(
                  width: double.infinity,
                  height: 60,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: LinearGradient(
                      colors: [
                        getBatteryColor().withOpacity(0.7),
                        getBatteryColor(),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: getBatteryColor().withOpacity(0.4),
                        blurRadius: 10,
                        spreadRadius: 0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (latitude != null && longitude != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BatteryTrackingPage(
                              latitude: latitude!,
                              longitude: longitude!,
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "Battery location not available",
                              style: GoogleFonts.poppins(),
                            ),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.location_on),
                    label: Text(
                      'Track Battery',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.black,
                      shadowColor: Colors.transparent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Modernized toggle with label on one side and switch on the other
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[900]?.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: getBatteryColor().withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Label side
                      Row(
                        children: [
                          Icon(
                            isBatteryOn ? Icons.power : Icons.power_off_outlined,
                            color: isBatteryOn ? Colors.green : Colors.red,
                            size: 24,
                          ),
                          const SizedBox(width: 15),
                          Text(
                            'Discharge Mode',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),

                      // Toggle switch
                      Switch(
                        value: isBatteryOn,
                        onChanged: (value) => toggleBattery(),
                        activeColor: getBatteryColor(),
                        activeTrackColor: getBatteryColor().withOpacity(0.3),
                        inactiveThumbColor: Colors.grey,
                        inactiveTrackColor: Colors.grey.withOpacity(0.3),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 15),

                // Status indicator
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: isBatteryOn ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: isBatteryOn ? Colors.green.withOpacity(0.5) : Colors.red.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    isBatteryOn ? "Discharge Mode is ON ✅" : "Discharge Mode is OFF ❌",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isBatteryOn ? Colors.green : Colors.red,
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
      // Using the custom bottom navigation bar
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 0, // Battery tab
        userId: widget.userId,
        activeColor: getBatteryColor(),
      ),
    );
  }
}