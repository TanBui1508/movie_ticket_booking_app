enum SeatStatus { available, selected, sold }

enum SeatType { regular, vip, couple }

class Seat {
  final String id;
  final SeatType type;
  SeatStatus status;

  Seat({
    required this.id,
    this.type = SeatType.regular,
    this.status = SeatStatus.available,
  });
}