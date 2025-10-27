import 'dart:async';
import 'dart:convert';
import 'package:cinema_app_flutter/models/ticket_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:app_links/app_links.dart';
import 'package:cinema_app_flutter/screens/main_screen.dart'; 
import 'package:cinema_app_flutter/services/movie_service.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final Ticket ticket;
  final String paymentMethod; // "Momo" hoặc "VNPay"

  const PaymentScreen({
    super.key,
    required this.ticket,
    required this.paymentMethod,
  });

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  bool _isLoading = true;
  String? _qrData;
  String _statusMessage = "";
  
  // Deep link listener
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  
  // Polling timer
  Timer? _pollingTimer;
  int _pollingAttempts = 0;
  final int _maxPollingAttempts = 60; // 5 phút (mỗi 5 giây)
  
  // Backend URL
  static const String _backendUrl = 'https://cozily-unfulminating-amia.ngrok-free.dev';

  @override
  void initState() {
    super.initState();
    _initDeepLinks(); // Khởi tạo deep link listener
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startPayment();
    });
  }

  /// Khởi tạo Deep Link Listener
  void _initDeepLinks() {
    _appLinks = AppLinks();
    
    // Lắng nghe deep link khi app được mở lại từ MoMo
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      debugPrint('📱 Nhận deep link: $uri');
      _handleDeepLink(uri);
    }, onError: (err) {
      debugPrint('❌ Lỗi deep link: $err');
    });
  }

  /// Xử lý Deep Link từ MoMo
  void _handleDeepLink(Uri uri) {
    if (!mounted) return;

    debugPrint('🔍 Scheme: ${uri.scheme}, Host: ${uri.host}');
    debugPrint('🔍 Query params: ${uri.queryParameters}');

    // Kiểm tra scheme của app (ví dụ: cinemaapp://payment/result)
    if (uri.scheme == 'cinemaapp' && uri.host == 'payment') {
      final resultCode = uri.queryParameters['resultCode'];
      final message = uri.queryParameters['message'];
      final orderId = uri.queryParameters['orderId'];

      _stopPolling(); // Dừng polling nếu có

      if (resultCode == '0') {
        _showSuccessAndClose(message ?? 'Thanh toán thành công!');
      } else {
        _showErrorAndRetry(message ?? 'Thanh toán thất bại', canRetry: true);
      }
    }
  }

  /// Hiển thị thành công và đóng màn hình
  void _showSuccessAndClose(String message) async {
    if (!mounted) return;
    _stopPolling();

    // 1. Cập nhật trạng thái vé trên Firestore từ Client
    try {
      if (widget.ticket.id != null) {
        await ref.read(movieServiceProvider).updateTicketPaymentStatus(
            widget.ticket.id!,
            'paid', // Chỉ cập nhật 'paid' khi thành công
            widget.paymentMethod
        );
        debugPrint("✅ Client-side update successful for ticket ${widget.ticket.id}");
      }
    } catch (e) {
      debugPrint("⚠️ Lỗi client-side update ticket status: $e");
    }

    // 2. Hiển thị SnackBar thành công
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );

    // 3. Đợi 1 giây rồi điều hướng về MainScreen (tab Vé đã đặt)
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const MainScreen(defaultIndex: 0),
          ),
          (Route<dynamic> route) => false,
        );
      }
    });
  }

  void _showErrorAndRetry(String errorMessage, {bool canRetry = false}) {
    if (!mounted) return;
    _stopPolling(); // Dừng polling
    
    setState(() {
      _isLoading = false;
      _qrData = null;
      _statusMessage = errorMessage;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
    );
  }

  /// Hàm điều phối thanh toán
  Future<void> _startPayment() async {
    setState(() {
      _isLoading = true;
      _qrData = null;
      _statusMessage = "Đang khởi tạo thanh toán qua ${widget.paymentMethod}...";
    });

    try {
      if (widget.paymentMethod == "Momo") {
        await _handleMoMoPayment();
      } else if (widget.paymentMethod == "VNPay") {
        await _handleVNPayPayment();
      } else {
        throw Exception("Phương thức thanh toán không được hỗ trợ.");
      }
    } catch (e) {
      // ✅ SỬA LỖI 2: Gọi _showErrorAndRetry khi có lỗi
       String errorMessage = "Đã xảy ra lỗi: ${e.toString()}";
       // if (e is FirebaseFunctionsException) { // Bỏ comment nếu dùng Cloud Functions
       //    errorMessage = "Lỗi CF: ${e.message ?? e.code}";
       // }
      _showErrorAndRetry(errorMessage, canRetry: true);
    }
  }

  /// Xử lý thanh toán MoMo
  Future<void> _handleMoMoPayment() async {
  final response = await http.post(
    Uri.parse('$_backendUrl/api/payment/create-momo-payment'),
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
      'amount': widget.ticket.totalPrice.toInt(),
      'ticket_id': widget.ticket.id.toString(),
      'movie_title': widget.ticket.movie.title,
    }),
  );

  if (response.statusCode == 200) {
    final responseData = json.decode(response.body);
    final deepLink = responseData['deepLink'];
    final payUrl = responseData['payUrl'];
    final qrCodeUrl = responseData['qrCodeUrl'];

    // ✅ LOG ĐỂ DEBUG
    debugPrint('=== PAYMENT RESPONSE ===');
    debugPrint('deepLink: $deepLink');
    debugPrint('payUrl: $payUrl');
    debugPrint('qrCodeUrl: $qrCodeUrl');
    debugPrint('========================');

    // Ưu tiên 1: Deep Link
    if (deepLink != null && deepLink.isNotEmpty) {
      debugPrint('✅ Mở deep link: $deepLink');
      final uri = Uri.parse(deepLink);
      
      if (await canLaunchUrl(uri)) {
        setState(() {
          _isLoading = false;
          _statusMessage = "Đang chuyển sang ứng dụng MoMo...";
        });

        await launchUrl(uri, mode: LaunchMode.externalApplication);
        _startPollingPaymentStatus();
        return;
      } else {
        debugPrint('❌ Không thể mở deep link');
      }
    } else {
      debugPrint('⚠️ Backend không trả về deep link!');
    }

    // Ưu tiên 2: QR Code
    if (qrCodeUrl != null && qrCodeUrl.isNotEmpty) {
      debugPrint('✅ Hiển thị QR code');
      setState(() {
        _isLoading = false;
        _qrData = qrCodeUrl;
        _statusMessage = "Quét mã QR bằng ứng dụng MoMo để thanh toán.";
      });
      _startPollingPaymentStatus();
      return;
    }

      // ✅ Ưu tiên 3: PayUrl (mở trình duyệt)
      if (payUrl != null && payUrl.isNotEmpty) {
        final uri = Uri.parse(payUrl);
        if (await canLaunchUrl(uri)) {
          setState(() {
            _isLoading = false;
            _statusMessage = "Đã chuyển sang trang thanh toán MoMo...";
          });

          await launchUrl(uri, mode: LaunchMode.externalApplication);
          _startPollingPaymentStatus();
          return;
        }
      }

      throw Exception('Không nhận được link thanh toán hợp lệ từ MoMo.');
    } else {
      // Xử lý lỗi server
      String errorMessage = 'Lỗi server. Mã: ${response.statusCode}';
      try {
        final responseData = json.decode(response.body);
        final detailedError = responseData['error'] ?? responseData['Error'];
        if (detailedError != null) {
          errorMessage = detailedError;
        }
      } catch (e) {
        errorMessage = 'Lỗi server: ${response.statusCode}';
      }
      throw Exception(errorMessage);
    }
  }

  /// Bắt đầu Polling để check trạng thái thanh toán
  void _startPollingPaymentStatus() {
    _pollingTimer?.cancel();
    _pollingAttempts = 0;

    debugPrint('⏳ Bắt đầu polling payment status...');

    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      _pollingAttempts++;
      debugPrint('🔄 Polling lần ${_pollingAttempts}/$_maxPollingAttempts');

      // Kiểm tra timeout
      if (_pollingAttempts > _maxPollingAttempts) {
        timer.cancel();
        _showErrorAndRetry(
          "Hết thời gian chờ thanh toán. Vui lòng kiểm tra lại.",
          canRetry: true,
        );
        return;
      }

      // Gọi API check status
      try {
        final checkResponse = await http.get(
          Uri.parse('$_backendUrl/api/payment/check-status/${widget.ticket.id}'),
        );

        if (checkResponse.statusCode == 200) {
          final data = json.decode(checkResponse.body);
          
          if (data['isPaid'] == true) {
            timer.cancel();
            debugPrint('✅ Thanh toán thành công (từ polling)');
            _showSuccessAndClose('Thanh toán thành công!');
          } else if (data['status'] == 'failed') {
            timer.cancel();
            _showErrorAndRetry('Thanh toán thất bại. Vui lòng thử lại.', canRetry: true);
          }
        }
      } catch (e) {
        debugPrint('⚠️ Lỗi khi polling: $e');
        // Không cancel timer, tiếp tục thử
      }
    });
  }

  /// Dừng polling
  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Xử lý thanh toán VNPay
  Future<void> _handleVNPayPayment() async {
    setState(() {
      _isLoading = false;
      _statusMessage = "Chức năng thanh toán VNPay sẽ được tích hợp sau.";
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_statusMessage), backgroundColor: Colors.amber),
    );
    
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String iconPath = widget.paymentMethod == "Momo"
        ? 'assets/images/momo-logo.png'
        : 'assets/icons/vnpay_icon.png';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_isLoading ? "Đang xử lý..." : "Thanh toán ${widget.paymentMethod}"),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            _stopPolling();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(32.w),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // --- LOADING STATE ---
                if (_isLoading) ...[
                  CircularProgressIndicator(
                    strokeWidth: 5.w,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.redAccent),
                  ),
                  SizedBox(height: 40.h),
                  Image.asset(
                    iconPath,
                    height: 80.h,
                    errorBuilder: (c, e, s) => Icon(Icons.payment, size: 80.h, color: Colors.grey),
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    NumberFormat.currency(locale: 'vi_VN', symbol: 'đ')
                        .format(widget.ticket.totalPrice),
                    style: TextStyle(
                      fontSize: 32.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    _statusMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w500),
                  ),
                ],

                // --- QR CODE STATE ---
                if (!_isLoading && _qrData != null) ...[
                  Text(
                    "Quét mã để thanh toán",
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15.r),
                      border: Border.all(color: Colors.deepPurple, width: 2),
                    ),
                    child: QrImageView(
                      data: _qrData!,
                      version: QrVersions.auto,
                      size: 250.w,
                      gapless: false,
                      errorStateBuilder: (cxt, err) {
                        return const Center(
                          child: Text("Lỗi tạo mã QR", textAlign: TextAlign.center),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    NumberFormat.currency(locale: 'vi_VN', symbol: 'đ')
                        .format(widget.ticket.totalPrice),
                    style: TextStyle(
                      fontSize: 32.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    _statusMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16.sp, color: Colors.black54),
                  ),
                  SizedBox(height: 30.h),
                  const CircularProgressIndicator(),
                  SizedBox(height: 10.h),
                  Text(
                    "Đang chờ xác nhận thanh toán... (${_pollingAttempts}/$_maxPollingAttempts)",
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],

                // --- ERROR STATE ---
                if (!_isLoading && _qrData == null) ...[
                  Image.asset(
                    iconPath,
                    height: 80.h,
                    errorBuilder: (c, e, s) => Icon(
                      Icons.error_outline,
                      size: 80.h,
                      color: Colors.red,
                    ),
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    NumberFormat.currency(locale: 'vi_VN', symbol: 'đ')
                        .format(widget.ticket.totalPrice),
                    style: TextStyle(
                      fontSize: 32.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    _statusMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.red,
                    ),
                  ),
                  SizedBox(height: 50.h),
                  ElevatedButton(
                    onPressed: _startPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 15.h),
                    ),
                    child: const Text("Thử lại"),
                  ),
                  SizedBox(height: 10.h),
                  TextButton(
                    onPressed: () {
                      _stopPolling();
                      Navigator.of(context).pop();
                    },
                    child: const Text("Đổi phương thức khác"),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}