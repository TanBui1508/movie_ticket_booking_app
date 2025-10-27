import 'package:cloud_firestore/cloud_firestore.dart';

class Showtime {
  final String? id;
  final String movieId;
  final String cinemaId;
  final String roomId;
  final DateTime startTime;
  final DateTime endTime;
  final double price;
  final int availableSeats;
  final List<String> bookedSeats;
  final String showDate;

  Showtime({
    this.id,
    required this.movieId,
    required this.cinemaId,
    required this.roomId,
    required this.startTime,
    required this.endTime,
    required this.price,
    required this.availableSeats,
    required this.bookedSeats,
    required this.showDate,
  });

  // Xử lý trực tiếp từ Map (JSON)
  factory Showtime.fromJson(String? id, Map<String, dynamic> json) {
    return Showtime(
      id: id,
      movieId: json['movieId'] ?? '',
      cinemaId: json['cinemaId'] ?? '',
      roomId: json['roomId'] ?? '',
      startTime: json['startTime'] is Timestamp
          ? (json['startTime'] as Timestamp).toDate()
          : DateTime.tryParse(json['startTime'] ?? '') ?? DateTime.now(),
      endTime: json['endTime'] is Timestamp
          ? (json['endTime'] as Timestamp).toDate()
          : DateTime.tryParse(json['endTime'] ?? '') ?? DateTime.now(),
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      availableSeats: json['availableSeats'] ?? 0,
      bookedSeats: List<String>.from(json['bookedSeats'] ?? []),
      showDate: json['showDate'] ?? '',
    );
  }

  factory Showtime.fromFirestore(DocumentSnapshot doc) {
    return Showtime.fromJson(doc.id, doc.data() as Map<String, dynamic>);
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'movieId': movieId,
      'cinemaId': cinemaId,
      'roomId': roomId,
      'startTime': startTime,
      'endTime': endTime,
      'price': price,
      'availableSeats': availableSeats,
      'bookedSeats': bookedSeats,
      'showDate': showDate,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'movieId': movieId,
      'cinemaId': cinemaId,
      'roomId': roomId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'price': price,
      'availableSeats': availableSeats,
      'bookedSeats': bookedSeats,
      'showDate': showDate,
    };
  }
}
