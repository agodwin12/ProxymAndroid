import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:proxymapp/operations/screens/bike%20details/my_bike.dart';
import 'package:proxymapp/operations/screens/equipement%20details/equipement_details.dart';
import 'package:proxymapp/operations/screens/user%20profile/profilescreen.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final String userId;
  final Color activeColor;

  const CustomBottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.userId,
    required this.activeColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, left: 24.0, right: 24.0),
      child: Container(
        height: 65,
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: activeColor.withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 0,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BottomNavigationBar(
            backgroundColor: Colors.transparent,
            selectedItemColor: activeColor,
            unselectedItemColor: Colors.grey,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.battery_charging_full_rounded),
                label: 'Battery',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.electric_bike_rounded),
                label: 'Bike',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.account_circle_rounded),
                label: 'Profile',
              ),
            ],
            currentIndex: currentIndex,
            onTap: (index) {
              if (index == currentIndex) return; // Don't navigate if already on this tab

              // Navigate to the selected screen
              if (index == 0) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EquipmentDetailsPage( userId: userId, bike: null,)
                  ),
                );
              } else if (index == 1) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MyBikesScreen(
                      userId: userId,
                    ),
                  ),
                );
              } else if (index == 2) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileScreen(
                      userId: userId,
                    ),
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}