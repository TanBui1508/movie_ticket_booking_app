// lib/screens/main_screen.dart
import 'package:cinema_app_flutter/screens/cinema_list_screen.dart';
import 'package:cinema_app_flutter/screens/home_screen.dart';
import 'package:cinema_app_flutter/screens/profile_screen.dart';
import 'package:cinema_app_flutter/screens/voucher_wallet_screen.dart'; 
import 'package:cinema_app_flutter/widgets/custom_bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:cinema_app_flutter/screens/notification_screen.dart';
import 'package:cinema_app_flutter/screens/my_tickets_screen.dart';

class MainScreen extends StatefulWidget {
  final int? defaultIndex;
  
  const MainScreen({super.key, this.defaultIndex});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 2; // Bắt đầu ở trang Home (index = 2)

  static const List<Widget> _pages = <Widget>[
    MyTicketsScreen(),             // Trang 0: Thông báo
    VoucherWalletScreen(),            // <-- Trang 1: Ví Voucher
    HomeScreen(),                     // Trang 2: Màn hình chính
    CinemaListScreen(),               // Trang 3: Rạp phim
    UserProfileScreen(),              // Trang 4: Màn hình Profile                     // Trang 4: Màn hình Profile
  ];

  @override
  void initState() {
    super.initState();
    // ✅ THÊM: Đặt index mặc định khi widget được tạo
    _selectedIndex = widget.defaultIndex ?? 2; // Mặc định là Home (index 2)
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // IndexedStack giúp giữ lại trạng thái của các trang khi chuyển tab
          IndexedStack(
            index: _selectedIndex,
            children: _pages,
          ),
          // BottomNavBar luôn nằm ở trên cùng của Stack
          CustomBottomNavBar(
            currentIndex: _selectedIndex,
            onItemTapped: _onItemTapped,
          ),
        ],
      ),
    );
  }
}