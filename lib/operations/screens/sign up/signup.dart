import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../otp validation/otpValidation.dart';
import '../login/login.dart';  // Update this path according to your project structure

class Registration extends StatefulWidget {
  const Registration({Key? key}) : super(key: key);

  @override
  _RegistrationState createState() => _RegistrationState();
}

class _RegistrationState extends State<Registration> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  Map<String, bool> _fieldValidation = {
    'lastName': false,
    'firstName': false,
    'email': false,
    'phone': false,
    'password': false,
    'confirmPassword': false,
  };

  @override
  void initState() {
    super.initState();
    _setupFieldValidation();
  }

  void _setupFieldValidation() {
    _lastNameController.addListener(() {
      setState(() {
        _fieldValidation['lastName'] = _lastNameController.text.length >= 2;
      });
    });

    _firstNameController.addListener(() {
      setState(() {
        _fieldValidation['firstName'] = _firstNameController.text.length >= 2;
      });
    });

    _emailController.addListener(() {
      setState(() {
        _fieldValidation['email'] = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
            .hasMatch(_emailController.text);
      });
    });

    _phoneController.addListener(() {
      setState(() {
        _fieldValidation['phone'] = _phoneController.text.length >= 8;
      });
    });

    _passwordController.addListener(() {
      setState(() {
        _fieldValidation['password'] = _passwordController.text.length >= 6;
        _validateConfirmPassword();
      });
    });

    _confirmPasswordController.addListener(() {
      setState(() {
        _validateConfirmPassword();
      });
    });
  }

  void _validateConfirmPassword() {
    _fieldValidation['confirmPassword'] =
        _confirmPasswordController.text == _passwordController.text &&
            _confirmPasswordController.text.isNotEmpty;
  }

  @override
  void dispose() {
    _lastNameController.dispose();
    _firstNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_validateForm()) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'nom': _lastNameController.text,
          'prenom': _firstNameController.text,
          'email': _emailController.text,
          'phone': _phoneController.text,
          'password': _passwordController.text,
        }),
      );

      print('Registration response: ${response.body}');

      if (response.statusCode == 201) {
        print('Registration successful');
        if (!mounted) return;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Otp(
                nom: _lastNameController.text,     // ✅ Send nom
                prenom: _firstNameController.text, // ✅ Send prenom
                email: _emailController.text,      // ✅ Send email
                phone: _phoneController.text,      // ✅ Send phone
                password: _passwordController.text // ✅ Send password
            ),
          ),
        );

      } else {
        final error = json.decode(response.body)['message'] ?? 'Registration failed';
        _showErrorDialog(error);
      }
    } catch (error) {
      print('Registration error: $error');
      _showErrorDialog('Connection error. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _validateForm() {
    return _fieldValidation.values.every((isValid) => isValid);
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Logo
                Container(
                  margin: const EdgeInsets.only(top: 48, bottom: 16),
                  width: 96,
                  height: 60,
                  child: Image.asset(
                    "assets/proxym.png",
                    fit: BoxFit.contain,
                  ),
                ),

                // Title
                const Text(
                  'Create your Account',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Welcome, please enter your details.',
                  style: TextStyle(
                    color: Color(0xD31A293D),
                    fontSize: 14,
                    height: 1.34,
                  ),
                ),
                const SizedBox(height: 32),

                // Form Fields
                _buildTextField(
                  controller: _lastNameController,
                  label: 'Noms',
                  hintText: 'Enter your last name',
                  isValid: _fieldValidation['lastName'] ?? false,
                ),
                _buildTextField(
                  controller: _firstNameController,
                  label: 'Prénoms',
                  hintText: 'Enter your first name',
                  isValid: _fieldValidation['firstName'] ?? false,
                ),
                _buildTextField(
                  controller: _emailController,
                  label: 'Email address',
                  hintText: 'Enter your email address',
                  keyboardType: TextInputType.emailAddress,
                  isValid: _fieldValidation['email'] ?? false,
                ),
                _buildTextField(
                  controller: _phoneController,
                  label: 'Phone',
                  hintText: 'Enter your phone number',
                  keyboardType: TextInputType.phone,
                  isValid: _fieldValidation['phone'] ?? false,
                ),
                _buildPasswordField(
                  controller: _passwordController,
                  label: 'Password',
                  hintText: 'Enter your password',
                  obscureText: _obscurePassword,
                  onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
                  isValid: _fieldValidation['password'] ?? false,
                ),
                _buildPasswordField(
                  controller: _confirmPasswordController,
                  label: 'Confirm password',
                  hintText: 'Confirm your password',
                  obscureText: _obscureConfirmPassword,
                  onToggleVisibility: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  isValid: _fieldValidation['confirmPassword'] ?? false,
                ),

                const SizedBox(height: 32),

                // Sign Up Button
                SizedBox(
                  width: double.infinity,
                  height: 49,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDCDC34),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF463E39)),
                      ),
                    )
                        : const Text(
                      'Sign up',
                      style: TextStyle(
                        color: Color(0xFF463E39),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style: TextStyle(
                        color: Color(0xFF454A53),
                        fontSize: 14,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const Login(),
                          ),
                        );
                      },
                      child: const Text(
                        'Click here',
                        style: TextStyle(
                          color: Color(0xFFDCDC34),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required bool isValid,
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
                style: const TextStyle(
                  color: Color(0xFF454A53),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Text(
                ' *',
                style: TextStyle(
                  color: Color(0xFFB4B429),
                  fontSize: 14,
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
              hintStyle: const TextStyle(
                color: Color(0xFF9EA2AD),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(
                  color: Color(0xFFE9EAEB),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(
                  color: Color(0xFFB4B429),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              suffixIcon: isValid
                  ? const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 20,
              )
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    required bool isValid,
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
                style: const TextStyle(
                  color: Color(0xFF454A53),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Text(
                ' *',
                style: TextStyle(
                  color: Color(0xFFB4B429),
                  fontSize: 14,
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
              hintStyle: const TextStyle(
                color: Color(0xFF9EA2AD),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(
                  color: Color(0xFFE9EAEB),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(
                  color: Color(0xFFB4B429),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isValid)
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20,
                    ),
                  IconButton(
                    icon: Icon(
                      obscureText ? Icons.visibility_off : Icons.visibility,
                      color: const Color(0xFF9EA2AD),
                    ),
                    onPressed: onToggleVisibility,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}