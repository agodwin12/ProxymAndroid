import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';

class PersonalDetailsScreen extends StatefulWidget {
  final String userId;

  const PersonalDetailsScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<PersonalDetailsScreen> createState() => _PersonalDetailsScreenState();
}

class _PersonalDetailsScreenState extends State<PersonalDetailsScreen> {
  Map<String, dynamic>? userData;
  bool _isLoading = true;
  bool _isEditing = false;

  // Controllers for password form
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // Form key for validation
  final _passwordFormKey = GlobalKey<FormState>();

  // Password visibility toggles
  bool _oldPasswordVisible = false;
  bool _newPasswordVisible = false;
  bool _confirmPasswordVisible = false;

  // Loading state for password change
  bool _isChangingPassword = false;

  // Theme colors
  final Color _backgroundColor = Colors.black;
  final Color _tealColor = Color(0xFFE0DC34);
  final Color _darkCardColor = Color(0xFF121212);
  final Color _textColor = Colors.white;
  final Color _subtextColor = Colors.grey[400]!;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> fetchUserData() async {
    try {
      const String apiUrl = "http://10.0.2.2:5000/api/personal-info/";
      final response = await http.get(Uri.parse("$apiUrl${widget.userId}"));

      if (response.statusCode == 200) {
        setState(() {
          userData = json.decode(response.body);
          _isLoading = false;
        });
        print("✅ User data fetched successfully: $userData");
      } else {
        print("🟠 Error fetching data: ${response.statusCode}");
        setState(() {
          _isLoading = false;
        });
      }
    } catch (error) {
      print("🔴 Network error: $error");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _changePassword() async {
    if (_passwordFormKey.currentState!.validate()) {
      setState(() {
        _isChangingPassword = true;
      });

      try {
        const String apiUrl = "http://10.0.2.2:5000/api/change-password";
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'userId': widget.userId,
            'oldPassword': _oldPasswordController.text,
            'newPassword': _newPasswordController.text,
          }),
        );

        setState(() {
          _isChangingPassword = false;
        });

        Navigator.pop(context); // Close the dialog

        if (response.statusCode == 200) {
          _showSnackBar('Password changed successfully!', _tealColor);
          _oldPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
        } else {
          final errorMsg = json.decode(response.body)['message'] ?? 'Failed to change password';
          _showSnackBar(errorMsg, Colors.red);
        }
      } catch (error) {
        setState(() {
          _isChangingPassword = false;
        });
        Navigator.pop(context);
        _showSnackBar('Network error. Please try again later.', Colors.red);
        print("🔴 Password change error: $error");
      }
    }
  }

  void _logout() {
    // Simply navigate to login screen
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);

    // You can add any additional client-side cleanup here if needed
    // For example, clearing any cached data or shared preferences

    // Optionally show a success message
    _showSnackBar('Logged out successfully', Colors.red);
  }

  void _showPasswordChangeDialog() {
    // Reset controllers
    _oldPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();

    // Reset visibility
    _oldPasswordVisible = false;
    _newPasswordVisible = false;
    _confirmPasswordVisible = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: _darkCardColor,
              title: Text(
                'Change Password',
                style: TextStyle(
                  color: _tealColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Form(
                key: _passwordFormKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildPasswordField(
                        controller: _oldPasswordController,
                        label: 'Current Password',
                        isVisible: _oldPasswordVisible,
                        toggleVisibility: () {
                          setDialogState(() {
                            _oldPasswordVisible = !_oldPasswordVisible;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your current password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildPasswordField(
                        controller: _newPasswordController,
                        label: 'New Password',
                        isVisible: _newPasswordVisible,
                        toggleVisibility: () {
                          setDialogState(() {
                            _newPasswordVisible = !_newPasswordVisible;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a new password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildPasswordField(
                        controller: _confirmPasswordController,
                        label: 'Confirm New Password',
                        isVisible: _confirmPasswordVisible,
                        toggleVisibility: () {
                          setDialogState(() {
                            _confirmPasswordVisible = !_confirmPasswordVisible;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your new password';
                          }
                          if (value != _newPasswordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'CANCEL',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _tealColor,
                    foregroundColor: Colors.white,
                    elevation: 8,
                    shadowColor: _tealColor.withOpacity(0.5),
                  ),
                  onPressed: _isChangingPassword ? null : _changePassword,
                  child: _isChangingPassword
                      ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : Text('UPDATE'),
                ),
              ],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              contentPadding: EdgeInsets.fromLTRB(24, 20, 24, 0),
              buttonPadding: EdgeInsets.symmetric(horizontal: 16),
            );
          },
        );
      },
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool isVisible,
    required Function toggleVisibility,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !isVisible,
      validator: validator,
      style: TextStyle(color: _textColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade700, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _tealColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            isVisible ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey,
          ),
          onPressed: () => toggleVisibility(),
        ),
        filled: true,
        fillColor: Colors.grey[900],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        elevation: 0,
        title: Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: _textColor,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: _tealColor),
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              fetchUserData();
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          color: _tealColor,
          strokeWidth: 2,
        ),
      )
          : SafeArea(
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile header
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: _darkCardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: _tealColor.withOpacity(0.2),
                        blurRadius: 15,
                        spreadRadius: 1,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              _tealColor.withOpacity(0.9),
                              _tealColor.withOpacity(0.7),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _tealColor.withOpacity(0.5),
                              blurRadius: 15,
                              spreadRadius: 2,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _getInitials(),
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        "${userData?['prenom'] ?? ''} ${userData?['nom'] ?? ''}",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _textColor,
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getStatusColor(userData?['status'] ?? '').withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: _getStatusColor(userData?['status'] ?? '').withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.circle,
                              size: 12,
                              color: _getStatusColor(userData?['status'] ?? ''),
                            ),
                            SizedBox(width: 6),
                            Text(
                              (userData?['status'] ?? '').toUpperCase(),
                              style: TextStyle(
                                color: _getStatusColor(userData?['status'] ?? ''),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24),

                _buildSectionTitle("Account Information"),
                SizedBox(height: 12),

                // Account Information
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _darkCardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: _tealColor.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 0,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildInfoItem(
                        icon: Icons.badge,
                        iconColor: _tealColor,
                        title: 'User ID',
                        value: userData?['user_unique_id'] ?? '',
                      ),
                      SizedBox(height: 16),
                      _buildInfoItem(
                        icon: Icons.email,
                        iconColor: _tealColor,
                        title: 'Email',
                        value: userData?['email'] ?? '',
                      ),
                      SizedBox(height: 16),
                      _buildInfoItem(
                        icon: Icons.phone,
                        iconColor: _tealColor,
                        title: 'Phone',
                        value: userData?['phone'] ?? '',
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24),

                _buildSectionTitle("Personal Information"),
                SizedBox(height: 12),

                // Personal Information
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _darkCardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: _tealColor.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 0,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildInfoItem(
                        icon: Icons.person,
                        iconColor: _tealColor,
                        title: 'First Name',
                        value: userData?['prenom'] ?? '',
                      ),
                      SizedBox(height: 16),
                      _buildInfoItem(
                        icon: Icons.person,
                        iconColor: _tealColor,
                        title: 'Last Name',
                        value: userData?['nom'] ?? '',
                      ),
                      SizedBox(height: 16),
                      _buildInfoItem(
                        icon: Icons.credit_card,
                        iconColor: _tealColor,
                        title: 'CNI Number',
                        value: userData?['numero_cni'] ?? '',
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 32),

                // Actions
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _darkCardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: _tealColor.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 0,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Actions",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _textColor,
                        ),
                      ),
                      SizedBox(height: 16),
                      _buildActionButton(
                        icon: Icons.lock,
                        title: "Change Password",
                        color: _tealColor,
                        onTap: _showPasswordChangeDialog,
                      ),
                      SizedBox(height: 10),
                      _buildActionButton(
                        icon: Icons.logout,
                        title: "Logout",
                        color: Colors.red,
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: _darkCardColor,
                              title: Text('Logout', style: TextStyle(color: _textColor)),
                              content: Text('Are you sure you want to logout?', style: TextStyle(color: _subtextColor)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('CANCEL', style: TextStyle(color: Colors.grey)),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _logout();
                                  },
                                  child: Text(
                                    'LOGOUT',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getInitials() {
    final firstName = userData?['prenom'] ?? '';
    final lastName = userData?['nom'] ?? '';

    String initials = '';
    if (firstName.isNotEmpty) {
      initials += firstName[0].toUpperCase();
    }
    if (lastName.isNotEmpty) {
      initials += lastName[0].toUpperCase();
    }

    return initials.isNotEmpty ? initials : 'U';
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: _tealColor,
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: iconColor.withOpacity(0.3),
                blurRadius: 6,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 20,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: _subtextColor,
                ),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: _textColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          border: Border.all(color: color.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 8,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: color,
              size: 22,
            ),
            SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: _textColor,
              ),
            ),
            Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[600],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'validé':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'suspended':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}