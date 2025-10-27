import 'dart:async';
import 'package:cinema_app_flutter/main.dart';
import 'package:cinema_app_flutter/models/cinema_model.dart';
import 'package:cinema_app_flutter/models/room_model.dart';
import 'package:cinema_app_flutter/models/showtime_model.dart';
import 'package:cinema_app_flutter/models/seat.dart';
import 'package:cinema_app_flutter/models/ticket_model.dart';
import 'package:cinema_app_flutter/models/ticket_seat.dart';
import 'package:cinema_app_flutter/screens/sigin_screen.dart';
import 'package:cinema_app_flutter/screens/ticket_screen.dart';
import 'package:cinema_app_flutter/services/movie_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';


// ✅ Provider tự động lấy sơ đồ ghế theo Room và Showtime
// final seatLayoutProvider = FutureProvider.family<List<List<Seat>>, Showtime>((ref, showtime) async {
//   final room = await ref.watch(roomProvider(showtime.roomId).future);
//   List<List<Seat>> layout = [];
//   int rowCount = 0;

//   for (int seatsInRow in room.seatMap) {
//     String rowLabel = String.fromCharCode('A'.codeUnitAt(0) + rowCount);
//     List<Seat> row = List.generate(seatsInRow, (seatIndex) {
//       final seatId = '$rowLabel${seatIndex + 1}';
//       return Seat(
//         id: seatId,
//         status: showtime.bookedSeats.contains(seatId)
//             ? SeatStatus.sold
//             : SeatStatus.available,
//       );
//     });
//     layout.add(row);
//     rowCount++;
//   }
//   return layout;
// });

// ✅ SỬA LẠI PROVIDER NÀY ĐỂ HIỆU QUẢ HƠN VÀ TỰ ĐỘNG CẬP NHẬT
final seatLayoutProvider = FutureProvider.autoDispose.family<List<List<Seat>>, String>((ref, showtimeId) async {
  
  // 1. Lắng nghe (watch) stream của CHỈ MỘT suất chiếu
  //    .future sẽ tự động xử lý loading/error.
  //    Khi stream này cập nhật (ghế được bán), provider này sẽ tự động chạy lại
  final showtime = await ref.watch(showtimeStreamProvider(showtimeId).future);

  // 2. Chờ (await) cho đến khi roomProvider CÓ DỮ LIỆU.
  final room = await ref.watch(roomProvider(showtime.roomId).future);
  
  // 3. Tạo layout (code cũ của bạn)
  List<List<Seat>> layout = [];
  int rowCount = 0;

  for (int seatsInRow in room.seatMap) {
    String rowLabel = String.fromCharCode('A'.codeUnitAt(0) + rowCount);
    List<Seat> row = List.generate(seatsInRow, (seatIndex) {
      final seatId = '$rowLabel${seatIndex + 1}';
      return Seat(
        id: seatId,
        // Dùng showtime MỚI NHẤT (đã lấy từ .future) để kiểm tra
        status: showtime.bookedSeats.contains(seatId) 
            ? SeatStatus.sold
            : SeatStatus.available,
      );
    });
    layout.add(row);
    rowCount++;
  }
  return layout;
});



// -------------------- MAIN SCREEN --------------------
class SeatSelectionScreen extends ConsumerStatefulWidget {
  final String movieTitle;
  final Showtime showtime;

  const SeatSelectionScreen({
    super.key,
    required this.movieTitle,
    required this.showtime,
  });

  @override
  ConsumerState<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends ConsumerState<SeatSelectionScreen> {
  List<Seat> _selectedSeats = [];
  Timer? _timer;
  int _countdown = 300; // 5 phút = 300 giây

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        timer.cancel();
        if (Navigator.canPop(context)) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã hết thời gian giữ ghế!'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onSeatTap(Seat seat) {
    if (seat.status == SeatStatus.sold) return;

    setState(() {
      if (seat.status == SeatStatus.available) {
        seat.status = SeatStatus.selected;
        _selectedSeats.add(seat);
      } else if (seat.status == SeatStatus.selected) {
        seat.status = SeatStatus.available;
        _selectedSeats.remove(seat);
      }
    });
  }

  String get formattedCountdown {
    int minutes = _countdown ~/ 60;
    int seconds = _countdown % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // ✅ SỬA Ở ĐÂY: Watch provider mới bằng ID
    final seatLayoutAsync = ref.watch(seatLayoutProvider(widget.showtime.id!));
    
    // Các provider khác giữ nguyên
    final roomAsync = ref.watch(roomProvider(widget.showtime.roomId));
    final authState = ref.watch(authStateProvider);
    final movieAsync = ref.watch(movieDetailProvider(widget.showtime.movieId));

    // ✅ BỌC SCAFFOLD BẰNG WILLPOPSCOPE ĐỂ XỬ LÝ NÚT BACK
    return WillPopScope(
      onWillPop: () async {
        if (_selectedSeats.isNotEmpty) {
          // Nếu có ghế đang chọn → hỏi người dùng
          final shouldLeave = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Xác nhận'),
              content: const Text('Những ghế đã chọn sẽ mất. Bạn có chắc muốn quay lại không?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false), // Không
                  child: const Text('Ở lại'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true), // Có
                  child: const Text('Rời khỏi', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
          // Nếu shouldLeave là true, tự động reset ghế
          if (shouldLeave == true) {
             _resetSelectedSeats(seatLayoutAsync.value); // Gọi hàm reset
          }
          return shouldLeave ?? false; // Cho phép thoát nếu shouldLeave là true
        }
        // Nếu chưa chọn ghế → thoát bình thường
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1E1E1E),
        appBar: _buildAppBar(),
        body: Column(
          children: [
            _buildShowtimeHeader(roomAsync),
            SizedBox(height: 24.h),
            _buildScreenRepresentation(),
            SizedBox(height: 24.h),
            _buildSeatLegend(),
            SizedBox(height: 16.h),
            Expanded(
              child: seatLayoutAsync.when(
                data: (layout) {
                   // ✅ LOGIC: Reset lại _selectedSeats nếu layout thay đổi (ghế bị bán)
                   WidgetsBinding.instance.addPostFrameCallback((_) {
                      _syncSelectedSeatsWithLayout(layout);
                   });

                   return _buildSeatMap(layout);
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) {
                   print(stack); 
                   return Center(
                      child: Text('Lỗi tải sơ đồ ghế: $err', style: const TextStyle(color: Colors.red)),
                   );
                },
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildFooter(context, authState, movieAsync, roomAsync),
      ),
    );
  }

  // ✅ HÀM MỚI: Đồng bộ _selectedSeats với layout mới
  void _syncSelectedSeatsWithLayout(List<List<Seat>> layout) {
      final List<Seat> stillSelected = [];
      bool seatsChanged = false;
      
      // Lấy danh sách ghế đã bán từ layout mới (chỉ ID)
      final Set<String> soldSeatIds = {};
      for (var row in layout) {
        for (var seat in row) {
           if (seat.status == SeatStatus.sold) {
              soldSeatIds.add(seat.id);
           }
        }
      }

      // Kiểm tra các ghế đang chọn (màu xanh)
      for (var selectedSeat in _selectedSeats) {
        if (soldSeatIds.contains(selectedSeat.id)) {
           // Ghế này vừa bị người khác mua (hoặc do thanh toán thành công)
           seatsChanged = true;
        } else {
           // Ghế này vẫn còn trống, tìm nó trong layout mới
           Seat? newLayoutSeat;
           try {
              final rowLabel = selectedSeat.id[0];
              final rowIndex = rowLabel.codeUnitAt(0) - 'A'.codeUnitAt(0);
              final seatIndex = int.parse(selectedSeat.id.substring(1)) - 1;
              newLayoutSeat = layout[rowIndex][seatIndex];
           } catch(e) { /* Lỗi parse (không tìm thấy) */ }

           if (newLayoutSeat != null) {
              newLayoutSeat.status = SeatStatus.selected; // Giữ trạng thái màu xanh
              stillSelected.add(newLayoutSeat);
           } else {
             seatsChanged = true; // Ghế không còn tồn tại?
           }
        }
      }

      // Chỉ setState nếu có thay đổi và widget còn mounted
      if (seatsChanged && mounted) {
        setState(() {
            _selectedSeats = stillSelected; // Cập nhật lại list ghế xanh
        });
      }
  }
  
  // ✅ HÀM MỚI: Reset ghế đã chọn (khi bấm back)
  void _resetSelectedSeats(List<List<Seat>>? layout) {
     if (layout != null) {
        // Đặt lại status của các ghế đang chọn (xanh lá) về available (trắng/vàng)
        for (var seat in _selectedSeats) {
           // Tìm ghế tương ứng trong layout (vì _selectedSeats có thể là object cũ)
           try {
              final rowLabel = seat.id[0];
              final rowIndex = rowLabel.codeUnitAt(0) - 'A'.codeUnitAt(0);
              final seatIndex = int.parse(seat.id.substring(1)) - 1;
              layout[rowIndex][seatIndex].status = SeatStatus.available;
           } catch(e) { /* Bỏ qua */ }
        }
     }
     if (mounted) {
       setState(() {
         _selectedSeats.clear(); // Xóa list ghế xanh
       });
     }
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
      title: const Text('Chọn ghế'),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Center(
            child: Row(
              children: [
                const Text('Thời gian còn lại: '),
                Text(
                  formattedCountdown,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShowtimeHeader(AsyncValue<Room> roomAsync) {
    final formattedDate =
        DateFormat('dd/MM/yyyy').format(widget.showtime.startTime);
    final time = DateFormat('HH:mm').format(widget.showtime.startTime);

    return Container(
      color: Colors.black,
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Center(
        child: roomAsync.when(
          data: (room) => Text(
            '${room.name} | $formattedDate - $time',
            style: TextStyle(color: Colors.white70, fontSize: 16.sp),
          ),
          loading: () => const SizedBox(),
          error: (_, __) => const SizedBox(),
        ),
      ),
    );
  }

  Widget _buildScreenRepresentation() {
    return Column(
      children: [
        Container(
          height: 20,
          width: 250,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 2),
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(30)),
          ),
        ),
        const Text('MÀN HÌNH',
            style: TextStyle(color: Colors.white, letterSpacing: 5)),
      ],
    );
  }

  Widget _buildSeatLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _legendItem('Đang chọn', Colors.green, Icons.event_seat),
        _legendItem('Đã bán', Colors.red, Icons.event_seat),
        _legendItem('Thường', Colors.white, Icons.event_seat),
        _legendItem('VIP', Colors.amber, Icons.event_seat),
      ],
    );
  }

  Widget _legendItem(String label, Color color, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }

  Widget _buildSeatMap(List<List<Seat>> seatLayout) {
    int maxCols = seatLayout.fold(0, (max, row) => row.length > max ? row.length : max);

    return InteractiveViewer(
      maxScale: 3.0,
      minScale: 0.8,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(maxCols + 2, (index) {
                if (index == 0 || index == maxCols + 1) return SizedBox(width: 28.w);
                return SizedBox(
                  width: 28.w,
                  child: Center(
                    child: Text(
                      '$index',
                      style: TextStyle(color: Colors.white70, fontSize: 12.sp),
                    ),
                  ),
                );
              }),
            ),
            SizedBox(height: 8.h),
            ...seatLayout.asMap().entries.map((entry) {
              int rowIndex = entry.key;
              List<Seat> row = entry.value;
              String rowLabel =
                  String.fromCharCode('A'.codeUnitAt(0) + rowIndex);

              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 28.w,
                    child: Center(
                      child: Text(rowLabel,
                          style:
                              TextStyle(color: Colors.white70, fontSize: 12.sp)),
                    ),
                  ),
                  ...List.generate(
                      (maxCols - row.length) ~/ 2, (_) => SizedBox(width: 28.w)),
                  ...row
                      .map((seat) =>
                          _SeatWidget(seat: seat, onSeatTap: _onSeatTap))
                      .toList(),
                  ...List.generate(
                      (maxCols - row.length) - ((maxCols - row.length) ~/ 2),
                      (_) => SizedBox(width: 28.w)),
                  SizedBox(
                    width: 28.w,
                    child: Center(
                      child: Text(rowLabel,
                          style:
                              TextStyle(color: Colors.white70, fontSize: 12.sp)),
                    ),
                  ),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  // lib/screens/seat_selection_screen.dart -> _SeatSelectionScreenState

// ✅ SỬA _buildFooter: Xóa ref.read thừa VÀ invalidate provider sau khi thanh toán
  Widget _buildFooter(BuildContext context, AsyncValue authState, AsyncValue movieAsync, AsyncValue<Room> roomAsync) {
    double total = 0;
    List<TicketSeat> detailedSelectedSeats = [];
    final double pricePerSeat = widget.showtime.price;

    for (var seat in _selectedSeats) {
      total += pricePerSeat;
      detailedSelectedSeats.add(TicketSeat(seatId: seat.id, price: pricePerSeat));
    }
    final selectedSeatIds = _selectedSeats.map((s) => s.id).join(', ');

    final bool isMovieLoading = movieAsync.isLoading;
    final bool isRoomLoading = roomAsync.isLoading; 
    final bool isButtonEnabled = _selectedSeats.isNotEmpty && movieAsync.hasValue && roomAsync.hasValue; 

    return Container(
      padding: EdgeInsets.only(
          left: 16, right: 16, top: 16,
          bottom: 16 + MediaQuery.of(context).viewPadding.bottom, 
      ),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: Colors.grey.shade800)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${_selectedSeats.length} ghế: $selectedSeatIds',
                  style: const TextStyle(color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Tổng: ${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(total)}',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
              ),
            ],
          ),
        const SizedBox(height: 16),
        ElevatedButton(
            onPressed: isButtonEnabled
                ? () async { 
                    
                    final user = ref.read(authStateProvider).value;
                    if (user == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Vui lòng đăng nhập để tiếp tục'),
                        backgroundColor: Colors.blueAccent,
                      ),
                    );
                    
                    // Đi đến màn hình đăng nhập và "chờ" kết quả
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SignInScreen()),
                    );

                    // ✅ 4. SAU KHI QUAY LẠI, KIỂM TRA LẠI
                    final updatedUser = ref.read(authStateProvider).value;
                    
                    // Nếu người dùng bấm "back" (vẫn null), thì dừng lại
                    if (updatedUser == null) {
                      return; 
                    }
                  }

                    final movie = movieAsync.value!;
                    final userId = ref.read(authStateProvider).value!.uid;
                    final allCinemas = ref.read(cinemasStreamProvider).value ?? [];
                    final room = roomAsync.value!; 

                    final cinema = allCinemas.firstWhere(
                    (c) => c.id == widget.showtime.cinemaId,
                    orElse: () => Cinema(
                      name: 'Không rõ',
                      id: '', // Provide default/empty values for required fields
                      address: '',
                      city: '',
                      location: const GeoPoint(0, 0),
                      phone: '',
                      logoUrl: '',
                      createdAt: DateTime.now(),
                      openingHours: '', // <-- Add this required argument
                      // No need to add amenities/imageUrls if they have defaults in constructor
                    ),
                  );

                    final ticket = Ticket(
                      userId: userId,
                      movie: movie, 
                      showtimeId: widget.showtime.id!,
                      roomId: room.id!,       
                      roomName: room.name,
                      theaterName: cinema.name,
                      showDateTime: widget.showtime.startTime,
                      seats: detailedSelectedSeats,
                      totalPrice: total,
                      bookingTime: DateTime.now(),
                    );

                    // ✅ ĐIỀU HƯỚNG VÀ XỬ LÝ KẾT QUẢ
                    final paymentResult = await Navigator.push<bool>( 
                      context,
                      MaterialPageRoute(
                        builder: (context) => TicketScreen(ticket: ticket),
                      ),
                    );

                    // ✅ XỬ LÝ KHI QUAY LẠI TỪ THANH TOÁN
                    if (paymentResult == true && mounted) {
                       // Thanh toán thành công!
                       // Backend đã cập nhật Firestore (qua IPN).
                       // StreamProvider (showtimeStreamProvider) sẽ tự động
                       // phát hiện thay đổi và kích hoạt seatLayoutProvider chạy lại.
                       // Chúng ta chỉ cần xóa ghế xanh (đang chọn).
                       setState(() {
                         _selectedSeats.clear();
                       });
                    }
                    // Nếu paymentResult != true (người dùng back/thất bại)
                    // thì _selectedSeats vẫn giữ nguyên (ghế vẫn xanh)
                  }
                : null, 
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade800,
            ),
            
            child: isMovieLoading || isRoomLoading
                ? const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 3,
                  )
                : const Text('Thanh toán'),
          ),
      ],
    ),
  );
}
}


// -------------------- WIDGET GHẾ --------------------
class _SeatWidget extends StatelessWidget {
  final Seat seat;
  final void Function(Seat) onSeatTap;

  const _SeatWidget({required this.seat, required this.onSeatTap});

  @override
  Widget build(BuildContext context) {
    Color color = Colors.grey.shade700;
    IconData icon = Icons.event_seat;

    switch (seat.type) {
      case SeatType.regular:
        icon = Icons.event_seat;
        color = Colors.white;
        break;
      case SeatType.vip:
        icon = Icons.event_seat;
        color = Colors.amber.shade200;
        break;
      case SeatType.couple:
        icon = Icons.weekend_outlined;
        color = Colors.lightBlue.shade200;
        break;
    }

    switch (seat.status) {
      case SeatStatus.available:
        break;
      case SeatStatus.selected:
        color = Colors.green;
        break;
      case SeatStatus.sold:
        color = Colors.red;
        break;
    }

    return GestureDetector(
      onTap: () => onSeatTap(seat),
      child: Container(
        margin: const EdgeInsets.all(4),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}
