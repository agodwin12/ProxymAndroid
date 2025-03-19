import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:proxymapp/operations/models/electric_bike.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

// Import the model from the dedicated model file
import '../equipement details/equipement_details.dart';

class MyEquipmentScreen extends StatefulWidget {
  final String userId;

  const MyEquipmentScreen({Key? key, required this.userId}) : super(key: key);
  @override
  State<MyEquipmentScreen> createState() => _MyEquipmentScreenState();
}

class _MyEquipmentScreenState extends State<MyEquipmentScreen> {
  List<ElectricBike> _bikes = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchBikes();
  }

  Future<void> _fetchBikes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final String userId = widget.userId;
      final String apiUrl = "http://57.128.178.119:8081/api/user/bike-battery/$userId";

      print("🚀 Fetching bike details for userId: $userId");
      print("🔗 API URL: $apiUrl");

      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print("✅ API Response: $data");

        setState(() {
          _bikes = [ElectricBike.fromJson(data)];
          _isLoading = false;
        });
      } else {
        print("❌ Failed to load bike data. Status Code: ${response.statusCode}");
        throw Exception("Failed to load bike data");
      }
    } catch (error) {
      print("🚨 Error fetching bikes: $error");
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  void _handleBikeTap(ElectricBike bike) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EquipmentDetailsPage(
          bike: bike,
          userId: widget.userId,  // Ensure userId is passed
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),

            Expanded(
              child: _isLoading
                  ? Center(
                child: CircularProgressIndicator(
                  color: const Color(0xFFDCDB32),
                ),
              )
                  : _hasError
                  ? _buildErrorState()
                  : _bikes.isEmpty
                  ? _buildEmptyState()
                  : _buildBikesList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Equipment',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'View and manage your bikes',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: _fetchBikes,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.refresh,
                color: const Color(0xFFDCDB32),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 60,
            color: Colors.red.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            "Failed to load data",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _fetchBikes,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDCDB32),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Try Again',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.electric_bike,
            size: 60,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            "No bikes found",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBikesList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      itemCount: _bikes.length,
      itemBuilder: (context, index) {
        final bike = _bikes[index];
        return BikeCard(
          bike: bike,
          onTap: () => _handleBikeTap(bike),
        );
      },
    );
  }
}

class BikeCard extends StatelessWidget {
  final ElectricBike bike;
  final VoidCallback onTap;

  const BikeCard({Key? key, required this.bike, required this.onTap}) : super(key: key);

  // Calculate SoC using the provided formula
  int _calculateSoC(int rawValue) {
    return ((rawValue - 7) * 100 / (100 - 7)).clamp(0, 100).toInt();
  }

  Color _getBatteryColor(int percentage) {
    if (percentage < 30) return Colors.red;
    if (percentage < 50) return Colors.yellow.shade700;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    // Calculate the battery percentage using the formula
    final calculatedPercentage = _calculateSoC(bike.batteryPercentage);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(35),
                  ),
                  child: Icon(
                    bike.icon,
                    size: 40,
                    color: const Color(0xFFDCDB32),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bike.name,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Model: ${bike.model}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'VIN: ${bike.vin.substring(0, min(bike.vin.length, 10))}...',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.black45,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.battery_charging_full,
                  size: 20,
                  color: _getBatteryColor(calculatedPercentage),
                ),
                const SizedBox(width: 8),
                Text(
                  'Battery:',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: calculatedPercentage / 100,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getBatteryColor(calculatedPercentage),
                      ),
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$calculatedPercentage%',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _getBatteryColor(calculatedPercentage),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  int min(int a, int b) {
    return a < b ? a : b;
  }
}