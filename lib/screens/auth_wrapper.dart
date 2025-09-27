import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cinema_app_flutter/main.dart'; 
import 'package:cinema_app_flutter/screens/home_screen.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    // Dùng .when để lắng nghe và tự động build lại UI
    return authState.when(
      // Khi có dữ liệu (dù user là null hay không), đều vào HomeScreen
      data: (user) => const HomeScreen(),
      
      // Trong khi chờ kết quả đầu tiên, hiển thị màn hình loading
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      
      // Nếu có lỗi (ví dụ: mất mạng lúc khởi động), hiển thị thông báo
      error: (err, stack) => Scaffold(
        body: Center(
          child: Text('Đã có lỗi xảy ra: $err'),
        ),
      ),
    );
  }
}