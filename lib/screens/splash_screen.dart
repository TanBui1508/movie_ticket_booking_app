import 'package:flutter/material.dart';
import 'package:cinema_app_flutter/screens/onboarding_screen.dart';
import 'package:lordicon/lordicon.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late IconController _controller;
  late void Function(ControllerStatus) _listener;

  double _opacity = 0.0; // độ mờ ban đầu

  @override
  void initState() {
    super.initState();

    _controller = IconController.assets('assets/logo_movie.json');

    _listener = (status) {
      if (!mounted) return;

      if (status == ControllerStatus.ready) {
        _controller.playFromBeginning();
        // Sau 1s thì bắt đầu fade-in text
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            setState(() {
              _opacity = 1.0;
            });
          }
        });
      } else if (status == ControllerStatus.completed) {
        Navigator.pushReplacementNamed(context, '/onboarding');
      }
    };

    _controller.addStatusListener(_listener);
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_listener);
    //_controller.dispose(); // tạm thời bỏ dispose để tránh crash
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo animation
            IconViewer(
              controller: _controller,
              width: 200,
              height: 200,
            ),
            const SizedBox(height: 24),

            // Fade-in cho text
            AnimatedOpacity(
              opacity: _opacity,
              duration: const Duration(seconds: 1),
              curve: Curves.easeIn,
              child: Column(
                children: const [
                  Text(
                    "Cinema App",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Your movie world in your pocket",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
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
