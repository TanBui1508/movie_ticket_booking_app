// // lib/utils/theme.dart
// import 'package:flutter/material.dart';

// final ColorScheme lightColorScheme = ColorScheme(
//   brightness: Brightness.light,
//   primary: Colors.blue,
//   onPrimary: Colors.white,
//   secondary: Colors.blue.shade300,
//   onSecondary: Colors.black,
//   error: Colors.red,
//   onError: Colors.white,
//   surface: Colors.white,
//   onSurface: Colors.black,
//   outline: Colors.black26,
//   shadow: Color(0xFF000000),
//   outlineVariant: Color(0xFFC2C8BC),
// );

// const darkColorScheme = ColorScheme(
//   brightness: Brightness.dark,
//   primary: Color(0xFF416FDF),
//   onPrimary: Color(0xFFFFFFFF),
//   secondary: Color(0xFF6EAEE7),
//   onSecondary: Color(0xFFFFFFFF),
//   error: Color(0xFFBA1A1A),
//   onError: Color(0xFFFFFFFF),
//   surface: Color(0xFF1A1C18), 
//   onSurface: Color(0xFFE3E3E3), 
//   outline: Color(0xFF8D9287),
//   shadow: Color(0xFF000000),
//   outlineVariant: Color(0xFFC2C8BC),
// );

// ThemeData lightMode = ThemeData(
//   useMaterial3: true,
//   brightness: Brightness.light,
//   colorScheme: lightColorScheme,
//   elevatedButtonTheme: ElevatedButtonThemeData(
//     style: ElevatedButton.styleFrom(
//       backgroundColor: lightColorScheme.primary,
//       foregroundColor: Colors.white,
//       elevation: 5.0,
//       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//       ),
//     ),
//   ),
// );

// ThemeData darkMode = ThemeData(
//   useMaterial3: true,
//   brightness: Brightness.dark,
//   colorScheme: darkColorScheme,
// );

import 'package:flutter/material.dart';

// (ColorSchemes của bạn giữ nguyên)
final ColorScheme lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Colors.blue,
  onPrimary: Colors.white,
  secondary: Colors.blue.shade300,
  onSecondary: Colors.black,
  error: Colors.red,
  onError: Colors.white,
  surface: Colors.white, // Nền
  onSurface: Colors.black, // Chữ/Icon trên nền
  outline: Colors.black26,
  shadow: Color(0xFF000000),
  outlineVariant: Color(0xFFC2C8BC),
);

const darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFF416FDF),
  onPrimary: Color(0xFFFFFFFF),
  secondary: Color(0xFF6EAEE7),
  onSecondary: Color(0xFFFFFFFF),
  error: Color(0xFFBA1A1A),
  onError: Color(0xFFFFFFFF),
  surface: Color(0xFF1A1C18), // Nền tối
  onSurface: Color(0xFFE3E3E3), // Chữ/Icon trên nền tối
  outline: Color(0xFF8D9287),
  shadow: Color(0xFF000000),
  outlineVariant: Color(0xFFC2C8BC),
);

// --- Light Mode Theme ---
ThemeData lightMode = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: lightColorScheme,
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: lightColorScheme.primary,
      foregroundColor: Colors.white,
      elevation: 5.0,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  ),

  // ✅ THÊM CẤU HÌNH CHO TEXTFORMFIELD (LIGHT MODE)
  inputDecorationTheme: InputDecorationTheme(
    // Màu cho hintText (Enter Email)
    hintStyle: TextStyle(color: lightColorScheme.onSurface.withOpacity(0.4)), // Màu đen mờ
    // Màu cho label (Email)
    labelStyle: TextStyle(color: lightColorScheme.onSurface.withOpacity(0.7)),
    // Màu viền mặc định
    border: OutlineInputBorder(
      borderSide: BorderSide(color: lightColorScheme.outline), // Dùng màu 'outline'
      borderRadius: BorderRadius.circular(10),
    ),
    // Màu viền khi không focus
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: lightColorScheme.outline), // Dùng màu 'outline'
      borderRadius: BorderRadius.circular(10),
    ),
    // Màu viền khi focus
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: lightColorScheme.primary, width: 2.0), // Dùng màu 'primary'
      borderRadius: BorderRadius.circular(10),
    ),
    // Màu chữ khi nhập: Tự động dùng lightColorScheme.onSurface (màu đen)
  ),
);

// --- Dark Mode Theme ---
ThemeData darkMode = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: darkColorScheme,

  // ✅ THÊM CẤU HÌNH CHO TEXTFORMFIELD (DARK MODE)
  inputDecorationTheme: InputDecorationTheme(
    // Màu cho hintText (Enter Email)
    hintStyle: TextStyle(color: darkColorScheme.onSurface.withOpacity(0.4)), // Sẽ là màu xám nhạt
    // Màu cho label (Email)
    labelStyle: TextStyle(color: darkColorScheme.onSurface.withOpacity(0.7)), // Sẽ là màu xám nhạt
    // Màu viền mặc định
    border: OutlineInputBorder(
      borderSide: BorderSide(color: darkColorScheme.outline), // Dùng màu 'outline'
      borderRadius: BorderRadius.circular(10),
    ),
    // Màu viền khi không focus
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: darkColorScheme.outline), // Dùng màu 'outline'
      borderRadius: BorderRadius.circular(10),
    ),
    // Màu viền khi focus
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: darkColorScheme.primary, width: 2.0), // Dùng màu 'primary'
      borderRadius: BorderRadius.circular(10),
    ),
    // Màu chữ khi nhập: Tự động dùng darkColorScheme.onSurface (màu trắng/xám nhạt)
  ),
);