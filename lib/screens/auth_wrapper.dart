import 'package:cinema_app_flutter/screens/sigin_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cinema_app_flutter/main.dart'; 
import 'package:cinema_app_flutter/screens/main_screen.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          return const MainScreen(); 
        } else {
          return const SignInScreen();
        }
      },
      
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      
      error: (err, stack) => Scaffold(
        body: Center(
          child: Text('Đã có lỗi xảy ra: $err'),
        ),
      ),
    );
  }
}