// lib/models/seat.dart

// Enum để định nghĩa các trạng thái của ghế
enum SeatStatus { available, selected, sold }

// Enum để định nghĩa các loại ghế
enum SeatType { regular, vip, couple }

class Seat {
  final String id; // Ví dụ: "A1", "B5"
  final SeatType type;
  SeatStatus status;

  Seat({
    required this.id,
    this.type = SeatType.regular,
    this.status = SeatStatus.available,
  });
}