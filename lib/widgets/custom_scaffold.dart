// File custom_scaffold.dart
import 'package:flutter/material.dart';

class CustomScaffold extends StatelessWidget {
  const CustomScaffold({super.key, this.child});
  final Widget? child;

  @override
  Widget build(BuildContext context) {
	return Scaffold(
	  extendBodyBehindAppBar: true,
	  appBar: AppBar(
		backgroundColor: Colors.transparent,
		elevation: 0,
	  ),
	  // Thêm một màu nền
	  backgroundColor: const Color.fromARGB(255, 237, 240, 255), // Thay thế màu này bằng màu chủ đạo của background.jpg
	  body: Stack(
		children: [
		  Image.asset(  
			'assets/images/background.jpg',
			fit: BoxFit.cover,
			width: double.infinity,
			height: double.infinity,
		  ),
		  SafeArea(child: child!)
		],
	  )
	);
  }
}