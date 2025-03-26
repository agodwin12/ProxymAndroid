import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

import '../complete profile/completeProfile.dart';

class Otp extends StatefulWidget {
  final String nom;
  final String prenom;
  final String email;
  final String phone;
  final String password;

  const Otp({
    Key? key,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.phone,
    required this.password,
  }) : super(key: key);

  @override
  _OtpState createState() => _OtpState();
}


class _OtpState extends State<Otp> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  int _timeRemaining = 120; // 120 seconds = 2 minutes
  Timer? _timer;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    setState(() {
      _timeRemaining = 120;
      _canResend = false;
    });

    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeRemaining > 0) {
          _timeRemaining--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  String get timerText {
    int minutes = _timeRemaining ~/ 60;
    int seconds = _timeRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> resendOTP() async {
    if (!_canResend) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/auth/resend-otp'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'phone': widget.phone,
        }),
      );

      if (response.statusCode == 200) {
        startTimer();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ OTP resent successfully")),
        );
      } else {
        final responseData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ ${responseData['message'] ?? 'Failed to resend OTP'}")),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ An error occurred while resending OTP")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Please enter a valid 4-digit OTP")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.parse('http://10.0.2.2:5000/auth/verify-otp');
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "nom": widget.nom,   // ✅ Make sure these fields are being passed
          "prenom": widget.prenom,
          "email": widget.email,
          "phone": widget.phone,
          "password": widget.password,
          "otp": _otpController.text,
        }),
      );

      print("🔍 Raw Response: ${response.body}"); // ✅ Debug API Response

      if (!response.body.startsWith("{")) {
        throw Exception("Invalid response format (HTML detected). Check API URL.");
      }

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        print("✅ OTP Verified Successfully!");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ OTP Verified! Proceeding to next step.")),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CompleteInformation(phone: widget.phone, nom: widget.nom, prenom: widget.prenom, email: widget.email, password: widget.password,),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ ${responseData['message']}")),
        );
        _otpController.clear();
      }
    } catch (error) {
      print("❌ Error in OTP Verification: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ An error occurred. Please try again.")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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

                  // Title Section with Timer
                  Positioned(
                    left: 17,
                    top: 241,
                    child: Container(
                      width: MediaQuery.of(context).size.width - 34,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'OTP Verification',
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
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Enter the code we sent to ',
                                  style: TextStyle(
                                    color: Color(0xD31A293D),
                                    fontSize: 14,
                                    fontFamily: 'Instrument Sans',
                                    fontWeight: FontWeight.w400,
                                    height: 1.34,
                                  ),
                                ),
                                TextSpan(
                                  text: widget.phone,
                                  style: TextStyle(
                                    color: Color(0xD31A293D),
                                    fontSize: 14,
                                    fontFamily: 'Instrument Sans',
                                    fontWeight: FontWeight.w600,
                                    height: 1.34,
                                  ),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          if (!_canResend) Text(
                            'Resend code in: $timerText',
                            style: TextStyle(
                              color: Color(0xFF9EA2AD),
                              fontSize: 14,
                              fontFamily: 'Instrument Sans',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          if (_canResend) TextButton(
                            onPressed: _isLoading ? null : resendOTP,
                            child: Text(
                              'Resend OTP',
                              style: TextStyle(
                                color: Color(0xFFDCDC34),
                                fontSize: 14,
                                fontFamily: 'Instrument Sans',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // OTP Input Section
                  Positioned(
                    left: 16,
                    top: 359,
                    child: Container(
                      width: MediaQuery.of(context).size.width - 32,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            maxLength: 4,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF454A53),
                              fontSize: 24,
                              fontFamily: 'Instrument Sans',
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              hintText: 'Enter 4-digit OTP',
                              hintStyle: TextStyle(
                                color: Color(0xFF9EA2AD),
                                fontSize: 16,
                                fontFamily: 'Instrument Sans',
                                fontWeight: FontWeight.w400,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Color(0xFFE9EAEB),
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Color(0xFFB4B429),
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Verify Button
                          GestureDetector(
                            onTap: _isLoading ? null : _verifyOtp,
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
                                child: _isLoading
                                    ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF463E39)),
                                    strokeWidth: 2,
                                  ),
                                )
                                    : Text(
                                  'Verify OTP',
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

                          const SizedBox(height: 16),

                          // Info Text
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Color(0xFF9EA2AD),
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Please check your phone for the OTP code',
                                style: TextStyle(
                                  color: Color(0xFF9EA2AD),
                                  fontSize: 14,
                                  fontFamily: 'Instrument Sans',
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ],
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
}