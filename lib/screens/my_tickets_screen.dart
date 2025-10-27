import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart'; 
import 'package:share_plus/share_plus.dart';   
import 'package:cinema_app_flutter/providers/ticket_provider.dart'; 
import 'package:cinema_app_flutter/models/ticket_model.dart';
import 'package:cinema_app_flutter/main.dart'; 
import 'sigin_screen.dart'; 
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart'; 
import 'package:permission_handler/permission_handler.dart';


class MyTicketsScreen extends ConsumerWidget {
  const MyTicketsScreen({super.key});

  void _showTicketDetails(BuildContext context, Ticket ticket) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) {
        return _TicketDetailSheet(ticket: ticket); 
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsAsync = ref.watch(userTicketsProvider);
    final user = ref.watch(authStateProvider).value;
    final theme = Theme.of(context);

    if (user == null) {
      return Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          title: const Text('Vé Đã Đặt'),
          backgroundColor: theme.colorScheme.surface,
          foregroundColor: theme.colorScheme.onSurface, // Chữ trên AppBar
          elevation: 1,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Vui lòng đăng nhập để xem vé của bạn.'),
              SizedBox(height: 16.h),
              ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SignInScreen())),
                child: const Text('Đăng nhập'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
 title: const Text('Vé Đã Đặt'),
 backgroundColor: theme.colorScheme.surface, // ✅ Sửa: Dùng màu surface
 foregroundColor: theme.colorScheme.onSurface, // ✅ Sửa: Dùng màu onSurface
 elevation: 1,
   ),
      body: ticketsAsync.when(
        data: (tickets) {
          if (tickets.isEmpty) {
            return const Center(
              child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                    Icon(Icons.confirmation_number_outlined, size: 80, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('Bạn chưa có vé nào.', style: TextStyle(fontSize: 18, color: Colors.grey)),
                 ],
              ),
            );
          }
          return ListView.builder(
            padding: EdgeInsets.all(12.w).copyWith(bottom: 90.h), 
            itemCount: tickets.length,
            itemBuilder: (context, index) {
              final ticket = tickets[index];
              return _TicketCard(
                ticket: ticket,
                onTap: () => _showTicketDetails(context, ticket), 
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Lỗi tải lịch sử vé: $err')),
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final Ticket ticket;
  final VoidCallback onTap;

  const _TicketCard({required this.ticket, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = _formatStatus(ticket.paymentStatus);
    final statusColor = _getStatusColor(ticket.paymentStatus);
    final bool isPaid = status == 'Đã thanh toán';

    return Card(
      margin: EdgeInsets.only(bottom: 16.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      elevation: 3,
      color: theme.colorScheme.surface,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.horizontal(left: Radius.circular(12.r)),
              child: Image.network(
                ticket.movie.posterUrl,
                width: 90.w,
                height: 130.h,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(
                  width: 90.w, height: 130.h, color: Colors.grey.shade200,
                  child: const Icon(Icons.movie, color: Colors.grey),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ticket.movie.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface, // Màu chữ trên nền
                        ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8.h),
                    _InfoRow(
                      icon: Icons.confirmation_number_outlined,
                      text: 'Ghế: ${ticket.seats.map((s) => s.seatId).join(', ')}',
                    ),
                    SizedBox(height: 4.h),
                    _InfoRow(
                      icon: Icons.calendar_today_outlined,
                      text: DateFormat('dd/MM/yyyy - HH:mm').format(ticket.showDateTime),
                    ),
                    SizedBox(height: 4.h),
                    _InfoRow(
                      icon: Icons.receipt_long_outlined,
                      text: NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(ticket.totalPrice),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      'Trạng thái: $status',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    )
                  ],
                ),
              ),
            ),
            Container(
              width: 40.w,
              height: 130.h,
              decoration: BoxDecoration(
                color: isPaid ? Colors.orange.shade600 : Colors.grey.shade400,
                borderRadius: BorderRadius.horizontal(right: Radius.circular(12.r)),
              ),
              child: Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18.sp),
            ),
          ],
        ),
      ),
    );
  }
}

class _TicketDetailSheet extends ConsumerStatefulWidget {
  final Ticket ticket;
  const _TicketDetailSheet({required this.ticket});

  @override
  ConsumerState<_TicketDetailSheet> createState() => _TicketDetailSheetState();
}

class _TicketDetailSheetState extends ConsumerState<_TicketDetailSheet> {
  // Key cho RepaintBoundary
  final GlobalKey _ticketImageKey = GlobalKey(); // ✅ Sửa: Dùng final
  bool _isSaving = false;

  // @override
  // void initState() {
  //   super.initState();
  //   _ticketImageKey = GlobalKey(); // Không cần gán lại ở đây
  // }

  // ✅ HÀM CHỤP ẢNH (ĐÃ SỬA LỖI HOÀN TOÀN)
  Future<File?> _captureAndSaveTempImage() async {
    try {
      // 1. Tìm RenderObject từ GlobalKey
      final boundary = _ticketImageKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('Không thể tìm thấy RepaintBoundary.');
      }
      
      // 2. Chuyển RenderObject thành ui.Image
      // (pixelRatio 3.0 cho ảnh nét hơn)
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0); 

      // 3. Chuyển ui.Image thành ByteData (dạng PNG)
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Không thể chuyển ảnh sang ByteData.');
      }

      // 4. Chuyển ByteData thành Uint8List
      final Uint8List bytes = byteData.buffer.asUint8List();

      // 5. Lưu vào file tạm
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/ticket_${widget.ticket.id ?? DateTime.now().millisecondsSinceEpoch}.png';
      final File file = await File(filePath).writeAsBytes(bytes);
      
      print('✅ Ảnh vé tạm đã được tạo tại: ${file.path}');
      return file;

    } catch (e) {
      print("❌ Lỗi chụp hoặc lưu file tạm: $e");
      return null;
    }
  }

  // HÀM SHARE (ĐÃ CẬP NHẬT)
  Future<void> _onShare() async {
    final movie = widget.ticket.movie.title;
    final time = DateFormat('HH:mm dd/MM/yyyy').format(widget.ticket.showDateTime);
    final seats = widget.ticket.seats.map((s) => s.seatId).join(', ');
    final room = widget.ticket.roomName;
    final text = "Vé xem phim '$movie' "
        "suất $time tại ${widget.ticket.theaterName} (Phòng $room), ghế $seats. "
        "Xem cùng tôi nhé!";

    // Hiển thị loading nhỏ
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đang chuẩn bị ảnh để chia sẻ...'), duration: Duration(seconds: 2))
    );

    final File? imageFile = await _captureAndSaveTempImage();
    
    if (imageFile != null) {
      final XFile imageXFile = XFile(imageFile.path);
      await Share.shareXFiles([imageXFile], text: text, subject: 'Chia sẻ vé xem phim');
    } else {
      // Fallback: Nếu chụp ảnh lỗi, chỉ chia sẻ text
      await Share.share(text, subject: 'Chia sẻ vé xem phim');
    }
  }

  // HÀM SAVE (ĐÃ SỬA LẠI VỚI 'gal')
  Future<void> _onSave() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    String? message;
    Color? bgColor;

    try {
      // 1. Xin quyền (quan trọng)
      if (await Permission.photos.request().isDenied) {
         if (Platform.isAndroid) {
            // Thử xin quyền storage cũ hơn cho Android < 13
            if (await Permission.storage.request().isDenied) {
                throw Exception('Không được cấp quyền truy cập thư viện.');
            }
         } else {
             throw Exception('Không được cấp quyền truy cập thư viện.');
         }
      }
      
      // 2. Chụp ảnh và lấy file tạm
      final File? file = await _captureAndSaveTempImage();
      if (file == null) {
        throw Exception('Không thể tạo ảnh vé.');
      }

      // 3. LƯU: Dùng 'gal'
      await Gal.putImage(file.path, album: 'Cinema Tickets');
      
      message = 'Đã lưu vé vào thư mục "Cinema Tickets"!';
      bgColor = Colors.green;

    } catch (e) {
      message = 'Lỗi lưu vé: ${e.toString()}';
      bgColor = Colors.red;
      print("❌ Lỗi _onSave: $e"); // In lỗi chi tiết ra console
      // Nếu lỗi do từ chối quyền, mở cài đặt app
      if (e.toString().contains('Không được cấp quyền')) {
         openAppSettings();
      }
    } finally {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(message ?? 'Đã xảy ra lỗi'), backgroundColor: bgColor ?? Colors.red),
         );
         setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface, // Dùng màu nền của theme
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      
      padding: EdgeInsets.all(20.w).copyWith(bottom: MediaQuery.of(context).viewInsets.bottom + 20.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ SỬA LỖI: Dùng RepaintBoundary thay vì WidgetToImage
          RepaintBoundary(
            key: _ticketImageKey,
            child: Container(
              color: theme.colorScheme.surface,
              padding: EdgeInsets.all(16.w),
              child: Column(
                 mainAxisSize: MainAxisSize.min,
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                    // Header
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8.r),
                          child: Image.network(widget.ticket.movie.posterUrl, width: 60.w, fit: BoxFit.cover),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ✅ Sửa: Dùng màu onSurface
                              Text(widget.ticket.movie.title, style: theme.textTheme.titleLarge?.copyWith(
                                color: theme.colorScheme.onSurface,
                                fontSize: 18.sp,
                              )),
                              SizedBox(height: 4.h),
                              // ✅ Sửa: Dùng màu onSurfaceVariant (màu xám mờ)
                              Text(widget.ticket.theaterName, style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 14.sp
                              )),
                              Text( 
                                'Phòng: ${widget.ticket.roomName}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontSize: 14.sp
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24.0),
                    // Chi tiết
                    _DetailInfoRow(label: 'Ngày:', value: DateFormat('dd/MM/yyyy').format(widget.ticket.showDateTime)),
                    _DetailInfoRow(label: 'Giờ:', value: DateFormat('HH:mm').format(widget.ticket.showDateTime)),
                    _DetailInfoRow(label: 'Ghế:', value: widget.ticket.seats.map((s) => s.seatId).join(', ')),
                    _DetailInfoRow(label: 'Tổng tiền:', value: NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(widget.ticket.totalPrice)),
                    _DetailInfoRow(label: 'Thanh toán:', value: widget.ticket.paymentMethod ?? 'N/A'),
                    SizedBox(height: 16.h),
                    
                    // Mã QR (Chỉ hiển thị nếu đã thanh toán)
                    if (widget.ticket.paymentStatus.toLowerCase() == 'paid') ...[
                       Center(
                          child: QrImageView(
                             data: widget.ticket.id!,
                             version: QrVersions.auto,
                             size: 180.r,
                             eyeStyle: QrEyeStyle(color: theme.colorScheme.onSurface),
                             dataModuleStyle: QrDataModuleStyle(color: theme.colorScheme.onSurface),
                          ),
                       ),
                       SizedBox(height: 8.h),
                       Center(child: SelectableText('Mã vé: ${widget.ticket.id!}', style: const TextStyle(fontWeight: FontWeight.bold))),
                       SizedBox(height: 8.h),
                       const Center(child: Text('Vui lòng xuất trình mã QR này khi vào cổng.', textAlign: TextAlign.center, style: TextStyle(color: Colors.red))),
                    ] else ... [
                       Center(
                          child: Text(
                            'Trạng thái: ${_formatStatus(widget.ticket.paymentStatus)}',
                             style: TextStyle(color: _getStatusColor(widget.ticket.paymentStatus), fontSize: 18.sp, fontWeight: FontWeight.bold),
                          ),
                       )
                    ],
                 ],
              ),
            ),
          ),

          const Divider(height: 24.0),
          
          // Nút hành động
          Row(
             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
             children: [
                TextButton.icon(
                   icon: const Icon(Icons.share_outlined),
                   label: const Text('Chia sẻ'),
                   onPressed: _onShare,
                ),
                TextButton.icon(
                   icon: _isSaving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_alt_outlined),
                   label: const Text('Lưu vé'),
                   onPressed: _isSaving ? null : _onSave,
                ),
             ],
          ),
          SizedBox(height: bottomPadding > 0 ? bottomPadding : 16.h),
        ],
      ),
    );
  }
}

// --- WIDGET HELPER ---

// Hàng thông tin tóm tắt (trong Card)
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 14.sp),
        SizedBox(width: 6.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// Hàng thông tin chi tiết (trong BottomSheet)
class _DetailInfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        // Căn chỉnh cho label ở đầu, value ở cuối
        crossAxisAlignment: CrossAxisAlignment.start, // Căn lề trên
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Label (Giữ nguyên)
          Text(
            label,
            style: TextStyle(
              fontSize: 15.sp,
              color: theme.colorScheme.onSurfaceVariant
            )
          ),
          SizedBox(width: 16.w), // Thêm khoảng cách

          // Value (Giá trị) - Bọc bằng Expanded để tự động xuống dòng
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right, // Căn lề phải cho value
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface
              ),
              // Không cần maxLines, Expanded sẽ tự xử lý xuống dòng
            ),
          ),
        ],
      ),
    );
  }
}

// (Copy 2 hàm helper từ PaymentHistoryScreen)
Color _getStatusColor(String status) {
  status = status.toLowerCase();
  if (status == 'paid' || status == 'success') return Colors.green;
  if (status == 'pending') return Colors.orange.shade700;
  if (status.startsWith('failed') || status.startsWith('cancelled')) return Colors.red;
  return Colors.grey;
}

String _formatStatus(String status) {
  status = status.toLowerCase();
  if (status == 'paid' || status == 'success') return 'Đã thanh toán';
  if (status == 'pending') return 'Chờ thanh toán';
  if (status == 'cancelled_timeout') return 'Hủy (Timeout)';
  if (status == 'cancelled') return 'Đã hủy';
  if (status.startsWith('failed')) return 'Thất bại';
  if (status == 'refunded') return 'Đã hoàn tiền';
  return status;
}