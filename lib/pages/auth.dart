import 'package:driver_app/navbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'home_page.dart';  // Assuming you have this screen
import 'login_page.dart';

class AuthCheck extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(), // Listening for changes
      builder: (context, snapshot) {
        // If the snapshot has data (user is authenticated)
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator()); // Show a loading indicator while checking
        } else if (snapshot.hasData) {
          // If user is authenticated, navigate to HomeScreen
          return CustomNavbar();
        } else {
          // If user is not authenticated, navigate to LoginScreen
          return LoginScreen();
        }
      },
    );
  }
}
