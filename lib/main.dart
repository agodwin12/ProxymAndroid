
import 'package:flutter/material.dart';
import 'package:proxymapp/operations/screens/equipement%20details/equipement_details.dart';
import 'package:proxymapp/operations/screens/my%20equipements/my_equipements.dart';

import 'operations/screens/forgot password/forgot_password.dart';
import 'operations/screens/login/login.dart';
import 'operations/screens/sign up/signup.dart';
import 'operations/screens/splash screen/splashScreen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(

      ),
      home: Login(),
      routes: {
        '/register': (context) => Registration(),
        '/login':(context)=>Login(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/equipements': (context) => MyEquipmentScreen(userId: '',),
      //  '/detailsequip': (context) => EquipmentDetailsPage(bike: ''),

      },
    );
  }
}

