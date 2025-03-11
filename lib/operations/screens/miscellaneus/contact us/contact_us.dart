import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({Key? key}) : super(key: key);

  // Theme colors
  static const Color backgroundColor = Colors.black;
  static const Color darkCardColor = Color(0xFF121212);
  static const Color tealColor = Color(0xFFE0DC34);
  static const Color textColor = Colors.white;
  static const Color subtextColor = Color(0xFFAAAAAA);

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri uri = Uri(scheme: 'tel', path: phoneNumber);
    if (!await launchUrl(uri)) {
      throw Exception('Could not launch $uri');
    }
  }

  Future<void> _sendEmail(String email) async {
    final Uri uri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Support Request&body=Hello Proxym Team,',
    );
    if (!await launchUrl(uri)) {
      throw Exception('Could not launch $uri');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Contact Us',
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
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Header image with glow effect
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: tealColor.withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/proxym.png',
                    height: 100,
                    width: 200,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Introduction text
              const Text(
                'We\'re Here For You',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: tealColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Need assistance with your electric bike? Our team is available 24/7 to help you. Contact us via phone or email, or visit our website for more information.',
                  style: TextStyle(fontSize: 16, color: textColor),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 36),

              // Contact cards
              _buildContactCard(
                context,
                'Phone',
                'ORANGE Cameroon',
                '+237 693-289-941',
                Icons.phone_android,
                Colors.orange,
                    () => _makePhoneCall('+237693289941'),
              ),

              _buildContactCard(
                context,
                'Phone',
                'MTN Cameroon',
                '+237 694 587 675',
                Icons.phone_android,
                Colors.yellow.shade700,
                    () => _makePhoneCall('+237694587675'),
              ),

              _buildContactCard(
                context,
                'Email',
                'Support',
                'accueil@proxymgroup.com',
                Icons.email_outlined,
                Colors.blue,
                    () => _sendEmail('accueil@proxymgroup.com'),
              ),

              _buildContactCard(
                context,
                'Website',
                'Visit Our Website',
                'www.proxymgroup.com',
                Icons.language,
                tealColor,
                    () => _launchURL('https://www.proxymgroup.com'),
              ),

              const SizedBox(height: 32),

              // Business hours with glow effect
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: darkCardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: tealColor.withOpacity(0.3),
                      blurRadius: 15,
                      spreadRadius: 1,
                    ),
                  ],
                  border: Border.all(
                    color: tealColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: const [
                    Text(
                      'Support Hours',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: tealColor,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      '24 hours / 7 days',
                      style: TextStyle(fontSize: 18, color: textColor),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'We\'re always here to help you!',
                      style: TextStyle(fontSize: 14, color: subtextColor),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactCard(
      BuildContext context,
      String title,
      String subtitle,
      String value,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: tealColor.withOpacity(0.2),
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        color: darkCardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: tealColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: tealColor.withOpacity(0.1),
          highlightColor: tealColor.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: textColor,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: subtextColor,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value,
                        style: const TextStyle(
                          color: tealColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: subtextColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}