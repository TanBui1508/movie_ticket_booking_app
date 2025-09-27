// main.dart - Cập nhật routes
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cinema_app_flutter/screens/splash_screen.dart';
import 'package:cinema_app_flutter/screens/sigin_screen.dart';
import 'package:cinema_app_flutter/screens/sigup_screen.dart';
import 'package:cinema_app_flutter/utils/theme.dart';
import 'package:cinema_app_flutter/services/auth_service.dart';
import 'firebase_options.dart';
import 'dart:developer';
import 'package:cinema_app_flutter/screens/auth_wrapper.dart';





void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  log('Firebase initialized successfully');

  runApp(const ProviderScope(child: MyApp()));
}

final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authProvider);
  return authService.authStateChanges;
});

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Movie Booking App',
      theme: lightMode,
      debugShowCheckedModeBanner: false,
      
      // Sử dụng một map 'routes' đơn giản, dễ quản lý
      routes: {
        '/': (context) => const SplashScreen(), // Route ban đầu
        '/auth': (context) => const AuthWrapper(), // Route của "người gác cổng"
        '/signin': (context) => const SignInScreen(),
        '/signup': (context) => const SignUpScreen(),
        // Chúng ta không cần route '/home' ở đây nữa vì AuthWrapper sẽ xử lý
      },
      
      // Luôn bắt đầu ứng dụng tại SplashScreen
      initialRoute: '/',
    );
  }
}