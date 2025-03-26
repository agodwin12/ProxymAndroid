import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../my equipements/my_equipements.dart';

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);



  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _keepMeLoggedIn = false;
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }


  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    final String apiUrl = "http://10.0.2.2:5000/api/auth/login";

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "identifier": _emailController.text.trim(),
          "password": _passwordController.text.trim(),
          "keepMeLoggedIn": _keepMeLoggedIn,
        }),
      );

      print("🔍 Status Code: ${response.statusCode}");
      print("📥 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print("✅ Login successful! Token: ${responseData["token"]}");

        final SharedPreferences prefs = await SharedPreferences.getInstance();

        // Only save session if "Keep me logged in" is selected
        if (_keepMeLoggedIn) {
          await prefs.setString("token", responseData["token"]);
          await prefs.setString("user_unique_id", responseData["user"]["user_unique_id"]);
          print("✅ Session saved successfully.");
        }

        if (!mounted) return;

        // ✅ Navigate to MyEquipmentScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MyEquipmentScreen(userId: responseData["user"]["user_unique_id"]),
          ),
        );
      } else {
        final responseData = jsonDecode(response.body);
        print("❌ Login failed: ${responseData["message"]}");

        if (!mounted) return;
        _showErrorDialog(responseData["message"] ?? "Login failed");
      }
    } catch (error) {
      print("🚨 Network error: $error");

      if (!mounted) return;
      _showErrorDialog("Login failed. Please check your internet connection.");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text("Login Failed"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _navigateToSignUp() {
    Navigator.pushNamed(context, '/register');  // Using named route

  }

  void _forgotPassword() {
    Navigator.pushNamed(context, '/forgot-password');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              clipBehavior: Clip.antiAlias,
              decoration: ShapeDecoration(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Stack(
                children: [
                  // Logo
                  Positioned(
                    left: 139,
                    top: 108,
                    child: Container(
                      width: 96,
                      height: 60,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage("assets/proxym.png"),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),

                  // Title Section
                  Positioned(
                    left: 56,
                    top: 196,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Log in to your Account',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 22,
                            fontFamily: 'Instrument Sans',
                            fontWeight: FontWeight.w600,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Welcome back, please enter your details.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xD31A293D),
                            fontSize: 14,
                            fontFamily: 'Instrument Sans',
                            fontWeight: FontWeight.w400,
                            height: 1.34,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Login Form
                  Positioned(
                    left: 16,
                    top: 295,
                    child: Container(
                      width: MediaQuery.of(context).size.width - 32,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Email Input
                          _buildInputField(
                            label: 'Email address',
                            hintText: 'Enter your email',
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                          ),

                          // Password Input
                          _buildPasswordField(
                            label: 'Password',
                            hintText: 'Enter your password',
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            onToggleVisibility: _togglePasswordVisibility,
                          ),

                          // Forgot Password and Keep Me Logged In
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Keep Me Logged In
                                Row(
                                  children: [
                                    Checkbox(
                                      value: _keepMeLoggedIn,
                                      onChanged: (bool? value) {
                                        setState(() {
                                          _keepMeLoggedIn = value ?? false;
                                        });
                                      },
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Keep me logged in',
                                      style: TextStyle(
                                        color: Color(0xFF454A53),
                                        fontSize: 14,
                                        fontFamily: 'Instrument Sans',
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),

                                // Forgot Password
                                GestureDetector(
                                  onTap: _forgotPassword,
                                  child: Text(
                                    'Forgot Password?',
                                    style: TextStyle(
                                      color: Color(0xFFB4B429),
                                      fontSize: 14,
                                      fontFamily: 'Instrument Sans',
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Login Button
                          GestureDetector(
                            onTap: _login,
                            child: Container(
                              width: double.infinity,
                              height: 49,
                              padding: const EdgeInsets.all(16),
                              decoration: ShapeDecoration(
                                color: const Color(0xFFDCDC34),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'Login',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color(0xFF463E39),
                                    fontSize: 14,
                                    fontFamily: 'Instrument Sans',
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Sign Up Section with new text
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Not registered yet? ',
                                  style: TextStyle(
                                    color: Color(0xFF454A53),
                                    fontSize: 14,
                                    fontFamily: 'Instrument Sans',
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _navigateToSignUp,
                                  child: Text(
                                    'Create an account now!',
                                    style: TextStyle(
                                      color: Color(0xFFB4B429),
                                      fontSize: 14,
                                      fontFamily: 'Instrument Sans',
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Footer
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(
                        '© 2025 Proxym Mobility',
                        style: TextStyle(
                          color: Color(0xD31A293D),
                          fontSize: 12,
                          fontFamily: 'Instrument Sans',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
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

  // Reusable Input Field
  Widget _buildInputField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Color(0xFF454A53),
                  fontSize: 14,
                  fontFamily: 'Instrument Sans',
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                ' *',
                style: TextStyle(
                  color: Color(0xFFB4B429),
                  fontSize: 14,
                  fontFamily: 'Instrument Sans',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                color: Color(0xFF9EA2AD),
                fontSize: 14,
                fontFamily: 'Instrument Sans',
                fontWeight: FontWeight.w400,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Color(0xFFE9EAEB),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Color(0xFFB4B429),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Reusable Password Input Field
  Widget _buildPasswordField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Color(0xFF454A53),
                  fontSize: 14,
                  fontFamily: 'Instrument Sans',
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                ' *',
                style: TextStyle(
                  color: Color(0xFFB4B429),
                  fontSize: 14,
                  fontFamily: 'Instrument Sans',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            obscureText: obscureText,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                color: Color(0xFF9EA2AD),
                fontSize: 14,
                fontFamily: 'Instrument Sans',
                fontWeight: FontWeight.w400,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Color(0xFFE9EAEB),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Color(0xFFB4B429),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off : Icons.visibility,
                  color: Color(0xFF9EA2AD),
                ),
                onPressed: onToggleVisibility,
              ),
            ),
          ),
        ],
      ),
    );
  }
}