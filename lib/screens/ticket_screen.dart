import 'dart:ui';
import 'package:cinema_app_flutter/main.dart';
import 'package:cinema_app_flutter/models/ticket_seat.dart';
import 'package:cinema_app_flutter/models/voucher_model.dart';
import 'package:cinema_app_flutter/providers/voucher_provider.dart';
import 'package:cinema_app_flutter/screens/payment_screen.dart';
import 'package:cinema_app_flutter/services/movie_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/ticket_model.dart';
import 'package:collection/collection.dart';

class TicketScreen extends ConsumerStatefulWidget {
  final Ticket ticket;
  const TicketScreen({super.key, required this.ticket});

  @override
  ConsumerState<TicketScreen> createState() => _TicketScreenState();
}

class _TicketScreenState extends ConsumerState<TicketScreen> {
  bool _showAllSeats = false;
  String? _selectedPaymentMethod;
  final _voucherCodeController = TextEditingController(); 
  Voucher? _appliedVoucher; 
  double _discountAmount = 0.0; 

  bool _isApplyingVoucher = false; // Biến trạng thái loading

  @override
  void dispose() {
    _voucherCodeController.dispose();
    super.dispose();
  }

  Future<void> _applyVoucher() async {
    // 1. Ngăn spam click
    if (_isApplyingVoucher) return;

    final code = _voucherCodeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập mã voucher'), backgroundColor: Colors.orange),
      );
      return;
    }

    final userId = ref.read(authStateProvider).value?.uid;
    if (userId == null) return; 

    setState(() { _isApplyingVoucher = true; });

    String? successMsg;
    String? errorMsg;

    try {
      // Giả lập độ trễ mạng
      await Future.delayed(const Duration(seconds: 1));

      Voucher? foundVoucher;
      final userVouchers = ref.read(userVouchersProvider).value ?? [];
      
      // ✅✅ SỬA LỖI Ở ĐÂY: Bỏ comment và dùng 'firstWhereOrNull'
      foundVoucher = userVouchers.firstWhereOrNull( 
        (v) => v.code.toUpperCase() == code && v.currentActualStatus == VoucherStatus.available,
      );

      if (foundVoucher != null) {
        // ✅ KHỐI NÀY SẼ CHẠY KHI TÌM THẤY
        // Tính toán giảm giá
        double discount = 0;
        if (foundVoucher.type == VoucherType.percent) {
          discount = widget.ticket.totalPrice * (foundVoucher.value / 100);
          // (Tùy chọn) Giới hạn giảm giá tối đa
          // if (discount > foundVoucher.maxDiscount) discount = foundVoucher.maxDiscount;
        } else { // fixedAmount
          discount = foundVoucher.value;
        }
        
        // Đảm bảo không giảm giá nhiều hơn tổng tiền
        discount = discount > widget.ticket.totalPrice ? widget.ticket.totalPrice : discount;

        setState(() {
          _appliedVoucher = foundVoucher;
          _discountAmount = discount;
        });
        successMsg = 'Áp dụng voucher "${foundVoucher.title}" thành công!';
      } else {
        // ✅ KHỐI NÀY SẼ CHẠY KHI KHÔNG TÌM THẤY
        errorMsg = 'Mã voucher không hợp lệ, đã hết hạn hoặc đã sử dụng.';
        setState(() { 
          _appliedVoucher = null;
          _discountAmount = 0.0;
        });
      }
    } catch (e) {
      errorMsg = "Đã xảy ra lỗi: $e";
    } finally {
      if (mounted) {
        setState(() { _isApplyingVoucher = false; });
      }

      if (mounted && successMsg != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMsg), backgroundColor: Colors.green),
        );
      }
      if (mounted && errorMsg != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
      }
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticketData = widget.ticket;

    return Scaffold(
      // ✅ SỬ DỤNG STACK ĐỂ CÓ NỀN MỜ
      body: Stack(
        fit: StackFit.expand,
        children: [
          // LỚP 1: NỀN MỜ
          _buildBackground(ticketData.movie.bannerUrl),

          // LỚP 2: NỘI DUNG
          SafeArea(
            child: Column(
              children: [
                AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  title: Text(ticketData.movie.title,
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  centerTitle: true,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        SizedBox(height: 10.h),
                        _buildTicketBody(ticketData),
                        SizedBox(height: 30.h),
                        //_buildPaymentArea(ticketData),
                        _buildPaymentDetailsAndAction(),
                        SizedBox(height: 20.h),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ WIDGET NỀN MỜ
  Widget _buildBackground(String posterUrl) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(posterUrl,
            fit: BoxFit.cover, errorBuilder: (c, e, s) => const SizedBox()),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
          child: Container(color: Colors.black.withOpacity(0.6)),
        ),
      ],
    );
  }

  Widget _buildTicketBody(Ticket ticketData) {
    return Center(
      child: ClipPath(
        clipper: TicketClipper(notchRadius: 15.r),
        child: Container(
          width: 330.w,
          color: Colors.white.withOpacity(0.95), // Hơi trong suốt
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10.r),
                  child: Image.network(
                    ticketData.movie.posterUrl,
                    height: 160.h,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                        height: 160.h,
                        color: Colors.grey,
                        child: const Icon(Icons.movie)),
                  ),
                ),
                SizedBox(height: 20.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Hàng 1: Date + Time ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildInfoColumn(
                            'DATE',
                            DateFormat('dd/MM/yyyy')
                                .format(ticketData.showDateTime),
                          ),
                          _buildInfoColumn(
                            'TIME',
                            DateFormat('HH:mm').format(ticketData.showDateTime),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),

                      // --- Hàng 2: Theater ---
                      _buildInfoColumn(
                        'THEATER',
                        ticketData.theaterName,
                        maxWidth: double.infinity, // full width
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.h),
                  child: const DottedLineSeparator(),
                ),
                ...ticketData.seats
                    .take(_showAllSeats ? ticketData.seats.length : 3)
                    .map((seat) => Padding(
                          padding: EdgeInsets.only(bottom: 12.h),
                          child: _buildSeatRow(seat),
                        )),
                if (ticketData.seats.length > 3)
                  GestureDetector(
                    onTap: () => setState(() => _showAllSeats = !_showAllSeats),
                    child: Container(
                      padding: EdgeInsets.all(6.r),
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.redAccent.withOpacity(0.8)),
                      child: Icon(
                          _showAllSeats
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: Colors.white,
                          size: 20.sp),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value, {double? maxWidth}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
            color: Colors.grey[600],
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 4.h),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth ?? 120.w),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            overflow:
                TextOverflow.ellipsis, // chỉ thêm "..." khi vượt chiều ngang
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildSeatRow(TicketSeat seat) {
    return Row(
      children: [
        Icon(Icons.event_seat, size: 18.sp, color: Colors.grey.shade600),
        SizedBox(width: 8.w),
        Text('Ghế ${seat.seatId}',
            style: TextStyle(fontSize: 14.sp, color: Colors.black87)),
        const Spacer(),
        Text(
          NumberFormat.currency(locale: 'vi_VN', symbol: 'đ')
              .format(seat.price),
          style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87),
        ),
      ],
    );
  }

  // Widget _buildPaymentArea(Ticket ticketData) {
  //   return Padding(
  //     padding: EdgeInsets.symmetric(horizontal: 24.w),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Text('Chọn phương thức thanh toán', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white)),
  //         SizedBox(height: 12.h),
  //         _buildPaymentMethodSelector(),
  //         SizedBox(height: 20.h),
  //         TextFormField(
  //           decoration: InputDecoration(
  //             hintText: 'Nhập mã giảm giá',
  //             hintStyle: TextStyle(color: Colors.grey.shade500),
  //             filled: true,
  //             fillColor: Colors.white.withOpacity(0.9),
  //             border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: BorderSide.none),
  //             contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
  //             suffixIcon: Icon(Icons.confirmation_num_outlined, color: Colors.grey.shade500),
  //           ),
  //         ),
  //         SizedBox(height: 20.h),
  //         Container(
  //           padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
  //           decoration: BoxDecoration(
  //             color: Colors.white.withOpacity(0.9),
  //             borderRadius: BorderRadius.circular(10.r),
  //           ),
  //           child: Row(
  //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //             children: [
  //               Text('Total', style: TextStyle(fontSize: 16.sp, color: Colors.black87)),
  //               Text(
  //                 NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(ticketData.totalPrice),
  //                 style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.black87),
  //               ),
  //             ],
  //           ),
  //         ),
  //         SizedBox(height: 24.h),
  //         Container(
  //           width: double.infinity,
  //           decoration: BoxDecoration(
  //             gradient: LinearGradient(
  //               colors: [Colors.orange.shade700, Colors.redAccent.shade700],
  //               begin: Alignment.centerLeft,
  //               end: Alignment.centerRight,
  //             ),
  //             borderRadius: BorderRadius.circular(15.r),
  //             boxShadow: [BoxShadow(color: Colors.redAccent.withOpacity(0.4), spreadRadius: 2, blurRadius: 8, offset: const Offset(0, 4))],
  //           ),
  //           child: ElevatedButton(
  //             onPressed: () {
  //               if (_selectedPaymentMethod == null) {
  //                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn phương thức thanh toán!'), backgroundColor: Colors.red));
  //               } else {
  //                 Navigator.push(
  //                   context,
  //                   MaterialPageRoute(
  //                     builder: (context) => PaymentScreen(ticket: ticketData, paymentMethod: _selectedPaymentMethod!
  //                   ),
  //                 ));
  //               }
  //             },
  //             style: ElevatedButton.styleFrom(
  //               backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
  //               padding: EdgeInsets.symmetric(vertical: 16.h),
  //               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
  //             ),
  //             child: Text('PAY', style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: Colors.white)),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildPaymentDetailsAndAction() {
    final ticketData = widget.ticket;
    final double originalPrice = ticketData.totalPrice; 
    final double finalPrice = originalPrice - _discountAmount;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Phần Mã giảm giá ---
          Text('Mã giảm giá',
              style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          SizedBox(height: 12.h),
          Row(
            // Dùng Row để có nút Apply
            children: [
              Expanded(
                child: TextFormField(
                  controller: _voucherCodeController,
                  decoration: InputDecoration(
                    hintText: 'Nhập mã giảm giá',
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.9),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.r),
                        borderSide: BorderSide.none),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    suffixIcon: Icon(Icons.confirmation_num_outlined,
                        color: Colors.grey.shade500),
                  ),
                  textCapitalization:
                      TextCapitalization.characters, // Tự viết hoa
                  // Disable nếu đã áp dụng voucher thành công
                  enabled: _appliedVoucher == null,
                ),
              ),
              SizedBox(width: 8.w),
              ElevatedButton(
                onPressed: _appliedVoucher == null
                    ? _applyVoucher
                    : null, // Disable nút nếu đã áp dụng
                style: ElevatedButton.styleFrom(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 13.h),
                  backgroundColor: _appliedVoucher == null
                      ? Colors.amber.shade700
                      : Colors.grey,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Áp dụng'),
              ),
            ],
          ),
          // Hiển thị thông tin voucher đã áp dụng (nếu có)
          if (_appliedVoucher != null) ...[
            SizedBox(height: 8.h),
            Text(
              'Đã áp dụng: ${_appliedVoucher!.title} (-${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(_discountAmount)})',
              style: TextStyle(color: Colors.green.shade300, fontSize: 13.sp),
            ),
            // Nút xóa voucher đã áp dụng
            TextButton.icon(
              icon: Icon(Icons.clear,
                  size: 14.sp, color: Colors.redAccent.shade100),
              label: Text('Xóa mã',
                  style: TextStyle(
                      color: Colors.redAccent.shade100, fontSize: 13.sp)),
              style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact),
              onPressed: () => setState(() {
                _appliedVoucher = null;
                _discountAmount = 0.0;
                _voucherCodeController.clear();
              }),
            )
          ],
          SizedBox(height: 20.h),

          // --- Phần Chọn phương thức thanh toán ---
          Text('Chọn phương thức thanh toán',
              style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          SizedBox(height: 12.h),
          _buildPaymentMethodSelector(), // Hàm này giữ nguyên
          SizedBox(height: 20.h),

          // --- Phần Tổng tiền cuối cùng ---
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Thanh toán',
                    style: TextStyle(fontSize: 16.sp, color: Colors.black87)),
                Text(
                  NumberFormat.currency(locale: 'vi_VN', symbol: 'đ')
                      .format(finalPrice), // ✅ Hiển thị giá cuối cùng
                  style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent.shade700), // Màu đỏ đậm hơn
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),

          // --- Nút Pay ---
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.shade700, Colors.redAccent.shade700],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(15.r),
              boxShadow: [
                BoxShadow(
                    color: Colors.redAccent.withOpacity(0.4),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 4))
              ],
            ),
            child: ElevatedButton(
              onPressed: (_selectedPaymentMethod !=
                      null) // Chỉ cần chọn phương thức là bật nút
                  ? () async {
                      // ✅ CHUYỂN SANG ASYNC
                      if (_selectedPaymentMethod == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Vui lòng chọn phương thức thanh toán!'),
                                backgroundColor: Colors.red));
                        return; // Dừng lại nếu chưa chọn
                      }

                      // 1. LẤY USER ID (Đảm bảo user đã đăng nhập - nên có check trước đó)
                      final user = ref.read(authStateProvider).value;
                      if (user == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Lỗi: Không tìm thấy người dùng.')));
                        return;
                      }

                      // 2. TẠO VÉ VỚI USER ID VÀ TRẠNG THÁI PENDING
                      // (Đảm bảo ticket object có đủ thông tin trước khi lưu)
                      final ticketToSave = Ticket(
                        userId: user.uid, // Gán userId thật
                        movie: ticketData.movie,
                        showtimeId: ticketData.showtimeId,
                        roomId: ticketData.roomId,
                        roomName: ticketData.roomName,
                        theaterName: ticketData.theaterName,
                        showDateTime: ticketData.showDateTime,
                        seats: ticketData.seats,
                        originalPrice: originalPrice,   
                        discountAmount: _discountAmount, 
                        totalPrice: finalPrice,
                        bookingTime: DateTime.now(),
                        paymentStatus: 'pending', // Trạng thái ban đầu
                        paymentMethod:
                            _selectedPaymentMethod, // Lưu phương thức đã chọn
                        appliedVoucherId: _appliedVoucher
                            ?.id, // ID của doc trong user_vouchers
                        appliedVoucherCode: _appliedVoucher?.code,
                        // id: null // ID sẽ được Firestore tạo
                      );

                      // 3. LƯU VÉ VÀO FIRESTORE ĐỂ LẤY ID
                      String? savedTicketId;
                      try {
                        // Hiển thị loading (tùy chọn)
                        // showDialog(context: context, builder: (_) => Center(child: CircularProgressIndicator()));
                        savedTicketId = await ref
                            .read(movieServiceProvider)
                            .saveTicket(ticketToSave);
                        // Navigator.pop(context); // Tắt loading
                      } catch (e) {
                        // Navigator.pop(context); // Tắt loading
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Lỗi lưu vé: $e'),
                            backgroundColor: Colors.red));
                        return; // Dừng nếu lưu lỗi
                      }

                      // 4. TẠO LẠI TICKET OBJECT VỚI ID ĐÃ CÓ
                      final savedTicket = Ticket(
                        id: savedTicketId, // ✅ Gán ID đã lưu
                        userId: ticketToSave.userId,
                        movie: ticketToSave.movie,
                        showtimeId: ticketToSave.showtimeId,
                        roomId: ticketToSave.roomId,
                        roomName: ticketToSave.roomName,
                        theaterName: ticketToSave.theaterName,
                        showDateTime: ticketToSave.showDateTime,
                        seats: ticketToSave.seats,
                        originalPrice: ticketToSave.originalPrice,
                        discountAmount: ticketToSave.discountAmount,
                        totalPrice: ticketToSave.totalPrice,
                        bookingTime: ticketToSave.bookingTime,
                        paymentStatus: ticketToSave.paymentStatus,
                        paymentMethod: ticketToSave.paymentMethod,
                        appliedVoucherId: ticketToSave.appliedVoucherId, 
                        appliedVoucherCode: ticketToSave.appliedVoucherCode,
                      );

                      // 5. ĐIỀU HƯỚNG SANG PAYMENTSCREEN VỚI VÉ ĐÃ CÓ ID
                      // Sử dụng pushReplacement để không quay lại màn hình này sau khi thanh toán xong
                      // Hoặc dùng push và xử lý pop nhiều lần trong PaymentScreen
                      final paymentResult = await Navigator.push<bool>(
                        // Chờ kết quả trả về từ PaymentScreen
                        context,
                        MaterialPageRoute(
                          builder: (context) => PaymentScreen(
                              ticket: savedTicket, // ✅ Truyền vé đã có ID
                              paymentMethod: _selectedPaymentMethod!),
                        ),
                      );

                      // 6. XỬ LÝ KẾT QUẢ TRẢ VỀ (TÙY CHỌN)
                      if (paymentResult == true && context.mounted) {
                        // Thanh toán thành công, có thể pop màn hình này hoặc điều hướng đi đâu đó
                        print(
                            "🎉 Thanh toán thành công, quay lại từ PaymentScreen!");
                        // Navigator.pop(context); // Ví dụ: Quay về màn hình trước (BookingScreen)
                        // Hoặc hiển thị màn hình vé của tôi...
                      } else {
                        // Thanh toán thất bại hoặc người dùng bấm back
                        print("🤔 Thanh toán không thành công hoặc bị hủy.");
                        // Có thể không cần làm gì, người dùng vẫn ở TicketScreen
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.r)),
              ),
              child: Text('PAY',
                  style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSelector() {
    // ✅ CẬP NHẬT DANH SÁCH THANH TOÁN
    final List<String> methods = ['Momo', 'VNPay'];
    return Wrap(
      spacing: 10.w,
      runSpacing: 10.h,
      children: methods.map((method) {
        final bool isSelected = _selectedPaymentMethod == method;
        return ChoiceChip(
          label: Text(method,
              style:
                  TextStyle(color: isSelected ? Colors.white : Colors.black87)),
          selected: isSelected,
          onSelected: (selected) =>
              setState(() => _selectedPaymentMethod = selected ? method : null),
          selectedColor: Colors.redAccent,
          backgroundColor: Colors.white,
          side: BorderSide(
              color: isSelected ? Colors.redAccent : Colors.grey.shade400,
              width: 1.w),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        );
      }).toList(),
    );
  }
}

class TicketClipper extends CustomClipper<Path> {
  final double notchRadius;
  TicketClipper({required this.notchRadius});

  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, notchRadius);
    path.arcToPoint(Offset(notchRadius, 0),
        radius: Radius.circular(notchRadius), clockwise: false);
    path.lineTo(size.width - notchRadius, 0);
    path.arcToPoint(Offset(size.width, notchRadius),
        radius: Radius.circular(notchRadius), clockwise: false);
    path.lineTo(size.width, size.height - notchRadius);
    path.arcToPoint(Offset(size.width - notchRadius, size.height),
        radius: Radius.circular(notchRadius), clockwise: false);
    path.lineTo(notchRadius, size.height);
    path.arcToPoint(Offset(0, size.height - notchRadius),
        radius: Radius.circular(notchRadius), clockwise: false);

    // Add notches
    for (double i = notchRadius * 2;
        i < size.height - notchRadius;
        i += notchRadius * 2.5) {
      path.moveTo(0, i);
      path.arcTo(
          Rect.fromCircle(
              center: Offset(0, i + notchRadius), radius: notchRadius),
          1.5 * 3.14159,
          1 * 3.14159,
          false);
      path.moveTo(size.width, i);
      path.arcTo(
          Rect.fromCircle(
              center: Offset(size.width, i + notchRadius), radius: notchRadius),
          1.5 * 3.14159,
          -1 * 3.14159,
          false);
    }

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class DottedLineSeparator extends StatelessWidget {
  const DottedLineSeparator({super.key});
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 5.0;
        const dashHeight = 1.0;
        const dashSpace = 3.0;
        final dashCount = (boxWidth / (dashWidth + dashSpace)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return const SizedBox(
              width: dashWidth,
              height: dashHeight,
              child:
                  DecoratedBox(decoration: BoxDecoration(color: Colors.grey)),
            );
          }),
        );
      },
    );
  }
}
