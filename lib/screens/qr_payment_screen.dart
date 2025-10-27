import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class QrPaymentScreen extends StatelessWidget {
  final String qrData;
  final String? deepLink; // Link để mở app
  final double amount;

  const QrPaymentScreen({
    super.key,
    required this.qrData,
    this.deepLink,
    required this.amount,
  });

  // Hàm để thử mở app MoMo
  Future<void> _launchMoMoApp(BuildContext context) async {
    if (deepLink != null && deepLink!.isNotEmpty) {
      final uri = Uri.parse(deepLink!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể mở ứng dụng MoMo.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quét mã QR MoMo'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(32.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/momo-logo.png', height: 60.h),
              SizedBox(height: 16.h),
              Text(
                NumberFormat.currency(locale: 'vi_VN', symbol: 'đ')
                    .format(amount),
                style: TextStyle(
                  fontSize: 32.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
              ),
              SizedBox(height: 24.h),

              // Đây là Widget tạo mã QR
              if (qrData.isNotEmpty)
                QrImageView(
                  data: qrData, // Dữ liệu từ API MoMo
                  version: QrVersions.auto,
                  size: 250.w,
                  embeddedImage:
                      const AssetImage('assets/images/momo-logo.png'),
                  embeddedImageStyle: QrEmbeddedImageStyle(
                    size: Size(40.w, 40.w),
                  ),
                  errorStateBuilder: (cxt, err) {
                    return const Center(
                      child: Text(
                        'Không thể tạo mã QR.',
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                )
              else
                // Hiển thị nếu không có data QR
                const Text('Không nhận được dữ liệu QR Code từ MoMo.'),
              
              SizedBox(height: 24.h),
              const Text(
                'Sử dụng ứng dụng MoMo hoặc ứng dụng Ngân hàng hỗ trợ VietQR để quét mã.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 32.h),

              // Nút để mở app (thay vì quét)
              if (deepLink != null && deepLink!.isNotEmpty)
                ElevatedButton(
                  onPressed: () => _launchMoMoApp(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink[600], // Màu MoMo
                    foregroundColor: Colors.white,
                    padding:
                        EdgeInsets.symmetric(horizontal: 40.w, vertical: 12.h),
                  ),
                  child: const Text('Mở ứng dụng MoMo'),
                ),

              // TODO: Bạn có thể thêm nút "Lưu ảnh QR" ở đây
              // (Sử dụng thư viện gallery_saver hoặc screenshot)
            ],
          ),
        ),
      ),
    );
  }
}