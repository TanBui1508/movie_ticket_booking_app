// lib/screens/voucher_wallet_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart'; // Import thư viện share_plus
import '../models/voucher_model.dart';
import '../providers/voucher_provider.dart';
import '../main.dart'; // Import authStateProvider
import 'sigin_screen.dart'; // Import SignInScreen

class VoucherWalletScreen extends ConsumerStatefulWidget {
  const VoucherWalletScreen({super.key});

  @override
  ConsumerState<VoucherWalletScreen> createState() => _VoucherWalletScreenState();
}

class _VoucherWalletScreenState extends ConsumerState<VoucherWalletScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Khởi tạo TabController với 4 tab
    _tabController = TabController(length: 4, vsync: this);
    // Lắng nghe thay đổi tab để cập nhật provider filter
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
         final newFilter = VoucherFilter.values[_tabController.index];
         ref.read(voucherFilterProvider.notifier).state = newFilter;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- Hàm hiển thị dialog nhập mã ---
  void _showEnterCodeDialog(BuildContext context, WidgetRef ref) {
    final codeController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final isLoading = StateProvider<bool>((ref) => false); // Loading cho dialog

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nhập mã voucher'),
          content: Consumer( // Dùng Consumer để rebuild khi isLoading thay đổi
            builder: (context, dialogRef, _) {
              final loading = dialogRef.watch(isLoading);
              return Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: codeController,
                      decoration: const InputDecoration(hintText: 'Nhập mã...'),
                      validator: (value) => value!.isEmpty ? 'Vui lòng nhập mã' : null,
                      enabled: !loading, // Disable khi đang load
                    ),
                    if (loading) ...[
                      const SizedBox(height: 16),
                      const CircularProgressIndicator(),
                    ]
                  ],
                ),
              );
            }
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            Consumer( // Consumer cho nút Lưu
               builder: (context, dialogRef, _) {
                 final loading = dialogRef.watch(isLoading);
                 return FilledButton(
                   onPressed: loading ? null : () async {
                     if (formKey.currentState!.validate()) {
                        final userId = ref.read(authStateProvider).value?.uid;
                        if (userId != null) {
                           dialogRef.read(isLoading.notifier).state = true; // Bật loading
                           final result = await ref.read(voucherServiceProvider)
                                                .claimVoucherByCode(codeController.text, userId);
                           dialogRef.read(isLoading.notifier).state = false; // Tắt loading

                           if (context.mounted) {
                              Navigator.pop(context); // Đóng dialog
                              ScaffoldMessenger.of(context).showSnackBar(
                                 SnackBar(
                                    content: Text(result),
                                    backgroundColor: result.contains('thành công') ? Colors.green : Colors.red,
                                 ),
                              );
                           }
                        } else {
                           // Nên xử lý trường hợp user null (mặc dù màn hình này nên yêu cầu đăng nhập)
                           Navigator.pop(context);
                        }
                     }
                   },
                   child: const Text('Xác nhận'),
                 );
               }
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    // Lấy danh sách voucher đã lọc
    final filteredVouchers = ref.watch(filteredUserVouchersProvider);
    // Lấy trạng thái loading/error từ provider gốc
    final vouchersAsync = ref.watch(userVouchersProvider);
    final user = ref.watch(authStateProvider).value; // Kiểm tra đăng nhập

    if (user == null) {
       // Nếu chưa đăng nhập, hiển thị nút yêu cầu đăng nhập
       return Scaffold(
          appBar: AppBar(title: const Text('Ví Voucher')),
          body: Center(
             child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   const Text('Vui lòng đăng nhập để xem voucher của bạn.'),
                   const SizedBox(height: 16),
                   ElevatedButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SignInScreen())),
                      child: const Text('Đăng nhập'),
                   )
                ],
             ),
          ),
       );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Ví Voucher / Quà'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_card_outlined),
            tooltip: 'Nhập mã voucher',
            onPressed: () => _showEnterCodeDialog(context, ref),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).primaryColor, // Màu chữ tab được chọn
          unselectedLabelColor: Colors.grey, // Màu chữ tab không được chọn
          indicatorColor: Theme.of(context).primaryColor, // Màu gạch chân
          tabs: const [
            Tab(text: 'Tất cả'),
            Tab(text: 'Còn hạn'),
            Tab(text: 'Hết hạn'),
            Tab(text: 'Đã dùng'),
          ],
        ),
      ),
      body: vouchersAsync.when(
        data: (_) => // Dùng _ vì ta lấy data từ filteredVouchersProvider
           filteredVouchers.isEmpty
            ? Center(
                child: Text(
                  _tabController.index == 0
                      ? 'Bạn chưa có voucher nào.'
                      : 'Không có voucher trong mục này.',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(12.0).copyWith(bottom: 90), // Thêm padding dưới
                itemCount: filteredVouchers.length,
                itemBuilder: (context, index) {
                  return _VoucherCard(voucher: filteredVouchers[index]);
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Lỗi tải voucher: $err')),
      ),
    );
  }
}

// --- Widget Thẻ Voucher ---
class _VoucherCard extends ConsumerWidget {
  final Voucher voucher;

  const _VoucherCard({required this.voucher});

  // Hàm xác định màu sắc dựa trên trạng thái
  Color _getCardColor(VoucherStatus status, bool isExpiringSoon) {
    if (status == VoucherStatus.available) {
      return isExpiringSoon ? Colors.orange.shade100 : Colors.green.shade100;
    } else if (status == VoucherStatus.used) {
      return Colors.blueGrey.shade100;
    } else { // expired
      return Colors.grey.shade300;
    }
  }

   // Hàm xác định màu viền/icon dựa trên trạng thái
  Color _getBorderColor(VoucherStatus status, bool isExpiringSoon) {
    if (status == VoucherStatus.available) {
      return isExpiringSoon ? Colors.deepOrange.shade600 : Colors.green.shade700;
    } else if (status == VoucherStatus.used) {
      return Colors.blueGrey.shade600;
    } else { // expired
      return Colors.grey.shade600;
    }
  }

   // Hàm hiển thị chi tiết voucher (BottomSheet)
  void _showVoucherDetails(BuildContext context, WidgetRef ref) {
     final actualStatus = voucher.currentActualStatus;
     final borderColor = _getBorderColor(actualStatus, voucher.isExpiringSoon);

     showModalBottomSheet(
        context: context,
        isScrollControlled: true, // Cho phép sheet cao hơn
        shape: const RoundedRectangleBorder(
           borderRadius: BorderRadius.vertical(top: Radius.circular(20))
        ),
        builder: (context) {

          final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
           return Padding(
             padding: EdgeInsets.fromLTRB(20.0, 20.0, 20.0, bottomPadding > 0 ? bottomPadding : 20.0),
             child: Wrap( 
               children: [
                 Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min, // Giới hạn chiều cao
                    children: [
                       Text(voucher.title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: borderColor)),
                       const SizedBox(height: 10),
                       Text("Mã: ${voucher.code}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                       const SizedBox(height: 10),
                       Text("HSD: ${DateFormat('dd/MM/yyyy HH:mm').format(voucher.expiryDate.toDate())}", style: TextStyle(color: borderColor)),
                       const Divider(height: 20),
                       const Text("Mô tả:", style: TextStyle(fontWeight: FontWeight.bold)),
                       Text(voucher.description),
                       const SizedBox(height: 10),
                       const Text("Điều kiện:", style: TextStyle(fontWeight: FontWeight.bold)),
                       Text(voucher.conditions),
                       const SizedBox(height: 20),
                       Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            // Nút Chia sẻ
                             TextButton.icon(
                                icon: const Icon(Icons.share_outlined),
                                label: const Text('Chia sẻ'),
                                onPressed: () {
                                   final shareText = "Nhận voucher '${voucher.title}' tại Cinema App! Mã: ${voucher.code}";
                                   Share.share(shareText); // Gọi hàm share
                                },
                             ),
                             // Nút Sử dụng (chỉ hiển thị nếu còn hạn)
                             if (actualStatus == VoucherStatus.available)
                                FilledButton.icon(
                                   icon: const Icon(Icons.check_circle_outline),
                                   label: const Text('Sử dụng ngay'),
                                   style: FilledButton.styleFrom(backgroundColor: borderColor),
                                   onPressed: () async {
                                      // TODO: Gửi mã voucher vào phần thông báo hoặc state management
                                      // Tạm thời chỉ đánh dấu đã dùng và đóng sheet
                                      try {
                                         await ref.read(voucherServiceProvider).markVoucherAsUsed(voucher.id!);
                                         Navigator.pop(context); // Đóng bottom sheet
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Đã đánh dấu voucher "${voucher.code}" là đã sử dụng.'), backgroundColor: Colors.blue)
                                          );
                                      } catch (e) {
                                         ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Lỗi khi đánh dấu sử dụng: $e'), backgroundColor: Colors.red)
                                          );
                                      }
                                   },
                                ),
                          ],
                       )
                    ],
                 ),
               ],
             ),
           );
        },
     );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actualStatus = voucher.currentActualStatus;
    final cardColor = _getCardColor(actualStatus, voucher.isExpiringSoon);
    final borderColor = _getBorderColor(actualStatus, voucher.isExpiringSoon);
    final isAvailable = actualStatus == VoucherStatus.available;

    return Card(
      color: cardColor,
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: 1.5),
      ),
      child: InkWell( // Thêm InkWell để nhấn vào xem chi tiết
         onTap: () => _showVoucherDetails(context, ref),
         borderRadius: BorderRadius.circular(12), // Bo tròn hiệu ứng nhấn
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Cột Icon/Hình ảnh (tùy chọn)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: borderColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.local_offer, color: borderColor, size: 30),
              ),
              const SizedBox(width: 12),
              // Cột Thông tin chính
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      voucher.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'HSD: ${DateFormat('dd/MM/yyyy').format(voucher.expiryDate.toDate())}',
                      style: TextStyle(fontSize: 12, color: borderColor),
                    ),
                     const SizedBox(height: 6),
                     // Hiển thị nút Sử dụng ngay hoặc Trạng thái
                     isAvailable
                       ? SizedBox( // Dùng SizedBox để nút không chiếm hết chiều rộng
                           height: 30, // Chiều cao nút nhỏ
                           child: OutlinedButton(
                              onPressed: () => _showVoucherDetails(context, ref),
                              style: OutlinedButton.styleFrom(
                                 side: BorderSide(color: borderColor),
                                 foregroundColor: borderColor,
                                 padding: const EdgeInsets.symmetric(horizontal: 12),
                                 visualDensity: VisualDensity.compact,
                              ),
                              child: const Text('Xem chi tiết', style: TextStyle(fontSize: 12)),
                           ),
                       )
                       : Text( // Hiển thị trạng thái nếu không còn hạn
                           actualStatus == VoucherStatus.used ? 'ĐÃ SỬ DỤNG' : 'ĐÃ HẾT HẠN',
                           style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: borderColor,
                           ),
                        ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}