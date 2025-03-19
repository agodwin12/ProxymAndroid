import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:proxymapp/operations/screens/custom%20nav%20bar/custombottomnavbar.dart';
import 'package:proxymapp/operations/screens/miscellaneus/PersonalDetailsScreen/PersonalDetailsScreen.dart';
import 'package:proxymapp/operations/screens/miscellaneus/about%20app/about_app.dart';
import 'package:proxymapp/operations/screens/miscellaneus/contact%20us/contact_us.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;

  const ProfileScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isLoading = true;
  Map<String, dynamic> userProfile = {};
  bool isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    try {
      final String apiUrl = "http://57.128.178.119:8081/api/user/${widget.userId}";

      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        setState(() {
          userProfile = data['user'] ?? {};
          isLoading = false;
        });
      } else {
        print("❌ Failed to load user profile. Status Code: ${response.statusCode}");
        setState(() {
          isLoading = false;
        });
      }
    } catch (error) {
      print("🚨 Error fetching user profile: $error");
      setState(() {
        isLoading = false;
      });
    }
  }

  // Handle logout logic
  Future<void> _handleLogout() async {

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear stored session

    // Show confirmation dialog
    final bool shouldLogout = await _showLogoutConfirmationDialog();
    if (!shouldLogout) return;

    setState(() {
      isLoggingOut = true;
    });

    try {
      // Show loading indicator
      _showLoadingDialog();

      // Clear user session data
      await _clearUserSession();

      // Close loading dialog
      Navigator.of(context).pop();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Successfully logged out',
            style: GoogleFonts.poppins(
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(10),
        ),
      );

      // Navigate to login screen and clear navigation history
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);

    } catch (error) {
      // Close loading dialog if open
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      setState(() {
        isLoggingOut = false;
      });

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error logging out: ${error.toString()}',
            style: GoogleFonts.poppins(
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(10),
        ),
      );
    }
  }

  // Show a confirmation dialog before logging out
  Future<bool> _showLogoutConfirmationDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Sign Out',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: GoogleFonts.poppins(
            color: Colors.white70,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'CANCEL',
              style: GoogleFonts.poppins(
                color: Colors.grey,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'SIGN OUT',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    ) ?? false;
  }

  // Show loading dialog while logging out
  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        content: Row(
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.red.shade700),
            ),
            SizedBox(width: 20),
            Text(
              'Signing out...',
              style: GoogleFonts.poppins(
                color: Colors.white,
              ),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  // Clear user session data from device
  Future<void> _clearUserSession() async {
    final prefs = await SharedPreferences.getInstance();

    // Clear authentication token
    await prefs.remove('auth_token');

    // Clear user ID
    await prefs.remove('user_id');

    // Clear other user data
    await prefs.remove('user_data');
    await prefs.remove('user_email');
    await prefs.remove('remember_user');

    // Add artificial delay to simulate network request for logout
    await Future.delayed(Duration(milliseconds: 800));

    // Optional: log the logout on the server side
    try {
      final response = await http.post(
        Uri.parse('http://57.128.178.119:8081/api/logout'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'user_id': widget.userId}),
      );

      if (response.statusCode != 200) {
        print("⚠️ Server-side logout may not have completed: ${response.statusCode}");
      }
    } catch (e) {
      print("⚠️ Could not reach logout endpoint: $e");
      // Continue with local logout even if server logout fails
    }
  }

  Color getThemeColor() {
    return Color(0xFFE0DC34);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true,
      appBar: AppBar(
        title: Text(
          'My Profile',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.black,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? Center(
        child: CircularProgressIndicator(
          color: getThemeColor(),
        ),
      )
          : SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 20.0 + bottomPadding + 80),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: screenSize.height - 150),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Header with Avatar
                Center(
                  child: Column(
                    children: [
                      Container(
                        height: 120,
                        width: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: getThemeColor().withOpacity(0.8),
                            width: 4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: getThemeColor().withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          backgroundColor: Colors.grey[800],
                          child: Text(
                            userProfile['name']?.substring(0, 1).toUpperCase() ?? 'U',
                            style: GoogleFonts.poppins(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        userProfile['name'] ?? 'User Name',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        userProfile['email'] ?? 'user@example.com',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: getThemeColor().withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: getThemeColor().withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          'Member since ${userProfile['joinDate'] ?? 'N/A'}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: getThemeColor(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Statistics Cards
                Text(
                  'Statistics',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    _buildStatCard(
                      'Bikes',
                      '${userProfile['bikeCount'] ?? '0'}',
                      Icons.electric_bike_rounded,
                    ),

                    const SizedBox(width: 15),
                    _buildStatCard(
                      'KM',
                      '${userProfile['totalDistance'] ?? '0'}',
                      Icons.speed_rounded,
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // Account Settings Section
                Text(
                  'Account Settings',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 15),
                _buildSettingsCard(
                  'Personal Information',
                  'Update your personal details',
                  Icons.person_outline_rounded,
                      () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PersonalDetailsScreen(userId: widget.userId),
                      ),
                    );

                  },
                ),

                const SizedBox(height: 40),

                _buildSettingsCard(
                  'Contact Support',
                  'Get help from our support team',
                  Icons.support_agent_rounded,
                      () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ContactUsScreen()),
                    );
                  },
                ),

                _buildSettingsCard(
                  'About App',
                  'Version and legal information',
                  Icons.info_outline_rounded,
                      () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AboutAppScreen()),
                    );
                  },
                ),
                const SizedBox(height: 30),
                // Logout Button
                Container(
                  width: double.infinity,
                  height: 55,
                  margin: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.4),
                        blurRadius: 15,
                        spreadRadius: 1,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: isLoggingOut ? null : _handleLogout,
                    icon: isLoggingOut
                        ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.black,
                        strokeWidth: 2,
                      ),
                    )
                        : const Icon(
                      Icons.logout_rounded,
                      color: Colors.black,
                      size: 24,
                    ),
                    label: Text(
                      isLoggingOut ? 'Signing Out...' : 'Sign Out',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
      // Using the custom bottom navigation bar instead of the inline implementation
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 2, // Profile is the third tab (index 2)
        userId: widget.userId,
        activeColor: getThemeColor(),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: Colors.grey[900]?.withOpacity(0.5),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: getThemeColor().withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: getThemeColor(),
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey[900]?.withOpacity(0.3),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.grey[800]!.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: getThemeColor().withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: getThemeColor(),
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          color: Colors.grey[600],
          size: 16,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    );
  }
}