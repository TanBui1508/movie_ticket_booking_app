import 'package:flutter/material.dart';
import 'package:lordicon/lordicon.dart';
import 'dart:developer';
import 'package:cinema_app_flutter/screens/auth_wrapper.dart'; 

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late IconController _controller;
  late void Function(ControllerStatus) _listener;
  bool _isNavigating = false;
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
  }

  void _initializeAnimation() {
    try {
      _controller = IconController.assets('assets/logo_movie.json');
      
      _listener = (status) {
        if (!mounted || _isNavigating) return;

        if (status == ControllerStatus.ready) {
          log('Animation ready, playing...');
          _controller.playFromBeginning();
          
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted && !_isNavigating) {
              setState(() {
                _opacity = 1.0;
              });
            }
          });
          
        } else if (status == ControllerStatus.completed) {
          log('✅ Animation completed, navigating...');
          _navigateToAuth(); // ✅ SỬA ĐỔI
        }
      };

      _controller.addStatusListener(_listener);
      
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && !_isNavigating) {
          log('⏰ Animation timeout, navigating...');
          _navigateToAuth(); // ✅ SỬA ĐỔI
        }
      });
      
    } catch (e) {
      log('Error initializing animation: $e');
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && !_isNavigating) {
          _navigateToAuth(); // ✅ SỬA ĐỔI
        }
      });
    }
  }

  void _navigateToAuth() { // ✅ SỬA ĐỔI TÊN HÀM
    if (_isNavigating || !mounted) return;
    
    _isNavigating = true;
    log('🚀 Navigating to /auth'); // ✅ SỬA ĐỔI LOG
    
    try {
      Navigator.pushReplacementNamed(context, '/auth'); // ✅ SỬA ĐỔI ROUTE
    } catch (e) {
      log('❌ Navigation error: $e. Using fallback.');
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AuthWrapper()), // ✅ SỬA ĐỔI FALLBACK
        );
      }
    }
  }

  @override
  void dispose() {
    // Luôn dispose controller để tránh memory leak
    _controller.removeStatusListener(_listener);
    //_controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ... Phần UI của bạn giữ nguyên, không cần thay đổi ...
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildAnimation(),
            const SizedBox(height: 24),
            AnimatedOpacity(
              opacity: _opacity,
              duration: const Duration(milliseconds: 1500),
              curve: Curves.easeOut,
              child: Column(
                children: [
                  const Text(
                    "Cinema App",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Your movie world in your pocket",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor,
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

  Widget _buildAnimation() {
    // ... phần này cũng giữ nguyên ...
    try {
      return IconViewer(
        controller: _controller,
        width: 200,
        height: 200,
      );
    } catch (e) {
      log('❌ Animation widget error: $e');
      return Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.movie,
              size: 60,
              color: Colors.grey,
            ),
            SizedBox(height: 8),
            Text(
              'Loading...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }
  }
}