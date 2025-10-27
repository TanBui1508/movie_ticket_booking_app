// lib/screens/notification_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/notification_model.dart'; // Import model AppNotification
import '../providers/notification_provider.dart';
import '../providers/read_notification_provider.dart'; // ✅ Import provider trạng thái đọc

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    // ✅ Watch trạng thái các ID đã đọc
    final readNotificationIds = ref.watch(readNotificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          // ✅ Nút Đánh dấu tất cả đã đọc
          notificationsAsync.maybeWhen( // Chỉ hiển thị khi có data
            data: (notifications) => notifications.isNotEmpty ? IconButton(
              icon: const Icon(Icons.mark_chat_read_outlined),
              tooltip: 'Đánh dấu tất cả đã đọc',
              onPressed: () {
                final allIds = notifications.map((n) => n.id!).toList();
                // Gọi notifier để đánh dấu tất cả
                ref.read(readNotificationsProvider.notifier).markAllAsRead(allIds);
              },
            ) : const SizedBox(), // Ẩn nếu list rỗng
            orElse: () => const SizedBox(), // Ẩn khi loading/error
          ),
        ],
      ),
      backgroundColor: Colors.grey.shade100, // ✅ Nền xám nhạt
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            // ✅ Giao diện khi trống đẹp hơn
            return Center(
               child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                     Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey.shade400),
                     const SizedBox(height: 16),
                     const Text('Không có thông báo nào.', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  ],
               ),
            );
          }
          return ListView.builder( // ✅ Dùng ListView.builder thay vì Separated
            padding: EdgeInsets.only(bottom: 90, top: 8, left: 8, right: 8), // Padding cho NavBar và xung quanh
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notif = notifications[index];
              // ✅ Kiểm tra xem ID có trong Set đã đọc không
              final bool isRead = readNotificationIds.contains(notif.id);

              // ✅ Bọc ListTile bằng Card để đẹp hơn
              return Card(
                 margin: const EdgeInsets.only(bottom: 8.0),
                 elevation: isRead ? 0.5 : 2.0, // Giảm elevation nếu đã đọc
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                 color: isRead ? Colors.white : Colors.blue.shade50.withOpacity(0.6), // Màu nền khác nhau
                 child: ListTile(
                   leading: _getIconForType(notif.type),
                   title: Text(
                     notif.title,
                     style: TextStyle(
                       fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                       color: isRead ? Colors.black54 : Colors.black87, // Màu chữ khác nhau
                     ),
                     maxLines: 1,
                     overflow: TextOverflow.ellipsis,
                   ),
                   subtitle: Text(
                     notif.content,
                     maxLines: 2,
                     overflow: TextOverflow.ellipsis,
                     style: TextStyle(color: isRead ? Colors.grey.shade600 : Colors.black87),
                   ),
                   trailing: Text(
                     DateFormat('dd/MM HH:mm').format(notif.createdAt.toDate()),
                     style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                   ),
                   onTap: () {
                     // ✅ Đánh dấu là đã đọc KHI nhấn vào
                     if (!isRead && notif.id != null) {
                       ref.read(readNotificationsProvider.notifier).markAsRead(notif.id!);
                     }
                     // Hiển thị dialog chi tiết
                     showDialog(
                       context: context,
                       builder: (context) => AlertDialog(
                         title: Text(notif.title),
                         content: SingleChildScrollView(child: Text(notif.content)),
                         actions: [TextButton(onPressed: ()=>Navigator.pop(context), child: const Text('Đóng'))],
                       )
                     );
                   },
                   // tileColor không cần nữa vì đã dùng Card color
                 ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Lỗi tải thông báo: $err')),
      ),
    );
  }

  // Helper _getIconForType giữ nguyên
   Widget _getIconForType(String type) {
    IconData iconData;
    Color color;
    switch (type.toLowerCase()) {
      case 'promotion':
        iconData = Icons.local_offer_outlined;
        color = Colors.orange.shade700; // Màu đậm hơn
        break;
      case 'system':
        iconData = Icons.settings_outlined;
        color = Colors.blue.shade700;
        break;
      case 'cinema_update':
        iconData = Icons.theaters_outlined;
        color = Colors.purple.shade700;
        break;
      default: // general
        iconData = Icons.notifications_none_outlined;
        color = Colors.grey.shade700;
    }
    return CircleAvatar(
      backgroundColor: color.withOpacity(0.15), // Nền đậm hơn chút
      child: Icon(iconData, color: color, size: 24),
    );
  }
}