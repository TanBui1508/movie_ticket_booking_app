// lib/screens/payment_history_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:cinema_app_flutter/providers/ticket_provider.dart'; // Import provider vé

class PaymentHistoryScreen extends ConsumerWidget {
  const PaymentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsAsync = ref.watch(userTicketsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Lịch sử giao dịch'), // Đổi tiêu đề
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 1,
      ),
      body: ticketsAsync.when(
        data: (tickets) {
          if (tickets.isEmpty) {
            return const Center(child: Text('Bạn chưa có giao dịch nào.'));
          }
          return ListView.builder(
            itemCount: tickets.length,
            itemBuilder: (context, index) {
              final ticket = tickets[index];
              final isPaid = ticket.paymentStatus.toLowerCase() == 'paid';
              
              // ✅ CHỌN THỜI GIAN ĐỂ HIỂN THỊ
              // Nếu đã thanh toán và có paidAt -> dùng paidAt
              // Nếu không -> dùng bookingTime (thời gian tạo vé)
              final DateTime displayTime = (isPaid && ticket.paidAt != null) 
                                            ? ticket.paidAt! 
                                            : ticket.bookingTime;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                elevation: 2,
                color: theme.colorScheme.surface,
                child: ListTile(
                  leading: Image.network(
                      ticket.movie.posterUrl,
                      width: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (c,e,s) => Container(
                         width: 50.w, height: 75.h, 
                         color: theme.colorScheme.surfaceVariant,
                         child: const Icon(Icons.movie)
                      )
                  ),
                  title: Text(
                    ticket.movie.title, 
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Rạp: ${ticket.theaterName}'),
                      Text('Suất: ${DateFormat('dd/MM HH:mm').format(ticket.showDateTime)}'),
                      Text('Ghế: ${ticket.seats.map((s) => s.seatId).join(', ')}'),
                      Text('Tổng tiền: ${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(ticket.totalPrice)}'),
                      Text('Trạng thái: ${_formatStatus(ticket.paymentStatus)}', style: TextStyle(color: _getStatusColor(ticket.paymentStatus))),
                      SizedBox(height: 4.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // // Trạng thái
                          // Text(
                          //   _formatStatus(ticket.paymentStatus), 
                          //   style: TextStyle(
                          //     color: _getStatusColor(ticket.paymentStatus), 
                          //     fontWeight: FontWeight.bold,
                          //     fontSize: 13.sp
                          //   )
                          // ),
                          // Thời gian
                          Text(
                            DateFormat('dd/MM/yy HH:mm').format(displayTime.toLocal()), // Hiển thị thời gian
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant, 
                              fontSize: 12.sp
                            )
                          ),
                        ],
                      ),
                    ],
                  ),
                  isThreeLine: false,
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Lỗi tải lịch sử: $err')),
      ),
    );
  }

  // Copy 2 hàm helper từ admin qua
  Color _getStatusColor(String status) {
    // ... (copy hàm từ TicketManagementScreen) ...
     switch (status.toLowerCase()) {
      case 'paid':
      case 'success':
      case 'đã thanh toán': return Colors.green;
      case 'pending':
      case 'chờ thanh toán': return Colors.orange;
      case 'failed':
      case 'thất bại':
      case 'cancelled':
      case 'đã hủy': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _formatStatus(String status) {
   // ... (copy hàm từ TicketManagementScreen) ...
    switch (status.toLowerCase()) {
      case 'paid':
      case 'success': return 'Đã thanh toán';
      case 'pending': return 'Chờ TT';
      case 'failed': return 'Thất bại';
      case 'cancelled': return 'Đã hủy';
      default: return status;
    }
  }
}