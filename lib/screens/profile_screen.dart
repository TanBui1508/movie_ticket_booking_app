import 'package:cinema_app_flutter/main.dart';
import 'package:cinema_app_flutter/providers/info_profile_provider.dart';
import 'package:cinema_app_flutter/screens/edit_profile_screen.dart';
import 'package:cinema_app_flutter/screens/notification_screen.dart';
import 'package:cinema_app_flutter/screens/payment_history_screen.dart';
import 'package:cinema_app_flutter/screens/points_history_screen.dart';
import 'package:cinema_app_flutter/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cinema_app_flutter/providers/user_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class UserProfileScreen extends ConsumerWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Tài khoản của tôi',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        // ✅ THÊM Padding ở dưới cùng
        padding: EdgeInsets.only(
            bottom: 90.h), // Thêm khoảng đệm = chiều cao NavBar + chút dư
        child: Column(
          children: [
            const _ProfileHeader(),
            SizedBox(height: 20.h),
            _MenuList(),
          ],
        ),
      ),
    );
  }
}

// PHẦN 1: HEADER THÔNG TIN CÁ NHÂN
class _ProfileHeader extends ConsumerWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserDetailProvider);

    return Container(
      padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20.r)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5)),
        ],
      ),
      child: userAsync.when(
        data: (appUser) {
          // ✅ Nhận về AppUser?
          if (appUser == null) {
            // Xử lý khi chưa đăng nhập hoặc không có data
            return Center(
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Điều hướng đến trang đăng nhập
                  Navigator.pushNamed(context, '/signin');
                },
                child: const Text('Đăng nhập / Đăng ký'),
              ),
            );
          }
          // Hiển thị thông tin user
          return Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 45.r,
                      backgroundColor: Colors.grey.shade200,
                      // ✅ Lấy avatarUrl từ AppUser, có fallback
                      backgroundImage: (appUser.avatarUrl != null &&
                              appUser.avatarUrl!.isNotEmpty)
                          ? NetworkImage(appUser.avatarUrl!)
                          : null, // Hoặc AssetImage('assets/default_avatar.png')
                      child: (appUser.avatarUrl == null ||
                              appUser.avatarUrl!.isEmpty)
                          ? Text(
                              // Hiển thị chữ cái đầu nếu không có ảnh
                              appUser.fullName.isNotEmpty
                                  ? appUser.fullName[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                  fontSize: 40.sp, color: Colors.grey.shade600),
                            )
                          : null,
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      appUser.fullName.isNotEmpty
                          ? appUser.fullName
                          : 'Người dùng', // ✅ Lấy fullName
                      style: TextStyle(
                          fontSize: 18.sp, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: QrImageView(
                        data: appUser.id, // ✅ Dùng ID thật của user
                        version: QrVersions.auto,
                        size: 90.r,
                        padding: EdgeInsets.all(8.r),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'Tích điểm',
                      style: TextStyle(
                          fontSize: 14.sp, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Lỗi tải thông tin: $err')),
      ),
    );
  }
}

// PHẦN 2: DANH SÁCH MENU CHỨC NĂNG
class _MenuList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserAsync = ref.watch(currentUserDetailProvider);
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.symmetric(vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          _MenuItem(
              icon: Icons.person_outline,
              title: 'Cập nhật thông tin',
              onTap: () {
                // Lấy giá trị data từ AsyncValue (có thể là null)
                final currentUser = currentUserAsync.value;

                if (currentUser != null) {
                  // Nếu có data user, chuyển sang màn hình Edit
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          EditProfileScreen(initialUser: currentUser),
                    ),
                  );
                } else {
                  // Nếu chưa đăng nhập hoặc data chưa load xong, báo lỗi
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Vui lòng đợi thông tin tải xong hoặc đăng nhập lại')),
                  );
                }
              }),
          _MenuItem(
              icon: Icons.history,
              title: 'Lịch sử thanh toán',
              onTap: () {
                // Kiểm tra đăng nhập trước khi điều hướng
                final user = ref.read(authStateProvider).value;
                if (user != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const PaymentHistoryScreen()),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Vui lòng đăng nhập để xem lịch sử')),
                  );
                }
              }),
          _MenuItem(
              icon: Icons.star_border,
              title: 'Lịch sử tích điểm',
              onTap: () {
                // Kiểm tra đăng nhập trước khi điều hướng
                final user = ref.read(authStateProvider).value;
                if (user != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const PointsHistoryScreen()),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Vui lòng đăng nhập để xem lịch sử')),
                  );
                }
                
              }),
          _MenuItem(
              icon: Icons.notifications_none_outlined,
              title: 'Thông báo',
              onTap: () {
                // Điều hướng đến NotificationScreen (trong MainScreen) bằng cách đổi index
                // Cách này không lý tưởng nếu bạn muốn push màn hình mới
                // Cách tốt hơn là tìm widget cha MainScreen và gọi _onItemTapped(0)
                // Hoặc đơn giản là push màn hình NotificationScreen mới:
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const NotificationScreen()),
                );
              }),
          const Divider(),
          _MenuItem(
              icon: Icons.info_outline,
              title: 'Thông tin công ty',
              onTap: () async {
                // Thêm async
                // Gọi provider để lấy data
                final infoAsync =
                    ref.read(appInfoProvider('company_info').future);
                final info = await infoAsync; // Đợi lấy data
                if (info != null && context.mounted) {
                  // Kiểm tra context.mounted
                  _showInfoDialog(context, info.title, info.content);
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Không thể tải thông tin')));
                }
              }),
          // Làm tương tự cho 3 _MenuItem còn lại với các ID tương ứng
          _MenuItem(
              icon: Icons.description_outlined,
              title: 'Điều khoản sử dụng',
              onTap: () async {
                final info =
                    await ref.read(appInfoProvider('terms_of_use').future);
                if (info != null && context.mounted) {
                  _showInfoDialog(context, info.title, info.content);
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Không thể tải thông tin')));
                }
              }),
          _MenuItem(
              icon: Icons.payment_outlined,
              title: 'Chính sách thanh toán',
              onTap: () async {
                final info =
                    await ref.read(appInfoProvider('payment_policy').future);
                if (info != null && context.mounted) {
                  _showInfoDialog(context, info.title, info.content);
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Không thể tải thông tin')));
                }
              }),
          _MenuItem(
              icon: Icons.shield_outlined,
              title: 'Chính sách bảo mật',
              onTap: () async {
                final info =
                    await ref.read(appInfoProvider('privacy_policy').future);
                if (info != null && context.mounted) {
                  _showInfoDialog(context, info.title, info.content);
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Không thể tải thông tin')));
                }
              }),
          const Divider(),
          _MenuItem(
              icon: Icons.phone_outlined,
              title: 'Hotline: 0812829809', // Added the number here for display
              onTap: () async {
                // ✅ 2. Make onTap async
                final Uri launchUri = Uri(
                  scheme: 'tel',
                  path: '0812829809', // The phone number
                );
                try {
                  if (await canLaunchUrl(launchUri)) {
                    await launchUrl(launchUri);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('Không thể mở ứng dụng gọi điện thoại.')),
                    );
                    print('Could not launch $launchUri'); // Log for debugging
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Lỗi mở ứng dụng gọi điện thoại: $e')),
                  );
                  print('Error launching phone: $e'); // Log for debugging
                }
              }),
          _MenuItem(
              icon: Icons.email_outlined,
              title:
                  'Email: cine4tk@gmail.com', // Added the email here for display
              onTap: () async {
                // ✅ 3. Make onTap async
                final Uri launchUri = Uri(
                  scheme: 'mailto',
                  path: 'cine4tk@gmail.com', // The email address
                );
                try {
                  if (await canLaunchUrl(launchUri)) {
                    await launchUrl(launchUri);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Không thể mở ứng dụng email.')),
                    );
                    print('Could not launch $launchUri'); // Log for debugging
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi mở ứng dụng email: $e')),
                  );
                  print('Error launching email: $e'); // Log for debugging
                }
              }),
          const Divider(),
          _MenuItem(
            icon: Icons.logout,
            title: 'Đăng xuất',
            color: Colors.red,
            onTap: () async {
              // Giữ async nếu dùng dialog
              // Tùy chọn: Thêm dialog xác nhận nếu muốn
              final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                        /* ... dialog xác nhận ... */
                        title: const Text('Xác nhận đăng xuất'),
                        content: const Text(
                            'Bạn có chắc chắn muốn đăng xuất không?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Hủy'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Đăng xuất'),
                          ),
                        ],
                      ));

              if (confirm == true) {
                // Chỉ đăng xuất nếu xác nhận
                try {
                  await ref.read(authProvider).signOut();
                  // ✅ KHÔNG cần Navigator ở đây nữa. AuthWrapper sẽ tự xử lý.
                  // Có thể hiển thị SnackBar nếu muốn
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Đã đăng xuất'),
                          duration: Duration(seconds: 1)),
                    );
                  }
                } catch (e) {
                  // Xử lý lỗi nếu signOut thất bại
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Lỗi đăng xuất: $e'),
                          backgroundColor: Colors.red),
                    );
                  }
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

// Widget con cho mỗi mục trong Menu
class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? color;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.grey.shade700),
      title: Text(title,
          style: TextStyle(color: color ?? Colors.black87, fontSize: 16.sp)),
      trailing: Icon(Icons.arrow_forward_ios,
          size: 14.sp, color: Colors.grey.shade400),
      onTap: onTap,
    );
  }
}

void _showInfoDialog(BuildContext context, String title, String content) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          // Cho phép cuộn nếu nội dung dài
          child: Text(content),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Đóng'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}
