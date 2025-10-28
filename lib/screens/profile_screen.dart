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
import 'package:flutter/services.dart';

class UserProfileScreen extends ConsumerWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);   //Dùng theme để hỗ trợ chế độ sáng/tối

    return Scaffold(
      backgroundColor: theme.colorScheme.background,  
      appBar: AppBar(
        title: Text(
          'Tài khoản của tôi',
          style: TextStyle(
            color: theme.colorScheme.onSurface,  
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: theme.colorScheme.surface,  
        elevation: 1,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: 90.h),
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

// -----------------------------------------------------------------------------
// PHẦN 1: HEADER THÔNG TIN CÁ NHÂN
// -----------------------------------------------------------------------------
class _ProfileHeader extends ConsumerWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserDetailProvider);
    final theme = Theme.of(context);  

    return Container(
      padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,  
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20.r)),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),  
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: userAsync.when(
        data: (appUser) {
          if (appUser == null) {
            return Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/signin'),
                child: const Text('Đăng nhập / Đăng ký'),
              ),
            );
          }

          return Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 45.r,
                      backgroundColor:
                          theme.colorScheme.primaryContainer,  
                      backgroundImage: (appUser.avatarUrl?.isNotEmpty ?? false)
                          ? NetworkImage(appUser.avatarUrl!)
                          : null,
                      child: (appUser.avatarUrl == null ||
                              appUser.avatarUrl!.isEmpty)
                          ? Text(
                              appUser.fullName.isNotEmpty
                                  ? appUser.fullName[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                fontSize: 40.sp,
                                color: theme.colorScheme.onSurfaceVariant,  
                              ),
                            )
                          : null,
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      appUser.fullName.isNotEmpty
                          ? appUser.fullName
                          : 'Người dùng',
                      style: theme.textTheme.titleMedium!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),  
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
                        border: Border.all(color: theme.dividerColor),  
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: QrImageView(
                        data: appUser.id,
                        version: QrVersions.auto,
                        size: 90.r,
                        padding: EdgeInsets.all(8.r),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'Tích điểm',
                      style: theme.textTheme.bodySmall,  
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

// -----------------------------------------------------------------------------
// PHẦN 2: DANH SÁCH MENU CHỨC NĂNG
// -----------------------------------------------------------------------------
class _MenuList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserAsync = ref.watch(currentUserDetailProvider);
    final theme = Theme.of(context);  

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.symmetric(vertical: 8.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,  
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          _MenuItem(
              icon: Icons.person_outline,
              title: 'Cập nhật thông tin',
              onTap: () {
                final currentUser = currentUserAsync.value;
                if (currentUser != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          EditProfileScreen(initialUser: currentUser),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text('Vui lòng đợi thông tin tải xong hoặc đăng nhập lại')),
                  );
                }
              }),
          _MenuItem(
              icon: Icons.history,
              title: 'Lịch sử thanh toán',
              onTap: () {
                final user = ref.read(authStateProvider).value;
                if (user != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const PaymentHistoryScreen()),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng đăng nhập để xem lịch sử')),
                  );
                }
              }),
          _MenuItem(
              icon: Icons.star_border,
              title: 'Lịch sử tích điểm',
              onTap: () {
                final user = ref.read(authStateProvider).value;
                if (user != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const PointsHistoryScreen()),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng đăng nhập để xem lịch sử')),
                  );
                }
              }),
          _MenuItem(
              icon: Icons.notifications_none_outlined,
              title: 'Thông báo',
              onTap: () {
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
                final infoAsync =
                    ref.read(appInfoProvider('company_info').future);
                final info = await infoAsync;
                if (info != null && context.mounted) {
                  _showInfoDialog(context, info.title, info.content);
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Không thể tải thông tin')));
                }
              }),
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
              title: 'Hotline: 0812829809',
              onTap: () async {
                final Uri launchUri = Uri(
                  scheme: 'tel',
                  path: '0812829809',
                );
                try {
                  if (await canLaunchUrl(launchUri)) {
                    await launchUrl(launchUri);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Không thể mở ứng dụng gọi điện thoại.')),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi mở ứng dụng gọi điện thoại: $e')),
                  );
                }
              }),
          const Divider(),
          _MenuItem(
            icon: Icons.logout,
            title: 'Đăng xuất',
            color: Colors.red,
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Xác nhận đăng xuất'),
                  content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
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
                ),
              );

              if (confirm == true) {
                try {
                  await ref.read(authProvider).signOut();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Đã đăng xuất'),
                          duration: Duration(seconds: 1)),
                    );
                  }
                } catch (e) {
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

// -----------------------------------------------------------------------------
// Widget con cho mỗi mục trong Menu
// -----------------------------------------------------------------------------
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
    final theme = Theme.of(context);  

    return ListTile(
      leading: Icon(icon, color: color ?? theme.iconTheme.color),  
      title: Text(
        title,
        style: theme.textTheme.bodyLarge!.copyWith(
          color: color ?? theme.colorScheme.onSurface,  
          fontSize: 16.sp,
        ),
      ),
      trailing: Icon(Icons.arrow_forward_ios,
          size: 14.sp, color: theme.hintColor),  
      onTap: onTap,
    );
  }
}

// -----------------------------------------------------------------------------
// HỘP THOẠI HIỂN THỊ THÔNG TIN
// -----------------------------------------------------------------------------
void _showInfoDialog(BuildContext context, String title, String content) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      final theme = Theme.of(context);  

      return AlertDialog(
        backgroundColor: theme.colorScheme.surface,  
        title: Text(title, style: theme.textTheme.titleMedium),  
        content: SingleChildScrollView(child: Text(content, style: theme.textTheme.bodyMedium)),  
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
