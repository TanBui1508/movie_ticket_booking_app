import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onItemTapped;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    final double systemBottomPadding = MediaQuery.of(context).viewPadding.bottom;


    return Align(
      alignment: Alignment.bottomCenter,
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30.r),
          topRight: Radius.circular(30.r),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(
            height: 70.h + systemBottomPadding,
            //color: Colors.white.withAlpha(26),
            color: Colors.black.withAlpha(100),
            child: Padding(
              // ✅ CHỈ THÊM ĐỆM Ở DƯỚI ĐỂ ĐẨY CÁC ICON LÊN
              padding: EdgeInsets.only(bottom: systemBottomPadding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _navBarIcon(Icons.confirmation_number_outlined, 0), // Sửa icon (Hỗ trợ -> Vé)
                  _navBarIcon(Icons.local_offer_outlined, 1),
                  _navBarIcon(Icons.home, 2, isHome: true),
                  _navBarIcon(Icons.theaters_outlined, 3),
                  _navBarIcon(Icons.person_outline, 4),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navBarIcon(IconData icon, int index, {bool isHome = false}) {
    final isActive = index == currentIndex;

    return GestureDetector(
      onTap: () => onItemTapped(index),
      child: Container(
        padding: EdgeInsets.all(isHome ? 12.r : 8.r),
        decoration: isHome && isActive
            ? const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.redAccent,
              )
            : null,
        child: Icon(
          icon,
          color: isHome
            ? (isActive ? Colors.white : Colors.white70)
            : (isActive ? Colors.redAccent : Colors.white70),
          size: isHome ? 28.sp : 24.sp,
        ),
      ),
    );
  }
}
