class TicketSeat {
  final String seatId;
  final double price;

  TicketSeat({required this.seatId, required this.price});

  // Chuyển đổi sang Map để lưu vào Firestore
  Map<String, dynamic> toJson() {
    return {
      'seatId': seatId,
      'price': price,
    };
  }

  // Tạo đối tượng từ Map (khi đọc từ Firestore)
  factory TicketSeat.fromJson(Map<String, dynamic> json) {
    return TicketSeat(
      seatId: json['seatId'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
    );
  }
}