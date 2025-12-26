import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'login_page.dart';
import '../home/home_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        print('🔐 AuthGate - ConnectionState: ${snapshot.connectionState}');
        print('🔐 AuthGate - HasData: ${snapshot.hasData}');
        print('🔐 AuthGate - IsSignedIn: ${authService.isSignedIn()}');
        print('🔐 AuthGate - Current User: ${authService.currentUser?.email}');

        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // Check if user is signed in
        if (snapshot.hasData && authService.isSignedIn()) {
          print('✅ User is signed in, showing HomePage');
          return const HomePage();
        }
        
        print('❌ User not signed in, showing LoginPage');
        // Show login page if not signed in
        return const LoginPage();
      },
    );
  }
}
