// About App Screen implementation
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({Key? key}) : super(key: key);

  // Theme colors
  static const Color backgroundColor = Colors.black;
  static const Color darkCardColor = Color(0xFF121212);
  static const Color tealColor = Color(0xFFE0DC34);
  static const Color textColor = Colors.white;
  static const Color subtextColor = Color(0xFFAAAAAA);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'About Proxym',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: tealColor),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // App logo with glow effect
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: tealColor.withOpacity(0.5),
                      blurRadius: 25,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/proxym.png',
                  height: 120,
                  width: 120,
                ),
              ),

              const SizedBox(height: 30),

              // App name and version
              const Text(
                'Proxym',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: tealColor,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Version 1.0.0',
                style: TextStyle(
                  fontSize: 16,
                  color: subtextColor,
                ),
              ),

              const SizedBox(height: 40),

              // App description with glowing card
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: tealColor.withOpacity(0.3),
                      blurRadius: 15,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Card(
                  color: darkCardColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: tealColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text(
                      'Proxym helps you track your electric bike, control it from distance, and monitor your activities.',
                      style: TextStyle(fontSize: 16, color: textColor),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Legal information with hover effect
              _buildLegalTile(
                'Privacy Policy',
                    () {
                  // Add navigation logic here
                },
              ),

              Divider(
                color: Colors.grey.shade800,
                thickness: 1,
              ),

              _buildLegalTile(
                'Terms of Service',
                    () {
                  // Add navigation logic here
                },
              ),

              const SizedBox(height: 40),

              // Copyright info
              const Text(
                '© 2025 Proxym. All rights reserved.',
                style: TextStyle(
                  fontSize: 14,
                  color: subtextColor,
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegalTile(String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: tealColor.withOpacity(0.2),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.shield_outlined,
              color: tealColor,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  color: textColor,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: subtextColor,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}