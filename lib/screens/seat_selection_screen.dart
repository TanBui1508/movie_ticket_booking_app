import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cinema_app_flutter/models/seat.dart';
import 'package:intl/intl.dart';
import 'package:flutter/src/material/icons.dart';

class SeatSelectionScreen extends ConsumerStatefulWidget {
  // Nhận dữ liệu từ màn hình trước
  final String movieTitle;
  final String cinemaName;
  final DateTime date;
  final String time;

  const SeatSelectionScreen({
    super.key,
    required this.movieTitle,
    required this.cinemaName,
    required this.date,
    required this.time,
  });

  @override
  ConsumerState<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends ConsumerState<SeatSelectionScreen> {
  // --- Dữ liệu giả cho sơ đồ ghế ---
  // Cấu trúc 2D: List các hàng, mỗi hàng là List các ghế
  final List<List<Seat>> _seatLayout = [
    List.generate(10, (i) => Seat(id: 'A${i + 1}')),
    List.generate(10, (i) => Seat(id: 'B${i + 1}')),
    List.generate(12, (i) => Seat(id: 'C${i + 1}', status: i % 4 == 0 ? SeatStatus.sold : SeatStatus.available)),
    List.generate(12, (i) => Seat(id: 'D${i + 1}')),
    List.generate(12, (i) => Seat(id: 'E${i + 1}', type: SeatType.vip)),
    List.generate(12, (i) => Seat(id: 'F${i + 1}', type: SeatType.vip, status: i > 10 ? SeatStatus.sold : SeatStatus.available)),
    List.generate(8, (i) => Seat(id: 'G${i + 1}', type: SeatType.couple)),
  ];

  // --- State Management ---
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
        //KHI HẾT GIỜ, QUAY LẠI MÀN HÌNH TRƯỚC
        if (Navigator.canPop(context)) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã hết thời gian giữ ghế!'), backgroundColor: Colors.red),
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
      if (seat.type == SeatType.couple) {
        // Tìm ghế liền kề trong cặp
        final seatNumber = int.parse(seat.id.substring(1));
        final partnerSeatId = seat.id.substring(0, 1) + (seatNumber % 2 != 0 ? (seatNumber + 1).toString() : (seatNumber - 1).toString());
        
        Seat? partnerSeat;
        try {
          partnerSeat = _seatLayout.expand((row) => row).firstWhere((s) => s.id == partnerSeatId);
        } catch(e) {
          partnerSeat = null;
        }

        if (seat.status == SeatStatus.available) {
          seat.status = SeatStatus.selected;
          _selectedSeats.add(seat);
          if (partnerSeat != null && partnerSeat.status == SeatStatus.available) {
            partnerSeat.status = SeatStatus.selected;
            _selectedSeats.add(partnerSeat);
          }
        } else if (seat.status == SeatStatus.selected) {
          seat.status = SeatStatus.available;
          _selectedSeats.remove(seat);
          if (partnerSeat != null && partnerSeat.status == SeatStatus.selected) {
            partnerSeat.status = SeatStatus.available;
            _selectedSeats.remove(partnerSeat);
          }
        }
      } else { // Ghế thường và VIP
        if (seat.status == SeatStatus.available) {
          seat.status = SeatStatus.selected;
          _selectedSeats.add(seat);
        } else if (seat.status == SeatStatus.selected) {
          seat.status = SeatStatus.available;
          _selectedSeats.remove(seat);
        }
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
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildShowtimeHeader(),
          const SizedBox(height: 24),
          _buildScreenRepresentation(),
          const SizedBox(height: 24),
          _buildSeatLegend(),
          const SizedBox(height: 16),
          Expanded(child: _buildSeatMap()),
        ],
      ),
      bottomNavigationBar: _buildFooter(),
    );
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
                Text(formattedCountdown, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShowtimeHeader() {
    final formattedDate = DateFormat('dd/MM/yyyy').format(widget.date);
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Center(
        child: Text(
          '${widget.cinemaName} | P.5 | $formattedDate - ${widget.time}',
          style: const TextStyle(color: Colors.white70, fontSize: 16),
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
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
          ),
        ),
        const Text('MÀN HÌNH', style: TextStyle(color: Colors.white, letterSpacing: 5)),
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
        _legendItem('Ghế đôi', Colors.lightBlue, Icons.weekend_outlined),
      ],
    );
  }

  Widget _legendItem(String label, Color color, IconData icon) {
  return Row(
    children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(width: 8),
      Text(label, style: const TextStyle(color: Colors.white70)),
    ]
  );
}

 // Thay thế hàm _buildSeatMap cũ của bạn bằng hàm này

Widget _buildSeatMap() {
  int maxCols = 0;
  for (var row in _seatLayout) {
    if (row.length > maxCols) {
      maxCols = row.length;
    }
  }

  return InteractiveViewer(
    maxScale: 3.0,
    minScale: 0.8,
    // ✅ BỌC WIDGET BẰNG SingleChildScrollView ĐỂ CHO PHÉP CUỘN NGANG
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        children: [
          // Nhãn cột số
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(maxCols + 2, (index) {
              if (index == 0 || index == maxCols + 1) return const SizedBox(width: 28);
              return SizedBox(
                width: 28,
                child: Center(
                  child: Text(
                    '${index}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          // Sơ đồ ghế và nhãn hàng
          ..._seatLayout.asMap().entries.map((entry) {
            int rowIndex = entry.key;
            List<Seat> row = entry.value;
            String rowLabel = String.fromCharCode('A'.codeUnitAt(0) + rowIndex);

            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(width: 28, child: Center(child: Text(rowLabel, style: const TextStyle(color: Colors.white70)))),
                // Thêm các SizedBox trống để các hàng ngắn hơn được căn giữa
                ...List.generate((maxCols - row.length) ~/ 2, (_) => const SizedBox(width: 28)),
                ...row.map((seat) => _SeatWidget(seat: seat, onSeatTap: _onSeatTap)).toList(),
                ...List.generate((maxCols - row.length) - ((maxCols - row.length) ~/ 2), (_) => const SizedBox(width: 28)),
                SizedBox(width: 28, child: Center(child: Text(rowLabel, style: const TextStyle(color: Colors.white70)))),
              ],
            );
          }).toList(),
        ],
      ),
    ),
  );
}

  Widget _buildFooter() {
    // final double pricePerSeat = 85000;
    // final double total = _selectedSeats.length * pricePerSeat;
    double total = 0;
for (var seat in _selectedSeats) {
  if (seat.type == SeatType.vip) {
    total += 120000; // Giá ghế VIP
  } else if (seat.type == SeatType.couple) {
    total += 180000; // Giá ghế đôi
  } else {
    total += 85000; // Giá ghế thường
  }
}
    final selectedSeatIds = _selectedSeats.map((s) => s.id).join(', ');

    return Container(
      padding: const EdgeInsets.all(16).copyWith(bottom: 32),
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
              Text('${_selectedSeats.length} ghế: $selectedSeatIds', style: const TextStyle(color: Colors.white)),
              Text('Tổng: ${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(total)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _selectedSeats.isNotEmpty ? () {} : null,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade800,
            ),
            child: const Text('Thanh toán'),
          ),
        ],
      ),
    );
  }
}

class _SeatWidget extends StatelessWidget {
  final Seat seat;
  final void Function(Seat) onSeatTap;

  const _SeatWidget({required this.seat, required this.onSeatTap});

  @override
  Widget build(BuildContext context) {
    Color color = Colors.grey.shade700;
    IconData icon = Icons.event_seat;

    // ✅ CẬP NHẬT: LOGIC MÀU SẮC VÀ ICON
    switch(seat.type) {
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

    switch(seat.status) {
      case SeatStatus.available:
        // Giữ nguyên màu đã set ở trên
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