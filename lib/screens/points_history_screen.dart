// lib/screens/points_history_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../providers/points_provider.dart';
import '../models/point_transaction_model.dart';

class PointsHistoryScreen extends ConsumerWidget {
  const PointsHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(pointsHistoryProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Lịch sử tích điểm'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Column(
        children: [
          // Phần 1: Thẻ tổng điểm
          _PointSummaryCard(),

          // Phần 2: Tiêu đề danh sách
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Giao dịch gần đây',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                TextButton(
                  onPressed: () { /* TODO: Mở trang đổi quà */ },
                  child: const Text('Đổi quà'),
                )
              ],
            ),
          ),

          // Phần 3: Danh sách giao dịch
          Expanded(
            child: historyAsync.when(
              data: (transactions) {
                if (transactions.isEmpty) {
                  return const Center(child: Text('Chưa có giao dịch điểm nào.'));
                }
                return ListView.separated(
                  padding: EdgeInsets.symmetric(horizontal: 12.w).copyWith(bottom: 90.h),
                  itemCount: transactions.length,
                  separatorBuilder: (context, index) => SizedBox(height: 8.h),
                  itemBuilder: (context, index) {
                    return _TransactionTile(transaction: transactions[index]);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Lỗi tải lịch sử: $err')),
            ),
          ),
        ],
      ),
    );
  }
}

// --- WIDGET THẺ TỔNG ĐIỂM ---
class _PointSummaryCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Lắng nghe tổng điểm từ provider
    final totalPointsAsync = ref.watch(userTotalPointsProvider);
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.primaryColor, Colors.red.shade400], // Gradient màu đỏ
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15.r),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: totalPointsAsync.when(
        data: (points) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tổng điểm của bạn',
              style: TextStyle(fontSize: 16.sp, color: Colors.white70),
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Icon(Icons.star, color: Colors.yellow.shade600, size: 36.sp),
                SizedBox(width: 10.w),
                Text(
                  NumberFormat.decimalPattern('vi').format(points), // Format số 1,000
                  style: TextStyle(
                    fontSize: 32.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              'Điểm sẽ hết hạn sau 12 tháng kể từ ngày tích lũy.',
              style: TextStyle(fontSize: 12.sp, color: Colors.white.withOpacity(0.8)),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (e, s) => Text('Lỗi tải điểm', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

// --- WIDGET TILE GIAO DỊCH ---
class _TransactionTile extends StatelessWidget {
  final PointTransaction transaction;
  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final bool isPositive = transaction.points >= 0;
    final Color color = isPositive ? Colors.green.shade600 : Colors.red.shade600;
    final IconData icon = isPositive ? Icons.add_circle : Icons.remove_circle;
    final String prefix = isPositive ? '+' : '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          transaction.title,
          style: const TextStyle(fontWeight: FontWeight.w500),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          DateFormat('dd/MM/yyyy HH:mm').format(transaction.timestamp.toDate()),
        ),
        trailing: Text(
          '$prefix${NumberFormat.decimalPattern('vi').format(transaction.points)}',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16.sp,
          ),
        ),
      ),
    );
  }
}