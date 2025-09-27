import 'package:flutter/material.dart';
// import 'package:cinema_app_flutter/screens/auth/login_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Welcome to Movie Booking App', style: Theme.of(context).textTheme.displayLarge),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // Navigator.push(context, MaterialPageRoute(builder: (context) => LoginScreen()));
            },
            child: Text('Get Started'),
          ),
        ],
      ),
    );
  }
}