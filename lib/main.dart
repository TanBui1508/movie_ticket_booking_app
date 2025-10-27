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
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/date_symbol_data_local.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('vi_VN', null); 

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
    return ScreenUtilInit(  
      designSize: const Size(412, 924),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'Cinema App',
          theme: lightMode,
          darkTheme: darkMode,
          themeMode: ThemeMode.system,
          debugShowCheckedModeBanner: false,
          initialRoute: '/',
          routes: {
            '/': (context) => const SplashScreen(),
            '/auth': (context) => const AuthWrapper(),
            '/signin': (context) => const SignInScreen(),
            '/signup': (context) => const SignUpScreen(),
            
          },
        );
      },
    );
  }
}